import 'dart:convert';
import 'dart:io';

const int defaultMaxArchivedRunCount = 50;
const int defaultMaxArchiveByteLength = 500 * 1024 * 1024;

class RunIdentity {
  const RunIdentity({required this.runNumber, required this.capturedAtUtc});

  final int runNumber;
  final DateTime capturedAtUtc;

  String get runLabel => 'run-${runNumber.toString().padLeft(4, '0')}';

  String get timestampLabel {
    final DateTime utc = capturedAtUtc.toUtc();
    return '${utc.year.toString().padLeft(4, '0')}-'
        '${utc.month.toString().padLeft(2, '0')}-'
        '${utc.day.toString().padLeft(2, '0')}__'
        '${utc.hour.toString().padLeft(2, '0')}-'
        '${utc.minute.toString().padLeft(2, '0')}-'
        '${utc.second.toString().padLeft(2, '0')}';
  }

  String get runDirectoryName => '${runLabel}__${timestampLabel}';
}

String buildLatestScreenshotFileName(String originalFileName, RunIdentity run) {
  final String baseName = _baseNameWithoutPng(originalFileName);
  return '${baseName}__${run.runLabel}.png';
}

String buildArchivedScreenshotFileName(
  String originalFileName,
  RunIdentity run,
) {
  final String baseName = _baseNameWithoutPng(originalFileName);
  return '${baseName}__${run.runLabel}__${run.timestampLabel}.png';
}

String buildScenarioSlug(String originalFileName) {
  return _baseNameWithoutPng(originalFileName);
}

class ArchiveStateStore {
  ArchiveStateStore(this.stateFile);

  final File stateFile;

  Future<Map<String, dynamic>> loadState() => _readState();

  Future<RunIdentity> allocateRunIdentity({
    required DateTime capturedAtUtc,
  }) async {
    final Map<String, dynamic> state = await _readState();
    final int nextRunNumber = state['nextRunNumber'] as int? ?? 1;

    state['nextRunNumber'] = nextRunNumber + 1;
    state['updatedAtUtc'] = capturedAtUtc.toUtc().toIso8601String();
    await _writeState(state);

    return RunIdentity(runNumber: nextRunNumber, capturedAtUtc: capturedAtUtc);
  }

  Future<void> mergeStateFields(Map<String, Object?> fields) async {
    final Map<String, dynamic> currentState = await _readState();
    await _writeState(<String, Object?>{...currentState, ...fields});
  }

  Future<Map<String, dynamic>> _readState() async {
    if (!stateFile.existsSync()) {
      return <String, dynamic>{'nextRunNumber': 1};
    }

    final Object? decoded = jsonDecode(await stateFile.readAsString());
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'nextRunNumber': 1};
  }

  Future<void> _writeState(Map<String, Object?> state) async {
    await stateFile.parent.create(recursive: true);
    await stateFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(state),
      flush: true,
    );
  }
}

class ArchivedRunSnapshot {
  const ArchivedRunSnapshot({
    required this.runNumber,
    required this.directoryName,
    required this.byteLength,
    this.directoryPath,
  });

  final int runNumber;
  final String directoryName;
  final int byteLength;
  final String? directoryPath;
}

class CleanupPlan {
  const CleanupPlan({
    required this.shouldPrune,
    required this.keepRunNumbers,
    required this.deleteRunNumbers,
  });

  final bool shouldPrune;
  final List<int> keepRunNumbers;
  final List<int> deleteRunNumbers;

  factory CleanupPlan.none(List<ArchivedRunSnapshot> runs) {
    final List<int> allRunNumbers = runs
        .map((ArchivedRunSnapshot run) => run.runNumber)
        .toList(growable: false);
    return CleanupPlan(
      shouldPrune: false,
      keepRunNumbers: allRunNumbers,
      deleteRunNumbers: const <int>[],
    );
  }

  factory CleanupPlan.fromProtectedSet(
    List<ArchivedRunSnapshot> runs,
    Set<int> keep,
  ) {
    final List<int> keepRunNumbers = runs
        .where((ArchivedRunSnapshot run) => keep.contains(run.runNumber))
        .map((ArchivedRunSnapshot run) => run.runNumber)
        .toList(growable: false);
    final List<int> deleteRunNumbers = runs
        .where((ArchivedRunSnapshot run) => !keep.contains(run.runNumber))
        .map((ArchivedRunSnapshot run) => run.runNumber)
        .toList(growable: false);

    return CleanupPlan(
      shouldPrune: true,
      keepRunNumbers: keepRunNumbers,
      deleteRunNumbers: deleteRunNumbers,
    );
  }
}

CleanupPlan buildCleanupPlan({
  required List<ArchivedRunSnapshot> runs,
  required int totalArchiveBytes,
  required int maxRunCount,
  required int maxArchiveBytes,
}) {
  final List<ArchivedRunSnapshot> sorted = <ArchivedRunSnapshot>[...runs]
    ..sort(
      (ArchivedRunSnapshot left, ArchivedRunSnapshot right) =>
          left.runNumber.compareTo(right.runNumber),
    );

  final bool shouldPrune =
      sorted.length >= maxRunCount || totalArchiveBytes > maxArchiveBytes;

  if (!shouldPrune) {
    return CleanupPlan.none(sorted);
  }

  final Set<int> keep = <int>{
    ...sorted.take(3).map((ArchivedRunSnapshot run) => run.runNumber),
    ..._middleBlock(sorted).map((ArchivedRunSnapshot run) => run.runNumber),
    ...sorted
        .skip(sorted.length - 4)
        .map((ArchivedRunSnapshot run) => run.runNumber),
  };

  return CleanupPlan.fromProtectedSet(sorted, keep);
}

class VisualReviewArchiveManager {
  VisualReviewArchiveManager({
    required this.outputRootDirectory,
    DateTime Function()? clock,
    ArchiveStateStore? stateStore,
    this.maxRunCount = defaultMaxArchivedRunCount,
    this.maxArchiveBytes = defaultMaxArchiveByteLength,
  }) : _clock = clock ?? DateTime.now,
       stateStore =
           stateStore ??
           ArchiveStateStore(
             File(
               '${outputRootDirectory.path}${Platform.pathSeparator}archive_state.json',
             ),
           );

  final Directory outputRootDirectory;
  final DateTime Function() _clock;
  final ArchiveStateStore stateStore;
  final int maxRunCount;
  final int maxArchiveBytes;

  Directory get latestDirectory =>
      Directory('${outputRootDirectory.path}${Platform.pathSeparator}latest');

  Directory get runsDirectory =>
      Directory('${outputRootDirectory.path}${Platform.pathSeparator}runs');

  File get archiveStateFile => stateStore.stateFile;

  Future<RunIdentity> prepareForNextRun() async {
    await pruneIfNeeded();
    return stateStore.allocateRunIdentity(capturedAtUtc: _clock().toUtc());
  }

  Future<CleanupPlan> pruneIfNeeded() async {
    final List<ArchivedRunSnapshot> runs = await listArchivedRuns();
    final int totalArchiveBytes = runs.fold<int>(
      0,
      (int total, ArchivedRunSnapshot run) => total + run.byteLength,
    );
    final CleanupPlan plan = buildCleanupPlan(
      runs: runs,
      totalArchiveBytes: totalArchiveBytes,
      maxRunCount: maxRunCount,
      maxArchiveBytes: maxArchiveBytes,
    );

    if (!plan.shouldPrune) {
      return plan;
    }

    final Set<int> deleteRunNumbers = plan.deleteRunNumbers.toSet();
    for (final ArchivedRunSnapshot run in runs) {
      if (!deleteRunNumbers.contains(run.runNumber)) {
        continue;
      }

      final String directoryPath =
          run.directoryPath ??
          '${runsDirectory.path}${Platform.pathSeparator}${run.directoryName}';
      final Directory directory = Directory(directoryPath);
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    }

    final List<ArchivedRunSnapshot> remainingRuns = await listArchivedRuns();
    final int remainingArchiveBytes = remainingRuns.fold<int>(
      0,
      (int total, ArchivedRunSnapshot run) => total + run.byteLength,
    );
    final bool stillOverLimit = remainingArchiveBytes > maxArchiveBytes;
    if (stillOverLimit && remainingRuns.length <= plan.keepRunNumbers.length) {
      await stateStore.mergeStateFields(<String, Object?>{
        'lastWarning': 'archive_above_size_after_protected_prune',
        'lastWarningAtUtc': _clock().toUtc().toIso8601String(),
      });
    }

    return plan;
  }

  Future<List<ArchivedRunSnapshot>> listArchivedRuns() async {
    if (!runsDirectory.existsSync()) {
      return const <ArchivedRunSnapshot>[];
    }

    final List<_PendingArchivedRun> legacyRuns = <_PendingArchivedRun>[];
    final List<ArchivedRunSnapshot> numberedRuns = <ArchivedRunSnapshot>[];

    for (final FileSystemEntity entity in runsDirectory.listSync()) {
      if (entity is! Directory) {
        continue;
      }

      final String directoryName = entity.uri.pathSegments
          .where((String segment) => segment.isNotEmpty)
          .last;
      final int? runNumber = parseRunNumberFromDirectoryName(directoryName);
      if (runNumber == null) {
        legacyRuns.add(
          _PendingArchivedRun(
            directoryName: directoryName,
            directoryPath: entity.path,
            byteLength: await computeDirectoryByteLength(entity),
          ),
        );
        continue;
      }

      numberedRuns.add(
        ArchivedRunSnapshot(
          runNumber: runNumber,
          directoryName: directoryName,
          directoryPath: entity.path,
          byteLength: await computeDirectoryByteLength(entity),
        ),
      );
    }

    legacyRuns.sort(
      (_PendingArchivedRun left, _PendingArchivedRun right) =>
          left.directoryName.compareTo(right.directoryName),
    );
    numberedRuns.sort(
      (ArchivedRunSnapshot left, ArchivedRunSnapshot right) =>
          left.runNumber.compareTo(right.runNumber),
    );

    final List<ArchivedRunSnapshot> runs = <ArchivedRunSnapshot>[];
    for (int index = 0; index < legacyRuns.length; index += 1) {
      final _PendingArchivedRun legacyRun = legacyRuns[index];
      runs.add(
        ArchivedRunSnapshot(
          runNumber: index - legacyRuns.length,
          directoryName: legacyRun.directoryName,
          directoryPath: legacyRun.directoryPath,
          byteLength: legacyRun.byteLength,
        ),
      );
    }
    runs.addAll(numberedRuns);
    runs.sort(
      (ArchivedRunSnapshot left, ArchivedRunSnapshot right) =>
          left.runNumber.compareTo(right.runNumber),
    );
    return runs;
  }
}

int? parseRunNumberFromDirectoryName(String directoryName) {
  final RegExpMatch? match = RegExp(r'^run-(\d{4,})').firstMatch(directoryName);
  if (match == null) {
    return null;
  }

  return int.parse(match.group(1)!);
}

Future<int> computeDirectoryByteLength(Directory directory) async {
  if (!directory.existsSync()) {
    return 0;
  }

  int total = 0;
  await for (final FileSystemEntity entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is File) {
      total += await entity.length();
    }
  }

  return total;
}

class _PendingArchivedRun {
  const _PendingArchivedRun({
    required this.directoryName,
    required this.directoryPath,
    required this.byteLength,
  });

  final String directoryName;
  final String directoryPath;
  final int byteLength;
}

List<ArchivedRunSnapshot> _middleBlock(List<ArchivedRunSnapshot> runs) {
  if (runs.length <= 3) {
    return List<ArchivedRunSnapshot>.from(runs);
  }

  final int startIndex;
  if (runs.length.isOdd) {
    startIndex = (runs.length ~/ 2) - 1;
  } else {
    startIndex = (runs.length ~/ 2) - 2;
  }

  final int safeStartIndex = startIndex < 0 ? 0 : startIndex;
  final int safeEndIndex = (safeStartIndex + 3) > runs.length
      ? runs.length
      : safeStartIndex + 3;
  return runs.sublist(safeStartIndex, safeEndIndex);
}

String _baseNameWithoutPng(String fileName) {
  return fileName.replaceFirst(RegExp(r'\.png$', caseSensitive: false), '');
}

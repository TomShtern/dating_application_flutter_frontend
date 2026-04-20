import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'visual_review_archive.dart';

void main() {
  test('allocates monotonic zero-padded run identities', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'visual-review-archive-state-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final File stateFile = File(
      '${tempDirectory.path}${Platform.pathSeparator}archive_state.json',
    );
    final ArchiveStateStore store = ArchiveStateStore(stateFile);

    final RunIdentity first = await store.allocateRunIdentity(
      capturedAtUtc: DateTime.parse('2026-04-20T16:12:05Z'),
    );
    final RunIdentity second = await store.allocateRunIdentity(
      capturedAtUtc: DateTime.parse('2026-04-20T16:18:41Z'),
    );

    expect(first.runNumber, 1);
    expect(first.runLabel, 'run-0001');
    expect(first.runDirectoryName, 'run-0001__2026-04-20__16-12-05');
    expect(second.runNumber, 2);
    expect(second.runLabel, 'run-0002');
    expect(second.runDirectoryName, 'run-0002__2026-04-20__16-18-41');

    final Map<String, dynamic> state =
        jsonDecode(await stateFile.readAsString()) as Map<String, dynamic>;
    expect(state['nextRunNumber'], 3);
  });

  test('builds latest and archive filenames from the scenario slug', () {
    final RunIdentity run = RunIdentity(
      runNumber: 7,
      capturedAtUtc: DateTime.parse('2026-04-20T16:12:05Z'),
    );

    expect(
      buildLatestScreenshotFileName('shell_matches.png', run),
      'shell_matches__run-0007.png',
    );
    expect(
      buildArchivedScreenshotFileName('shell_matches.png', run),
      'shell_matches__run-0007__2026-04-20__16-12-05.png',
    );
  });

  test('protects oldest middle and latest archived runs', () {
    final List<ArchivedRunSnapshot> runs = List<ArchivedRunSnapshot>.generate(
      50,
      (int index) => ArchivedRunSnapshot(
        runNumber: index + 1,
        directoryName: 'run-${(index + 1).toString().padLeft(4, '0')}',
        byteLength: 1024,
      ),
    );

    final CleanupPlan plan = buildCleanupPlan(
      runs: runs,
      totalArchiveBytes: 50 * 1024,
      maxRunCount: 50,
      maxArchiveBytes: 500 * 1024 * 1024,
    );

    expect(plan.shouldPrune, isTrue);
    expect(plan.keepRunNumbers, [1, 2, 3, 24, 25, 26, 47, 48, 49, 50]);
    expect(plan.deleteRunNumbers, containsAll([4, 23, 27, 46]));
    expect(plan.deleteRunNumbers, isNot(contains(24)));
  });

  test('skips cleanup when archive stays below thresholds', () {
    final CleanupPlan plan = buildCleanupPlan(
      runs: List<ArchivedRunSnapshot>.generate(
        4,
        (int index) => ArchivedRunSnapshot(
          runNumber: index + 1,
          directoryName: 'run-${(index + 1).toString().padLeft(4, '0')}',
          byteLength: 2048,
        ),
      ),
      totalArchiveBytes: 8192,
      maxRunCount: 50,
      maxArchiveBytes: 500 * 1024 * 1024,
    );

    expect(plan.shouldPrune, isFalse);
    expect(plan.keepRunNumbers, [1, 2, 3, 4]);
    expect(plan.deleteRunNumbers, isEmpty);
  });

  test('prunes archived run directories before run 51', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'visual-review-prune-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Directory outputRootDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}visual_review',
    );
    final Directory runsDirectory = Directory(
      '${outputRootDirectory.path}${Platform.pathSeparator}runs',
    );
    await runsDirectory.create(recursive: true);

    for (int runNumber = 1; runNumber <= 50; runNumber += 1) {
      final Directory runDirectory = Directory(
        '${runsDirectory.path}${Platform.pathSeparator}run-${runNumber.toString().padLeft(4, '0')}__2026-04-20__12-00-00',
      );
      await runDirectory.create(recursive: true);
      await File(
        '${runDirectory.path}${Platform.pathSeparator}marker.txt',
      ).writeAsString('run $runNumber', flush: true);
    }

    final VisualReviewArchiveManager manager = VisualReviewArchiveManager(
      outputRootDirectory: outputRootDirectory,
      clock: () => DateTime.parse('2026-04-20T16:12:05Z'),
    );

    final CleanupPlan plan = await manager.pruneIfNeeded();

    expect(plan.shouldPrune, isTrue);
    expect(plan.keepRunNumbers, [1, 2, 3, 24, 25, 26, 47, 48, 49, 50]);

    final List<String> remainingDirectories =
        runsDirectory.listSync().whereType<Directory>().map((
          Directory directory,
        ) {
          return directory.uri.pathSegments
              .where((String segment) => segment.isNotEmpty)
              .last;
        }).toList()..sort();

    expect(remainingDirectories, [
      'run-0001__2026-04-20__12-00-00',
      'run-0002__2026-04-20__12-00-00',
      'run-0003__2026-04-20__12-00-00',
      'run-0024__2026-04-20__12-00-00',
      'run-0025__2026-04-20__12-00-00',
      'run-0026__2026-04-20__12-00-00',
      'run-0047__2026-04-20__12-00-00',
      'run-0048__2026-04-20__12-00-00',
      'run-0049__2026-04-20__12-00-00',
      'run-0050__2026-04-20__12-00-00',
    ]);
  });

  test(
    'includes legacy timestamp-named run directories in archive ordering',
    () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'visual-review-legacy-runs-',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final Directory outputRootDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}visual_review',
      );
      final Directory runsDirectory = Directory(
        '${outputRootDirectory.path}${Platform.pathSeparator}runs',
      );
      await runsDirectory.create(recursive: true);

      for (final String directoryName in <String>[
        '2026-04-20T16-22-09-506056Z',
        '2026-04-20T16-27-31-464306Z',
        'run-0001__2026-04-20__18-12-44',
      ]) {
        final Directory runDirectory = Directory(
          '${runsDirectory.path}${Platform.pathSeparator}$directoryName',
        );
        await runDirectory.create(recursive: true);
        await File(
          '${runDirectory.path}${Platform.pathSeparator}marker.txt',
        ).writeAsString(directoryName, flush: true);
      }

      final VisualReviewArchiveManager manager = VisualReviewArchiveManager(
        outputRootDirectory: outputRootDirectory,
        clock: () => DateTime.parse('2026-04-20T18:12:44Z'),
      );

      final List<ArchivedRunSnapshot> runs = await manager.listArchivedRuns();

      expect(
        runs.map((ArchivedRunSnapshot run) => run.directoryName).toList(),
        [
          '2026-04-20T16-22-09-506056Z',
          '2026-04-20T16-27-31-464306Z',
          'run-0001__2026-04-20__18-12-44',
        ],
      );
      expect(runs.map((ArchivedRunSnapshot run) => run.runNumber).toList(), [
        -2,
        -1,
        1,
      ]);
    },
  );
}

# Visual Review Archive and Retention Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the visual review workflow so each successful run produces sorted, self-identifying screenshots inside the workspace, preserves the latest run separately from archived runs, and applies the custom oldest/middle/latest retention policy before run 51 or when the archive bank exceeds 500 MB.

**Architecture:** Keep `test/visual/support/screenshot_capture.dart` as the orchestration layer, move run numbering/naming/retention logic into a focused archive helper, and isolate PNG metadata writing into a dedicated helper so the comparator remains understandable. Verify behavior with focused unit tests first, then run the real visual suite with a timeout and inspect generated artifacts in `build/visual_review/`.

**Tech Stack:** Flutter test, Dart I/O, JSON manifests, PNG binary chunk handling, PowerShell/Flutter CLI verification.

---

### Task 1: Add archive naming and state primitives

**Files:**
- Create: `test/visual/support/visual_review_archive.dart`
- Create: `test/visual/support/visual_review_archive_test.dart`
- Modify: `test/visual/support/screenshot_capture.dart`

- [ ] **Step 1: Write the failing archive-state and naming tests**

```dart
test('allocates monotonic zero-padded run identities', () async {
  final Directory tempDirectory = await Directory.systemTemp.createTemp(
    'visual-review-archive-state-',
  );
  addTearDown(() async => tempDirectory.delete(recursive: true));

  final ArchiveStateStore store = ArchiveStateStore(
    File('${tempDirectory.path}${Platform.pathSeparator}archive_state.json'),
  );

  final RunIdentity first = await store.allocateRunIdentity(
    capturedAtUtc: DateTime.parse('2026-04-20T16:12:05Z'),
  );
  final RunIdentity second = await store.allocateRunIdentity(
    capturedAtUtc: DateTime.parse('2026-04-20T16:18:41Z'),
  );

  expect(first.runLabel, 'run-0001');
  expect(first.runDirectoryName, 'run-0001__2026-04-20__16-12-05');
  expect(second.runLabel, 'run-0002');
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
```

- [ ] **Step 2: Run the archive-state test to verify it fails**

Run: `flutter test test/visual/support/visual_review_archive_test.dart`
Expected: FAIL because `ArchiveStateStore`, `RunIdentity`, and filename builders do not exist yet.

- [ ] **Step 3: Write the minimal archive helper implementation**

```dart
class RunIdentity {
  const RunIdentity({required this.runNumber, required this.capturedAtUtc});

  final int runNumber;
  final DateTime capturedAtUtc;

  String get runLabel => 'run-${runNumber.toString().padLeft(4, '0')}';

  String get timestampLabel {
    final utc = capturedAtUtc.toUtc();
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
  final String baseName = originalFileName.replaceFirst(RegExp(r'\.png$'), '');
  return '${baseName}__${run.runLabel}.png';
}

String buildArchivedScreenshotFileName(String originalFileName, RunIdentity run) {
  final String baseName = originalFileName.replaceFirst(RegExp(r'\.png$'), '');
  return '${baseName}__${run.runLabel}__${run.timestampLabel}.png';
}
```

- [ ] **Step 4: Re-run the archive-state test to verify it passes**

Run: `flutter test test/visual/support/visual_review_archive_test.dart`
Expected: PASS

- [ ] **Step 5: Commit the archive helper foundation**

```bash
git add test/visual/support/visual_review_archive.dart test/visual/support/visual_review_archive_test.dart test/visual/support/screenshot_capture.dart
git commit -m "feat: add visual review archive naming primitives"
```

### Task 2: Add cleanup-policy coverage before integrating it

**Files:**
- Modify: `test/visual/support/visual_review_archive.dart`
- Modify: `test/visual/support/visual_review_archive_test.dart`

- [ ] **Step 1: Write the failing cleanup-policy tests**

```dart
test('protects oldest, middle, and latest archived runs', () {
  final List<ArchivedRunSnapshot> runs = List<ArchivedRunSnapshot>.generate(
    50,
    (index) => ArchivedRunSnapshot(
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

  expect(plan.keepRunNumbers, [1, 2, 3, 24, 25, 26, 47, 48, 49, 50]);
  expect(plan.deleteRunNumbers, containsAll([4, 23, 27, 46]));
});

test('skips cleanup when archive stays below thresholds', () {
  final CleanupPlan plan = buildCleanupPlan(
    runs: List<ArchivedRunSnapshot>.generate(
      4,
      (index) => ArchivedRunSnapshot(
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
  expect(plan.deleteRunNumbers, isEmpty);
});
```

- [ ] **Step 2: Run the cleanup-policy test to verify it fails**

Run: `flutter test test/visual/support/visual_review_archive_test.dart`
Expected: FAIL because `ArchivedRunSnapshot`, `CleanupPlan`, and `buildCleanupPlan` are not implemented yet.

- [ ] **Step 3: Implement the minimal cleanup planner**

```dart
CleanupPlan buildCleanupPlan({
  required List<ArchivedRunSnapshot> runs,
  required int totalArchiveBytes,
  required int maxRunCount,
  required int maxArchiveBytes,
}) {
  final sorted = [...runs]..sort((a, b) => a.runNumber.compareTo(b.runNumber));
  final bool shouldPrune =
      sorted.length >= maxRunCount || totalArchiveBytes > maxArchiveBytes;

  if (!shouldPrune) {
    return CleanupPlan.none(sorted);
  }

  final Set<int> keep = <int>{
    ...sorted.take(3).map((run) => run.runNumber),
    ..._middleBlock(sorted).map((run) => run.runNumber),
    ...sorted.skip(sorted.length - 4).map((run) => run.runNumber),
  };

  return CleanupPlan.fromProtectedSet(sorted, keep);
}
```

- [ ] **Step 4: Re-run the cleanup-policy test to verify it passes**

Run: `flutter test test/visual/support/visual_review_archive_test.dart`
Expected: PASS

- [ ] **Step 5: Commit the cleanup-policy logic**

```bash
git add test/visual/support/visual_review_archive.dart test/visual/support/visual_review_archive_test.dart
git commit -m "feat: add visual review archive retention planner"
```

### Task 3: Add PNG metadata support with focused tests

**Files:**
- Create: `test/visual/support/png_text_metadata.dart`
- Create: `test/visual/support/png_text_metadata_test.dart`

- [ ] **Step 1: Write the failing PNG metadata tests**

```dart
test('embeds text metadata into a png without corrupting the file', () {
  final Uint8List pngBytes = _pngBytes();
  final Uint8List updated = embedPngTextMetadata(pngBytes, {
    'scenarioName': 'signed-in shell matches tab',
    'runLabel': 'run-0007',
    'capturedAtUtc': '2026-04-20T16:12:05Z',
  });

  expect(updated, isNot(equals(pngBytes)));
  expect(readPngTextMetadata(updated)['runLabel'], 'run-0007');
  expect(readPngTextMetadata(updated)['scenarioName'], 'signed-in shell matches tab');
});
```

- [ ] **Step 2: Run the PNG metadata test to verify it fails**

Run: `flutter test test/visual/support/png_text_metadata_test.dart`
Expected: FAIL because the PNG metadata helpers do not exist yet.

- [ ] **Step 3: Implement the minimal PNG text-chunk helper**

```dart
Uint8List embedPngTextMetadata(Uint8List pngBytes, Map<String, String> values) {
  final List<_PngChunk> chunks = _parsePngChunks(pngBytes);
  final int iendIndex = chunks.lastIndexWhere((chunk) => chunk.type == 'IEND');
  final List<_PngChunk> metadataChunks = values.entries
      .map((entry) => _PngChunk.text(entry.key, entry.value))
      .toList(growable: false);

  chunks.insertAll(iendIndex, metadataChunks);
  return _encodePng(chunks);
}
```

- [ ] **Step 4: Re-run the PNG metadata test to verify it passes**

Run: `flutter test test/visual/support/png_text_metadata_test.dart`
Expected: PASS

- [ ] **Step 5: Commit the PNG metadata helper**

```bash
git add test/visual/support/png_text_metadata.dart test/visual/support/png_text_metadata_test.dart
git commit -m "feat: embed metadata in archived visual review pngs"
```

### Task 4: Integrate naming, sorting, cleanup, and metadata into the screenshot writer

**Files:**
- Modify: `test/visual/support/screenshot_capture.dart`
- Modify: `test/visual/support/screenshot_capture_test.dart`

- [ ] **Step 1: Write the failing integration tests for latest/archive naming and sorted manifests**

```dart
test('writes latest files with run number and archive files with full identity', () async {
  final ScreenshotWriter writer = ScreenshotWriter(
    testFileUri,
    outputRootDirectory: outputRootDirectory,
    clock: () => DateTime.parse('2026-04-20T12:00:00Z'),
  )..registerScenario(fileName: 'sample.png', scenarioName: 'sample screen');

  await writer.compare(_pngBytes(), Uri.parse('screenshots/sample.png'));

  expect(
    writer.latestDirectory
        .listSync()
        .map((entry) => path.basename(entry.path))
        .contains('sample__run-0001.png'),
    isTrue,
  );
  expect(
    writer.runDirectory
        .listSync()
        .map((entry) => path.basename(entry.path))
        .contains('sample__run-0001__2026-04-20__12-00-00.png'),
    isTrue,
  );
});

test('updates archive state and sorts manifest screenshots by scenario slug', () async {
  await writer.compare(_pngBytes(), Uri.parse('screenshots/zeta.png'));
  await writer.compare(_pngBytes(), Uri.parse('screenshots/alpha.png'));

  final Map<String, dynamic> manifest =
      jsonDecode(await writer.latestManifestFile.readAsString())
          as Map<String, dynamic>;
  final List<dynamic> screenshots = manifest['screenshots'] as List<dynamic>;

  expect(screenshots.first['latestFileName'], 'alpha__run-0001.png');
  expect(screenshots.last['latestFileName'], 'zeta__run-0001.png');
});
```

- [ ] **Step 2: Run the screenshot-writer integration tests to verify they fail**

Run: `flutter test test/visual/support/screenshot_capture_test.dart`
Expected: FAIL because the writer still uses the old flat filenames and does not persist run state or sorted manifest fields.

- [ ] **Step 3: Implement the minimal integration in `ScreenshotWriter`**

```dart
Future<void> _prepareOutputDirectory() async {
  _archiveManager ??= await VisualReviewArchiveManager.create(
    outputRootDirectory: outputRootDirectory,
    clock: _clock,
  );

  await _archiveManager!.prepareForNextRun();
  _runIdentity = await _archiveManager!.allocateRunIdentity();
}

Future<void> _writeArtifact(Uri golden, Uint8List imageBytes) async {
  final String sourceFileName = _fileNameFor(golden);
  final String latestFileName = buildLatestScreenshotFileName(sourceFileName, _runIdentity!);
  final String archivedFileName = buildArchivedScreenshotFileName(sourceFileName, _runIdentity!);
  final Uint8List archivedBytes = embedPngTextMetadata(imageBytes, {
    'scenarioName': _scenarioNames[sourceFileName] ?? sourceFileName,
    'runLabel': _runIdentity!.runLabel,
    'capturedAtUtc': _clock().toUtc().toIso8601String(),
  });
  // write latestFileName and archivedFileName, then sort manifest records by scenario slug
}
```

- [ ] **Step 4: Re-run the screenshot-writer integration tests to verify they pass**

Run: `flutter test test/visual/support/screenshot_capture_test.dart`
Expected: PASS

- [ ] **Step 5: Commit the integrated screenshot-writer behavior**

```bash
git add test/visual/support/screenshot_capture.dart test/visual/support/screenshot_capture_test.dart test/visual/support/visual_review_archive.dart test/visual/support/png_text_metadata.dart
git commit -m "feat: add organized visual review archive output"
```

### Task 5: Update workflow docs and verify the real visual suite end-to-end

**Files:**
- Modify: `docs/visual-review-workflow.md`

- [ ] **Step 1: Write the failing expectation as a doc-checklist in the task notes**

```text
The doc is incomplete until it explains:
- latest filename format with run numbers
- archived run folder format
- archived filename format
- archive cleanup thresholds and preserved bands
- default rule to inspect latest first and ignore history unless needed
```

- [ ] **Step 2: Update the workflow documentation**

```md
## Output layout

- `build/visual_review/latest/` — newest screenshots only, named like `shell_matches__run-0007.png`
- `build/visual_review/runs/run-0007__2026-04-20__16-12-05/` — archived run folder
- archived screenshots are named like `shell_matches__run-0007__2026-04-20__16-12-05.png`
- `build/visual_review/archive_state.json` — monotonic run counter state

## Archive cleanup

Before run 51, or when archived runs exceed 500 MB, the workflow prunes the archive bank and keeps only the oldest 3, middle 3, and latest 4 archived runs.
```

- [ ] **Step 3: Run focused unit tests before the real workflow**

Run: `flutter test test/visual/support/visual_review_archive_test.dart test/visual/support/png_text_metadata_test.dart test/visual/support/screenshot_capture_test.dart`
Expected: PASS

- [ ] **Step 4: Run the real visual suite with a timeout and verify artifacts**

Run: `flutter test test/visual/screenshot_test.dart`
Expected: PASS and fresh files under:

- `build/visual_review/latest/`
- `build/visual_review/runs/<new-run-folder>/`
- `build/visual_review/latest/manifest.json`
- `build/visual_review/latest/index.html`

Then verify:

- latest PNG names include `__run-####`
- archived PNG names include `__run-####__YYYY-MM-DD__HH-mm-ss`
- manifest screenshot entries are sorted
- the new run directory is inside the workspace

- [ ] **Step 5: Commit docs and verified workflow output changes if intended for version control**

```bash
git add docs/visual-review-workflow.md test/visual/support/*.dart build/visual_review/latest/manifest.json
git commit -m "docs: document organized visual review archive workflow"
```
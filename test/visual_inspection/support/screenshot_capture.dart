import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'png_text_metadata.dart';
import 'visual_review_archive.dart';

class ScreenshotWriter extends LocalFileComparator {
  ScreenshotWriter(
    super.testFile, {
    Directory? outputRootDirectory,
    DateTime Function()? clock,
  }) : outputRootDirectory =
           outputRootDirectory ?? _defaultOutputRootDirectory(),
       _clock = clock ?? DateTime.now {
    _archiveManager = VisualReviewArchiveManager(
      outputRootDirectory: this.outputRootDirectory,
      clock: _clock,
    );
  }

  final Directory outputRootDirectory;
  final DateTime Function() _clock;
  final Map<String, String> _scenarioNames = <String, String>{};
  final List<Map<String, Object?>> _screenshots = <Map<String, Object?>>[];
  late final VisualReviewArchiveManager _archiveManager;
  RunIdentity? _runIdentity;

  bool _prepared = false;
  Future<void>? _prepareFuture;
  Future<void>? _writeMutex;

  Directory get outputDirectory => latestDirectory;

  Directory get latestDirectory =>
      Directory('${outputRootDirectory.path}${Platform.pathSeparator}latest');

  Directory get runsDirectory =>
      Directory('${outputRootDirectory.path}${Platform.pathSeparator}runs');

  String get runId => _requireRunIdentity().runDirectoryName;

  Directory get runDirectory => Directory(
    '${runsDirectory.path}${Platform.pathSeparator}${_requireRunIdentity().runDirectoryName}',
  );

  File get manifestFile => latestManifestFile;

  File get archiveStateFile => _archiveManager.archiveStateFile;

  File get latestManifestFile =>
      File('${latestDirectory.path}${Platform.pathSeparator}manifest.json');

  File get runManifestFile =>
      File('${runDirectory.path}${Platform.pathSeparator}manifest.json');

  File get latestGalleryFile =>
      File('${latestDirectory.path}${Platform.pathSeparator}index.html');

  File get runGalleryFile =>
      File('${runDirectory.path}${Platform.pathSeparator}index.html');

  Directory get legacyOutputRootDirectory => Directory(
    '${outputRootDirectory.parent.path}${Platform.pathSeparator}visual_screenshots',
  );

  void registerScenario({
    required String fileName,
    required String scenarioName,
  }) {
    _scenarioNames[fileName] = scenarioName;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await _writeArtifact(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await _writeArtifact(golden, imageBytes);
  }

  Future<void> _writeArtifact(Uri golden, Uint8List imageBytes) async {
    final previousMutex = _writeMutex;
    final completer = Completer<void>();
    _writeMutex = completer.future;

    if (previousMutex != null) {
      await previousMutex;
    }

    try {
      await _prepareOutputDirectory();

      final RunIdentity runIdentity = _requireRunIdentity();
      final String fileName = _fileNameFor(golden);
      final String scenarioName = _scenarioNames[fileName] ?? fileName;
      final String scenarioSlug = buildScenarioSlug(fileName);
      final String latestFileName = buildLatestScreenshotFileName(
        fileName,
        runIdentity,
      );
      final String archivedFileName = buildArchivedScreenshotFileName(
        fileName,
        runIdentity,
      );
      final String capturedAtUtc = _clock().toUtc().toIso8601String();
      final Uint8List archivedImageBytes = embedPngTextMetadata(imageBytes, {
        'scenarioName': scenarioName,
        'scenarioSlug': scenarioSlug,
        'latestFileName': latestFileName,
        'archivedFileName': archivedFileName,
        'runNumber': runIdentity.runNumber.toString(),
        'runLabel': runIdentity.runLabel,
        'runDirectoryName': runIdentity.runDirectoryName,
        'capturedAtUtc': capturedAtUtc,
      });

      final File latestArtifactFile = File(
        '${latestDirectory.path}${Platform.pathSeparator}$latestFileName',
      );
      final File runArtifactFile = File(
        '${runDirectory.path}${Platform.pathSeparator}$archivedFileName',
      );
      await Future.wait([
        latestArtifactFile.parent.create(recursive: true),
        runArtifactFile.parent.create(recursive: true),
      ]);
      await Future.wait([
        latestArtifactFile.writeAsBytes(imageBytes, flush: true),
        runArtifactFile.writeAsBytes(archivedImageBytes, flush: true),
      ]);

      _screenshots.removeWhere(
        (entry) => entry['scenarioSlug'] == scenarioSlug,
      );
      _screenshots.add(<String, Object?>{
        'scenarioName': scenarioName,
        'scenarioSlug': scenarioSlug,
        'sourceFileName': fileName,
        'fileName': latestFileName,
        'latestFileName': latestFileName,
        'archivedFileName': archivedFileName,
        'runNumber': runIdentity.runNumber,
        'runLabel': runIdentity.runLabel,
        'runDirectoryName': runIdentity.runDirectoryName,
        'path': latestArtifactFile.path,
        'latestPath': latestArtifactFile.path,
        'archivedPath': runArtifactFile.path,
        'runPath': runArtifactFile.path,
        'capturedAtUtc': capturedAtUtc,
        'byteLength': imageBytes.length,
        'archivedByteLength': archivedImageBytes.length,
      });
      _sortScreenshots();
      await _writeManifest();
      await _writeGallery();
    } finally {
      completer.complete();
    }
  }

  Future<void> _prepareOutputDirectory() async {
    if (_prepared) {
      return;
    }

    final existing = _prepareFuture;
    if (existing != null) {
      return existing;
    }

    final preparation = _prepareOutputDirectoryOnce();
    _prepareFuture = preparation;
    return preparation;
  }

  Future<void> _prepareOutputDirectoryOnce() async {
    try {
      if (legacyOutputRootDirectory.path != outputRootDirectory.path &&
          legacyOutputRootDirectory.existsSync()) {
        await legacyOutputRootDirectory.delete(recursive: true);
      }

      _runIdentity = await _archiveManager.prepareForNextRun();

      if (latestDirectory.existsSync()) {
        await latestDirectory.delete(recursive: true);
      }

      if (runDirectory.existsSync()) {
        await runDirectory.delete(recursive: true);
      }

      await latestDirectory.create(recursive: true);
      await runDirectory.create(recursive: true);
      _prepared = true;
    } catch (_) {
      _prepareFuture = null;
      rethrow;
    }
  }

  Future<void> _writeManifest() async {
    final RunIdentity runIdentity = _requireRunIdentity();
    final Map<String, Object?> manifest = <String, Object?>{
      'generatedAtUtc': _clock().toUtc().toIso8601String(),
      'runId': runIdentity.runDirectoryName,
      'runNumber': runIdentity.runNumber,
      'runLabel': runIdentity.runLabel,
      'workflow': 'visual_observability',
      'outputDirectory': latestDirectory.path,
      'latestDirectory': latestDirectory.path,
      'runDirectory': runDirectory.path,
      'runDirectoryName': runIdentity.runDirectoryName,
      'archiveStateFile': archiveStateFile.path,
      'screenshots': _screenshots,
    };

    final String manifestJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(manifest);
    await Future.wait([
      latestManifestFile.writeAsString(manifestJson, flush: true),
      runManifestFile.writeAsString(manifestJson, flush: true),
    ]);
  }

  Future<void> _writeGallery() async {
    final String latestHtml = _buildGalleryHtml(
      imageFileNameKey: 'latestFileName',
    );
    final String archivedHtml = _buildGalleryHtml(
      imageFileNameKey: 'archivedFileName',
    );

    await Future.wait([
      latestGalleryFile.writeAsString(latestHtml, flush: true),
      runGalleryFile.writeAsString(archivedHtml, flush: true),
    ]);
  }

  String _buildGalleryHtml({required String imageFileNameKey}) {
    final HtmlEscape htmlEscape = const HtmlEscape();
    final String html =
        '''<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Visual review $runId</title>
    <style>
      :root { color-scheme: light dark; }
      body {
        font-family: Arial, Helvetica, sans-serif;
        margin: 0;
        padding: 24px;
        background: #f6f4ff;
        color: #231f32;
      }
      h1 { margin-top: 0; }
      .meta { margin-bottom: 24px; color: #5a556c; }
      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
        gap: 20px;
      }
      figure {
        margin: 0;
        background: rgba(255, 255, 255, 0.88);
        border-radius: 20px;
        padding: 16px;
        box-shadow: 0 10px 30px rgba(48, 37, 86, 0.12);
      }
      img {
        display: block;
        width: 100%;
        height: auto;
        border-radius: 16px;
        border: 1px solid rgba(90, 85, 108, 0.15);
      }
      figcaption {
        margin-top: 12px;
        font-weight: 600;
      }
      .subtle {
        margin-top: 6px;
        font-size: 0.9rem;
        color: #5a556c;
        word-break: break-word;
      }
    </style>
  </head>
  <body>
    <h1>Visual review</h1>
    <div class="meta">Run ID: ${htmlEscape.convert(runId)} • Generated: ${htmlEscape.convert(_clock().toUtc().toIso8601String())}</div>
    <div class="grid">
      ${_screenshots.map((entry) {
          final String scenarioName = htmlEscape.convert(entry['scenarioName'] as String? ?? 'Scenario');
          final String fileName = htmlEscape.convert(entry[imageFileNameKey] as String? ?? 'screenshot.png');
          final String capturedAtUtc = htmlEscape.convert(entry['capturedAtUtc'] as String? ?? '');
          return '''<figure>
  <img src="$fileName" alt="$scenarioName" />
  <figcaption>$scenarioName</figcaption>
  <div class="subtle">$fileName</div>
  <div class="subtle">Captured: $capturedAtUtc</div>
</figure>''';
        }).join('\n')}
    </div>
  </body>
</html>
''';

    return html;
  }

  String _fileNameFor(Uri golden) {
    if (golden.pathSegments.isEmpty) {
      throw StateError('URI must include a file name: $golden');
    }

    return golden.pathSegments.last;
  }

  RunIdentity _requireRunIdentity() {
    final RunIdentity? runIdentity = _runIdentity;
    if (runIdentity == null) {
      throw StateError('Run identity is not available before preparation.');
    }

    return runIdentity;
  }

  void _sortScreenshots() {
    _screenshots.sort((Map<String, Object?> left, Map<String, Object?> right) {
      final String leftSlug = left['scenarioSlug'] as String? ?? '';
      final String rightSlug = right['scenarioSlug'] as String? ?? '';
      return leftSlug.compareTo(rightSlug);
    });
  }

  static Directory _defaultOutputRootDirectory() {
    return Directory(
      [Directory.current.path, 'visual_review'].join(Platform.pathSeparator),
    );
  }
}

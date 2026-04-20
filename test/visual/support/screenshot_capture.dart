import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class ScreenshotWriter extends LocalFileComparator {
  ScreenshotWriter(
    super.testFile, {
    Directory? outputDirectory,
    DateTime Function()? clock,
  }) : outputDirectory = outputDirectory ?? _defaultOutputDirectory(),
       _clock = clock ?? DateTime.now;

  final Directory outputDirectory;
  final DateTime Function() _clock;
  final Map<String, String> _scenarioNames = <String, String>{};
  final List<Map<String, Object?>> _screenshots = <Map<String, Object?>>[];

  bool _prepared = false;
  Future<void>? _prepareFuture;
  Future<void>? _writeMutex;

  File get manifestFile =>
      File('${outputDirectory.path}${Platform.pathSeparator}manifest.json');

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

      final String fileName = _fileNameFor(golden);
      final File artifactFile = File(
        '${outputDirectory.path}${Platform.pathSeparator}$fileName',
      );
      await artifactFile.parent.create(recursive: true);
      await artifactFile.writeAsBytes(imageBytes, flush: true);

      _screenshots.removeWhere((entry) => entry['fileName'] == fileName);
      _screenshots.add(<String, Object?>{
        'scenarioName': _scenarioNames[fileName] ?? fileName,
        'fileName': fileName,
        'path': artifactFile.path,
        'capturedAtUtc': _clock().toUtc().toIso8601String(),
        'byteLength': imageBytes.length,
      });
      await _writeManifest();
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
      if (outputDirectory.existsSync()) {
        await outputDirectory.delete(recursive: true);
      }

      await outputDirectory.create(recursive: true);
      _prepared = true;
    } catch (_) {
      _prepareFuture = null;
      rethrow;
    }
  }

  Future<void> _writeManifest() async {
    final Map<String, Object?> manifest = <String, Object?>{
      'generatedAtUtc': _clock().toUtc().toIso8601String(),
      'outputDirectory': outputDirectory.path,
      'screenshots': _screenshots,
    };

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
  }

  String _fileNameFor(Uri golden) {
    if (golden.pathSegments.isEmpty) {
      throw StateError('URI must include a file name: $golden');
    }

    return golden.pathSegments.last;
  }

  static Directory _defaultOutputDirectory() {
    return Directory(
      [
        Directory.current.path,
        'build',
        'visual_screenshots',
        'latest',
      ].join(Platform.pathSeparator),
    );
  }
}

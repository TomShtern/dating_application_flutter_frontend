import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

class VisualReviewArtifactComparator extends LocalFileComparator {
  VisualReviewArtifactComparator(
    super.testFile, {
    Directory? artifactDirectory,
    DateTime Function()? clock,
  }) : artifactDirectory = artifactDirectory ?? _defaultArtifactDirectory(),
       _clock = clock ?? DateTime.now;

  final Directory artifactDirectory;
  final DateTime Function() _clock;
  final Map<String, String> _scenarioNames = <String, String>{};
  final List<Map<String, Object?>> _screenshots = <Map<String, Object?>>[];

  bool _prepared = false;
  String? _runStartedAtUtc;

  File get manifestFile =>
      File('${artifactDirectory.path}${Platform.pathSeparator}manifest.json');

  void registerScenario({
    required String goldenFileName,
    required String scenarioName,
  }) {
    _scenarioNames[goldenFileName] = scenarioName;
  }

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await _writeArtifact(golden, imageBytes);
    return super.compare(imageBytes, golden);
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    await _writeArtifact(golden, imageBytes);
    await super.update(golden, imageBytes);
  }

  Future<void> _writeArtifact(Uri golden, Uint8List imageBytes) async {
    await _prepareArtifactDirectory();

    final String fileName = _fileNameFor(golden);
    final File artifactFile = File(
      '${artifactDirectory.path}${Platform.pathSeparator}$fileName',
    );
    await artifactFile.parent.create(recursive: true);
    await artifactFile.writeAsBytes(imageBytes, flush: true);

    _screenshots.removeWhere((entry) => entry['fileName'] == fileName);
    _screenshots.add(<String, Object?>{
      'scenarioName': _scenarioNames[fileName] ?? fileName,
      'fileName': fileName,
      'goldenUri': golden.toString(),
      'path': artifactFile.path,
      'capturedAtUtc': _clock().toUtc().toIso8601String(),
      'byteLength': imageBytes.length,
    });
    await _writeManifest();
  }

  Future<void> _prepareArtifactDirectory() async {
    if (_prepared) {
      return;
    }

    if (artifactDirectory.existsSync()) {
      await artifactDirectory.delete(recursive: true);
    }

    await artifactDirectory.create(recursive: true);
    _runStartedAtUtc = _clock().toUtc().toIso8601String();
    _prepared = true;
  }

  Future<void> _writeManifest() async {
    final Map<String, Object?> manifest = <String, Object?>{
      'runStartedAtUtc': _runStartedAtUtc,
      'generatedAtUtc': _clock().toUtc().toIso8601String(),
      'outputDirectory': artifactDirectory.path,
      'screenshots': _screenshots,
    };

    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(manifest),
      flush: true,
    );
  }

  String _fileNameFor(Uri golden) {
    if (golden.pathSegments.isEmpty) {
      throw StateError('Golden URI must include a file name: $golden');
    }

    return golden.pathSegments.last;
  }

  static Directory _defaultArtifactDirectory() {
    return Directory(
      [
        Directory.current.path,
        'build',
        'visual_review',
        'latest',
      ].join(Platform.pathSeparator),
    );
  }
}

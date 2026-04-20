import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'screenshot_capture.dart';

void main() {
  test('writes screenshot to disk and updates manifest', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'screenshot-capture-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Uri testFileUri = Uri.file(
      '${tempDirectory.path}${Platform.pathSeparator}screenshot_test.dart',
    );

    final Directory outputDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}screenshots',
    );

    final ScreenshotWriter writer = ScreenshotWriter(
      testFileUri,
      outputDirectory: outputDirectory,
      clock: () => DateTime.parse('2026-04-20T12:00:00Z'),
    )..registerScenario(fileName: 'sample.png', scenarioName: 'sample screen');

    final Uint8List imageBytes = _pngBytes();
    final bool matches = await writer.compare(
      imageBytes,
      Uri.parse('screenshots/sample.png'),
    );

    expect(matches, isTrue);

    final File screenshotFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}sample.png',
    );
    expect(screenshotFile.existsSync(), isTrue);
    expect(await screenshotFile.readAsBytes(), orderedEquals(imageBytes));

    final Map<String, dynamic> manifest =
        jsonDecode(await writer.manifestFile.readAsString())
            as Map<String, dynamic>;
    final List<dynamic> screenshots = manifest['screenshots'] as List<dynamic>;

    expect(manifest['outputDirectory'], outputDirectory.path);
    expect(screenshots, hasLength(1));
    expect(screenshots.single, containsPair('scenarioName', 'sample screen'));
    expect(screenshots.single, containsPair('fileName', 'sample.png'));
  });

  test('first capture clears stale files from previous runs', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'screenshot-capture-stale-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Uri testFileUri = Uri.file(
      '${tempDirectory.path}${Platform.pathSeparator}screenshot_test.dart',
    );
    final Directory outputDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}screenshots',
    );
    await outputDirectory.create(recursive: true);
    final File staleFile = File(
      '${outputDirectory.path}${Platform.pathSeparator}stale.txt',
    );
    await staleFile.writeAsString('old', flush: true);

    final ScreenshotWriter writer = ScreenshotWriter(
      testFileUri,
      outputDirectory: outputDirectory,
      clock: () => DateTime.parse('2026-04-20T13:00:00Z'),
    );

    await writer.update(_uri('fresh.png'), _pngBytes());

    expect(staleFile.existsSync(), isFalse);
    expect(
      File(
        '${outputDirectory.path}${Platform.pathSeparator}fresh.png',
      ).existsSync(),
      isTrue,
    );
  });

  test('concurrent writes are serialized via mutex', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'screenshot-capture-concurrent-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Uri testFileUri = Uri.file(
      '${tempDirectory.path}${Platform.pathSeparator}screenshot_test.dart',
    );
    final Directory outputDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}screenshots',
    );

    final ScreenshotWriter writer = ScreenshotWriter(
      testFileUri,
      outputDirectory: outputDirectory,
      clock: () => DateTime.parse('2026-04-20T14:00:00Z'),
    );

    await Future.wait([
      writer.compare(_pngBytes(), _uri('alpha.png')),
      writer.compare(_pngBytes(), _uri('beta.png')),
    ]);

    expect(
      File(
        '${outputDirectory.path}${Platform.pathSeparator}alpha.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${outputDirectory.path}${Platform.pathSeparator}beta.png',
      ).existsSync(),
      isTrue,
    );

    final Map<String, dynamic> manifest =
        jsonDecode(await writer.manifestFile.readAsString())
            as Map<String, dynamic>;
    final List<dynamic> screenshots = manifest['screenshots'] as List<dynamic>;
    expect(screenshots, hasLength(2));
  });
}

Uri _uri(String fileName) => Uri.parse('screenshots/$fileName');

Uint8List _pngBytes({
  String base64Data =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO/a0WQAAAAASUVORK5CYII=',
}) {
  return base64Decode(base64Data);
}

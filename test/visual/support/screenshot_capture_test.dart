import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'png_text_metadata.dart';
import 'screenshot_capture.dart';

void main() {
  test(
    'writes screenshot to latest and run directories and updates manifests',
    () async {
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

      final Directory outputRootDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}visual_review',
      );

      final ScreenshotWriter writer =
          ScreenshotWriter(
            testFileUri,
            outputRootDirectory: outputRootDirectory,
            clock: () => DateTime.parse('2026-04-20T12:00:00Z'),
          )..registerScenario(
            fileName: 'sample.png',
            scenarioName: 'sample screen',
          );

      final Uint8List imageBytes = _pngBytes();
      final bool matches = await writer.compare(
        imageBytes,
        Uri.parse('screenshots/sample.png'),
      );

      expect(matches, isTrue);

      final String latestFileName = 'sample__run-0001.png';
      final String archivedFileName =
          'sample__run-0001__2026-04-20__12-00-00.png';
      final File latestScreenshotFile = File(
        '${writer.latestDirectory.path}${Platform.pathSeparator}$latestFileName',
      );
      final File runScreenshotFile = File(
        '${writer.runDirectory.path}${Platform.pathSeparator}$archivedFileName',
      );
      expect(latestScreenshotFile.existsSync(), isTrue);
      expect(runScreenshotFile.existsSync(), isTrue);
      expect(
        await latestScreenshotFile.readAsBytes(),
        orderedEquals(imageBytes),
      );
      expect(
        await runScreenshotFile.readAsBytes(),
        isNot(orderedEquals(imageBytes)),
      );

      final Map<String, dynamic> manifest =
          jsonDecode(await writer.latestManifestFile.readAsString())
              as Map<String, dynamic>;
      final List<dynamic> screenshots =
          manifest['screenshots'] as List<dynamic>;

      expect(manifest['runId'], 'run-0001__2026-04-20__12-00-00');
      expect(manifest['latestDirectory'], writer.latestDirectory.path);
      expect(manifest['runDirectory'], writer.runDirectory.path);
      expect(screenshots, hasLength(1));
      expect(screenshots.single, containsPair('scenarioName', 'sample screen'));
      expect(screenshots.single, containsPair('scenarioSlug', 'sample'));
      expect(screenshots.single, containsPair('fileName', latestFileName));
      expect(
        screenshots.single,
        containsPair('latestFileName', latestFileName),
      );
      expect(
        screenshots.single,
        containsPair('archivedFileName', archivedFileName),
      );
      expect(screenshots.single, containsPair('runNumber', 1));
      expect(
        screenshots.single,
        containsPair('runDirectoryName', 'run-0001__2026-04-20__12-00-00'),
      );
      expect(
        screenshots.single,
        containsPair('latestPath', latestScreenshotFile.path),
      );
      expect(
        screenshots.single,
        containsPair('archivedPath', runScreenshotFile.path),
      );

      final Map<String, String> archivedMetadata = readPngTextMetadata(
        await runScreenshotFile.readAsBytes(),
      );
      expect(archivedMetadata['scenarioName'], 'sample screen');
      expect(archivedMetadata['scenarioSlug'], 'sample');
      expect(archivedMetadata['runLabel'], 'run-0001');
      expect(
        archivedMetadata['runDirectoryName'],
        'run-0001__2026-04-20__12-00-00',
      );

      final String latestGallery = await writer.latestGalleryFile
          .readAsString();
      expect(latestGallery, contains('sample screen'));
      expect(latestGallery, contains(latestFileName));

      final String runGallery = await writer.runGalleryFile.readAsString();
      expect(runGallery, contains('sample screen'));
      expect(runGallery, contains(archivedFileName));

      final File archiveStateFile = File(
        '${outputRootDirectory.path}${Platform.pathSeparator}archive_state.json',
      );
      final Map<String, dynamic> archiveState =
          jsonDecode(await archiveStateFile.readAsString())
              as Map<String, dynamic>;
      expect(archiveState['nextRunNumber'], 2);
    },
  );

  test('first capture clears stale latest files and legacy output root', () async {
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
    final Directory outputRootDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}visual_review',
    );
    final Directory latestDirectory = Directory(
      '${outputRootDirectory.path}${Platform.pathSeparator}latest',
    );
    await latestDirectory.create(recursive: true);
    final File staleFile = File(
      '${latestDirectory.path}${Platform.pathSeparator}stale.txt',
    );
    await staleFile.writeAsString('old', flush: true);
    final Directory legacyDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}visual_screenshots',
    );
    await legacyDirectory.create(recursive: true);
    final File legacyFile = File(
      '${legacyDirectory.path}${Platform.pathSeparator}legacy.txt',
    );
    await legacyFile.writeAsString('old legacy output', flush: true);

    final ScreenshotWriter writer = ScreenshotWriter(
      testFileUri,
      outputRootDirectory: outputRootDirectory,
      clock: () => DateTime.parse('2026-04-20T13:00:00Z'),
    );

    await writer.update(_uri('fresh.png'), _pngBytes());

    expect(staleFile.existsSync(), isFalse);
    expect(legacyFile.existsSync(), isFalse);
    expect(
      File(
        '${writer.latestDirectory.path}${Platform.pathSeparator}fresh__run-0001.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${writer.runDirectory.path}${Platform.pathSeparator}fresh__run-0001__2026-04-20__13-00-00.png',
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
    final Directory outputRootDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}visual_review',
    );

    final ScreenshotWriter writer = ScreenshotWriter(
      testFileUri,
      outputRootDirectory: outputRootDirectory,
      clock: () => DateTime.parse('2026-04-20T14:00:00Z'),
    );

    await Future.wait([
      writer.compare(_pngBytes(), _uri('alpha.png')),
      writer.compare(_pngBytes(), _uri('beta.png')),
    ]);

    expect(
      File(
        '${writer.latestDirectory.path}${Platform.pathSeparator}alpha__run-0001.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${writer.latestDirectory.path}${Platform.pathSeparator}beta__run-0001.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${writer.runDirectory.path}${Platform.pathSeparator}alpha__run-0001__2026-04-20__14-00-00.png',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        '${writer.runDirectory.path}${Platform.pathSeparator}beta__run-0001__2026-04-20__14-00-00.png',
      ).existsSync(),
      isTrue,
    );

    final Map<String, dynamic> manifest =
        jsonDecode(await writer.latestManifestFile.readAsString())
            as Map<String, dynamic>;
    final List<dynamic> screenshots = manifest['screenshots'] as List<dynamic>;
    expect(screenshots, hasLength(2));
    expect(screenshots.first['latestFileName'], 'alpha__run-0001.png');
    expect(screenshots.last['latestFileName'], 'beta__run-0001.png');
  });
}

Uri _uri(String fileName) => Uri.parse('screenshots/$fileName');

Uint8List _pngBytes({
  String base64Data =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO/a0WQAAAAASUVORK5CYII=',
}) {
  return base64Decode(base64Data);
}

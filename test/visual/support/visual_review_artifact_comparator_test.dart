import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'visual_review_artifact_comparator.dart';

void main() {
  test('compare writes fresh screenshot artifacts and a manifest', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'visual-review-comparator-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Uri testFileUri = Uri.file(
      '${tempDirectory.path}${Platform.pathSeparator}visual_review_test.dart',
    );
    final Directory goldenDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}goldens',
    );
    await goldenDirectory.create(recursive: true);

    final Uint8List imageBytes = _pngBytes();
    await File(
      '${goldenDirectory.path}${Platform.pathSeparator}sample.png',
    ).writeAsBytes(imageBytes, flush: true);

    final Directory artifactDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}artifacts',
    );
    final VisualReviewArtifactComparator comparator =
        VisualReviewArtifactComparator(
          testFileUri,
          artifactDirectory: artifactDirectory,
          clock: () => DateTime.parse('2026-04-20T12:00:00Z'),
        )..registerScenario(
          goldenFileName: 'sample.png',
          scenarioName: 'sample screen',
        );

    final bool matches = await comparator.compare(
      imageBytes,
      Uri.parse('goldens/sample.png'),
    );

    expect(matches, isTrue);

    final File artifactFile = File(
      '${artifactDirectory.path}${Platform.pathSeparator}sample.png',
    );
    expect(artifactFile.existsSync(), isTrue);
    expect(await artifactFile.readAsBytes(), orderedEquals(imageBytes));

    final Map<String, dynamic> manifest =
        jsonDecode(await comparator.manifestFile.readAsString())
            as Map<String, dynamic>;
    final List<dynamic> screenshots = manifest['screenshots'] as List<dynamic>;

    expect(manifest['outputDirectory'], artifactDirectory.path);
    expect(screenshots, hasLength(1));
    expect(screenshots.single, containsPair('scenarioName', 'sample screen'));
    expect(screenshots.single, containsPair('fileName', 'sample.png'));
    expect(screenshots.single, containsPair('goldenUri', 'goldens/sample.png'));
  });

  test('first artifact write clears stale files from previous runs', () async {
    final Directory tempDirectory = await Directory.systemTemp.createTemp(
      'visual-review-stale-artifacts-',
    );
    addTearDown(() async {
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    final Uri testFileUri = Uri.file(
      '${tempDirectory.path}${Platform.pathSeparator}visual_review_test.dart',
    );
    final Directory artifactDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}artifacts',
    );
    await artifactDirectory.create(recursive: true);
    final File staleFile = File(
      '${artifactDirectory.path}${Platform.pathSeparator}stale.txt',
    );
    await staleFile.writeAsString('old', flush: true);

    final VisualReviewArtifactComparator comparator =
        VisualReviewArtifactComparator(
          testFileUri,
          artifactDirectory: artifactDirectory,
          clock: () => DateTime.parse('2026-04-20T13:00:00Z'),
        );

    await comparator.update(_goldenUri('fresh.png'), _pngBytes());

    expect(staleFile.existsSync(), isFalse);
    expect(
      File(
        '${artifactDirectory.path}${Platform.pathSeparator}fresh.png',
      ).existsSync(),
      isTrue,
    );
  });

  test(
    'compare still writes a fresh artifact when the golden mismatches',
    () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'visual-review-mismatch-',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final Uri testFileUri = Uri.file(
        '${tempDirectory.path}${Platform.pathSeparator}visual_review_test.dart',
      );
      final Directory goldenDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}goldens',
      );
      await goldenDirectory.create(recursive: true);

      final Uint8List goldenBytes = await _repoGoldenBytes(
        'app_home_startup.png',
      );
      await File(
        '${goldenDirectory.path}${Platform.pathSeparator}mismatch.png',
      ).writeAsBytes(goldenBytes, flush: true);

      final Directory artifactDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}artifacts',
      );
      final VisualReviewArtifactComparator comparator =
          VisualReviewArtifactComparator(
            testFileUri,
            artifactDirectory: artifactDirectory,
            clock: () => DateTime.parse('2026-04-20T14:00:00Z'),
          );

      final Uint8List changedBytes = await _repoGoldenBytes(
        'shell_discover.png',
      );

      await expectLater(
        () => comparator.compare(changedBytes, _goldenUri('mismatch.png')),
        throwsA(isA<FlutterError>()),
      );

      final File artifactFile = File(
        '${artifactDirectory.path}${Platform.pathSeparator}mismatch.png',
      );
      expect(artifactFile.existsSync(), isTrue);
      expect(await artifactFile.readAsBytes(), orderedEquals(changedBytes));
    },
  );
}

Uri _goldenUri(String fileName) => Uri.parse('goldens/$fileName');

Uint8List _pngBytes({
  String base64Data =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO/a0WQAAAAASUVORK5CYII=',
}) {
  return base64Decode(base64Data);
}

Future<Uint8List> _repoGoldenBytes(String fileName) async {
  final File file = File(
    [
      Directory.current.path,
      'test',
      'visual',
      'goldens',
      fileName,
    ].join(Platform.pathSeparator),
  );

  return Uint8List.fromList(await file.readAsBytes());
}

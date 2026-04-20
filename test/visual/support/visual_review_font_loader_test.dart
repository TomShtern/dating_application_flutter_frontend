import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'visual_review_font_loader.dart';

void main() {
  group('resolveFlutterRootForVisualTests', () {
    test('prefers FLUTTER_ROOT when it is provided', () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'visual-review-font-root-',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      await Directory(
        '${tempDirectory.path}${Platform.pathSeparator}bin',
      ).create(recursive: true);
      await File(
        '${tempDirectory.path}${Platform.pathSeparator}bin${Platform.pathSeparator}flutter.bat',
      ).writeAsString('@echo off', flush: true);

      final String flutterRoot = resolveFlutterRootForVisualTests(
        environment: {'FLUTTER_ROOT': tempDirectory.path},
        resolvedExecutablePath: 'ignored',
      );

      expect(flutterRoot, tempDirectory.path);
    });

    test('walks up from the resolved executable to find flutter root', () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'visual-review-font-walk-',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final Directory flutterRoot = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}flutter',
      );
      await Directory(
        '${flutterRoot.path}${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin',
      ).create(recursive: true);
      await File(
        '${flutterRoot.path}${Platform.pathSeparator}bin${Platform.pathSeparator}flutter.bat',
      ).writeAsString('@echo off', flush: true);

      final String resolved =
          '${flutterRoot.path}${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}dart-sdk${Platform.pathSeparator}bin${Platform.pathSeparator}dart.exe';

      final String discovered = resolveFlutterRootForVisualTests(
        environment: const {},
        resolvedExecutablePath: resolved,
      );

      expect(discovered, flutterRoot.path);
    });
  });

  group('resolveVisualReviewFontSources', () {
    test('returns MaterialIcons and Roboto files from material_fonts', () async {
      final Directory tempDirectory = await Directory.systemTemp.createTemp(
        'visual-review-fonts-',
      );
      addTearDown(() async {
        if (tempDirectory.existsSync()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final Directory materialFontsDirectory = Directory(
        '${tempDirectory.path}${Platform.pathSeparator}bin${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}material_fonts',
      );
      await materialFontsDirectory.create(recursive: true);
      for (final String fileName in <String>[
        'materialicons-regular.otf',
        'roboto-regular.ttf',
        'roboto-medium.ttf',
        'roboto-bold.ttf',
        'robotocondensed-regular.ttf',
      ]) {
        await File(
          '${materialFontsDirectory.path}${Platform.pathSeparator}$fileName',
        ).writeAsBytes(const <int>[0, 1, 2], flush: true);
      }

      final List<VisualReviewFontSource> sources =
          resolveVisualReviewFontSources(flutterRootPath: tempDirectory.path);

      expect(
        sources.map((source) => source.family).toList(),
        equals(<String>['MaterialIcons', 'Roboto', 'Roboto', 'Roboto']),
      );
      expect(
        sources.map((source) => source.file.uri.pathSegments.last).toList(),
        equals(<String>[
          'materialicons-regular.otf',
          'roboto-bold.ttf',
          'roboto-medium.ttf',
          'roboto-regular.ttf',
        ]),
      );
    });
  });
}

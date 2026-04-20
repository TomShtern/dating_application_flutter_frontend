import 'dart:io';

import 'package:flutter/services.dart';

class VisualReviewFontSource {
  const VisualReviewFontSource({required this.family, required this.file});

  final String family;
  final File file;
}

Future<void>? _fontLoadFuture;

Future<void> ensureVisualReviewFontsLoaded({
  Map<String, String>? environment,
  String? resolvedExecutablePath,
}) {
  return _fontLoadFuture ??= _loadVisualReviewFonts(
    environment: environment,
    resolvedExecutablePath: resolvedExecutablePath,
  );
}

String resolveFlutterRootForVisualTests({
  Map<String, String>? environment,
  String? resolvedExecutablePath,
}) {
  final Map<String, String> effectiveEnvironment =
      environment ?? Platform.environment;
  final String? environmentFlutterRoot = effectiveEnvironment['FLUTTER_ROOT'];
  if (environmentFlutterRoot != null && environmentFlutterRoot.isNotEmpty) {
    final Directory candidate = Directory(environmentFlutterRoot);
    if (_looksLikeFlutterRoot(candidate)) {
      return candidate.path;
    }
  }

  final File resolvedExecutable = File(
    resolvedExecutablePath ?? Platform.resolvedExecutable,
  );
  Directory directory = resolvedExecutable.parent;
  while (directory.path != directory.parent.path) {
    if (_looksLikeFlutterRoot(directory)) {
      return directory.path;
    }
    directory = directory.parent;
  }

  throw StateError(
    'Unable to locate Flutter root for visual review font loading.',
  );
}

List<VisualReviewFontSource> resolveVisualReviewFontSources({
  required String flutterRootPath,
}) {
  final Directory materialFontsDirectory = Directory(
    [
      flutterRootPath,
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
    ].join(Platform.pathSeparator),
  );
  if (!materialFontsDirectory.existsSync()) {
    throw StateError(
      'Material font artifacts were not found at ${materialFontsDirectory.path}.',
    );
  }

  final List<File> files = materialFontsDirectory
      .listSync()
      .whereType<File>()
      .toList(growable: false);

  final File materialIcons = files.firstWhere(
    (file) => _baseName(file).toLowerCase() == 'materialicons-regular.otf',
    orElse: () => throw StateError(
      'MaterialIcons-Regular font was not found in ${materialFontsDirectory.path}.',
    ),
  );

  final List<File> robotoFiles =
      files.where((file) {
        final String name = _baseName(file).toLowerCase();
        return name.startsWith('roboto-') && name.endsWith('.ttf');
      }).toList()..sort(
        (left, right) => _baseName(
          left,
        ).toLowerCase().compareTo(_baseName(right).toLowerCase()),
      );

  if (robotoFiles.isEmpty) {
    throw StateError(
      'Roboto font files were not found in ${materialFontsDirectory.path}.',
    );
  }

  return <VisualReviewFontSource>[
    VisualReviewFontSource(family: 'MaterialIcons', file: materialIcons),
    ...robotoFiles.map(
      (file) => VisualReviewFontSource(family: 'Roboto', file: file),
    ),
  ];
}

Future<void> _loadVisualReviewFonts({
  Map<String, String>? environment,
  String? resolvedExecutablePath,
}) async {
  final String flutterRootPath = resolveFlutterRootForVisualTests(
    environment: environment,
    resolvedExecutablePath: resolvedExecutablePath,
  );
  final List<VisualReviewFontSource> sources = resolveVisualReviewFontSources(
    flutterRootPath: flutterRootPath,
  );

  final Map<String, List<File>> filesByFamily = <String, List<File>>{};
  for (final VisualReviewFontSource source in sources) {
    filesByFamily.putIfAbsent(source.family, () => <File>[]).add(source.file);
  }

  for (final MapEntry<String, List<File>> entry in filesByFamily.entries) {
    final FontLoader loader = FontLoader(entry.key);
    for (final File file in entry.value) {
      loader.addFont(_readFontByteData(file));
    }
    await loader.load();
  }
}

Future<ByteData> _readFontByteData(File file) async {
  final Uint8List bytes = await file.readAsBytes();
  return ByteData.sublistView(bytes);
}

bool _looksLikeFlutterRoot(Directory directory) {
  final String binPath =
      '${directory.path}${Platform.pathSeparator}bin${Platform.pathSeparator}';
  return File('${binPath}flutter.bat').existsSync() ||
      File('${binPath}flutter').existsSync();
}

String _baseName(File file) {
  final String path = file.path;
  final int separatorIndex = path.lastIndexOf(Platform.pathSeparator);
  if (separatorIndex == -1) {
    return path;
  }
  return path.substring(separatorIndex + 1);
}

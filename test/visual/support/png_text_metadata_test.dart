import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'png_text_metadata.dart';

void main() {
  test('embeds text metadata into a png without corrupting the file', () {
    final Uint8List pngBytes = _pngBytes();
    final Uint8List updated = embedPngTextMetadata(pngBytes, {
      'scenarioName': 'signed-in shell matches tab',
      'runLabel': 'run-0007',
      'capturedAtUtc': '2026-04-20T16:12:05Z',
    });

    expect(updated, isNot(equals(pngBytes)));

    final Map<String, String> metadata = readPngTextMetadata(updated);
    expect(metadata['runLabel'], 'run-0007');
    expect(metadata['scenarioName'], 'signed-in shell matches tab');
    expect(metadata['capturedAtUtc'], '2026-04-20T16:12:05Z');
  });
}

Uint8List _pngBytes({
  String base64Data =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO/a0WQAAAAASUVORK5CYII=',
}) {
  return base64Decode(base64Data);
}

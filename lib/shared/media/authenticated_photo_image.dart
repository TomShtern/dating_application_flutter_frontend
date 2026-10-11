import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Loads the bytes for [AuthenticatedPhotoImage]. In the app this is
/// `ApiClient.getPhotoBytes`, which attaches a fresh token on every request.
typedef PhotoBytesLoader = Future<Uint8List> Function(String url);

/// An image fetched through the API client instead of Flutter's own HTTP
/// stack, so backend photos get the same auth headers as API calls.
///
/// The provider holds only the URL and a function: no token is ever kept in a
/// widget. Decoded images live in Flutter's in-memory image cache, keyed by
/// URL; a failed load is evicted so it is not remembered as an image.
@immutable
class AuthenticatedPhotoImage extends ImageProvider<AuthenticatedPhotoImage> {
  const AuthenticatedPhotoImage(this.url, {required this.loadBytes});

  final String url;
  final PhotoBytesLoader loadBytes;

  @override
  Future<AuthenticatedPhotoImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<AuthenticatedPhotoImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AuthenticatedPhotoImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: 1,
      debugLabel: key.url,
    );
  }

  Future<ui.Codec> _load(
    AuthenticatedPhotoImage key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final bytes = await key.loadBytes(key.url);
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer);
    } catch (_) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AuthenticatedPhotoImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;

  @override
  String toString() => 'AuthenticatedPhotoImage("$url")';
}

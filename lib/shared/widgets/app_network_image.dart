import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../app/app_config.dart';
import '../media/authenticated_photo_image.dart';
import '../media/media_url.dart';

/// The one place the app loads a remote image.
///
/// Bytes come through [ApiClient.getPhotoBytes], so backend `/photos/...` URLs
/// are sent with the shared secret and a fresh Clerk token. Any failure
/// (401, 403, 404, 429, offline) shows [fallbackBuilder] and nothing else.
class AppNetworkImage extends ConsumerWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackBuilder,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget Function(BuildContext context)? fallbackBuilder;

  static double? _safeDim(double? v) =>
      v != null && v.isFinite && !v.isNaN && v > 0 ? v : null;

  @visibleForTesting
  static int? cacheDim(double? logical, double dpr) {
    final safe = _safeDim(logical);
    if (safe == null) return null;
    return (safe * dpr).toInt();
  }

  Widget _fallback(BuildContext context) => fallbackBuilder != null
      ? fallbackBuilder!(context)
      : const Center(child: SizedBox.shrink());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final apiClient = ref.watch(apiClientProvider);
    final resolvedUrl =
        resolveMediaUrl(
          rawUrl: url,
          baseUrl: ref.watch(appConfigProvider).baseUrl,
        ) ??
        url;

    final image = Image(
      image: ResizeImage.resizeIfNeeded(
        cacheDim(width, dpr),
        cacheDim(height, dpr),
        AuthenticatedPhotoImage(
          resolvedUrl,
          loadBytes: apiClient.getPhotoBytes,
        ),
      ),
      width: _safeDim(width),
      height: _safeDim(height),
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        if (frame == null) return _fallback(context);
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 200),
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(context),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

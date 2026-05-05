import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final safeWidth = _safeDim(width);
    final safeHeight = _safeDim(height);
    final image = CachedNetworkImage(
      imageUrl: url,
      width: safeWidth,
      height: safeHeight,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      memCacheWidth: cacheDim(width, dpr),
      memCacheHeight: cacheDim(height, dpr),
      placeholder: (context, url) => fallbackBuilder != null
          ? fallbackBuilder!(context)
          : const Center(child: SizedBox.shrink()),
      errorWidget: (context, url, error) => fallbackBuilder != null
          ? fallbackBuilder!(context)
          : const Center(child: SizedBox.shrink()),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import 'app_network_image.dart';
import 'user_avatar.dart';
import '../media/media_url.dart';

class PersonMediaThumbnail extends ConsumerWidget {
  const PersonMediaThumbnail({
    super.key,
    required this.name,
    this.photoUrl,
    this.width = 96,
    this.height = 128,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
  });

  final String name;
  final String? photoUrl;
  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolvedPhotoUrl = resolveMediaUrl(
      rawUrl: photoUrl,
      baseUrl: ref.watch(appConfigProvider).baseUrl,
    );

    final fallback = _PhotoFallback(name: name, width: width, height: height);

    if (resolvedPhotoUrl == null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: SizedBox(width: width, height: height, child: fallback),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: AppNetworkImage(
          url: resolvedPhotoUrl,
          width: width,
          height: height,
          borderRadius: borderRadius,
          fallbackBuilder: (_) => fallback,
        ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({
    required this.name,
    required this.width,
    required this.height,
  });

  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = appPhotoFallbackPalette(context, name);
    final showMediaIcon = width >= 88 && height >= 104;
    final emblemSize = showMediaIcon ? 44.0 : 0.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.surface, palette.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.15),
                  radius: 0.85,
                  colors: [
                    palette.accentSoft.withValues(alpha: 0.36),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showMediaIcon)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.accentSoft,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.all(color: palette.outline),
                    ),
                    child: SizedBox.square(
                      dimension: emblemSize,
                      child: Icon(
                        Icons.photo_library_outlined,
                        size: 22,
                        color: palette.accent,
                      ),
                    ),
                  ),
                if (showMediaIcon) const SizedBox(height: 10),
                Text(
                  appPhotoInitials(name),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: palette.labelForeground,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
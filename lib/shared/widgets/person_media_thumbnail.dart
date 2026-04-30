import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
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

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: resolvedPhotoUrl == null
            ? _PhotoFallback(name: name, width: width, height: height)
            : Image.network(
                resolvedPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PhotoFallback(
                    name: name,
                    width: width,
                    height: height,
                  );
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }

                  return _PhotoFallback(
                    name: name,
                    width: width,
                    height: height,
                  );
                },
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
    final showPendingCopy = width >= 96 && height >= 120;
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
          if (showPendingCopy)
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.labelBackground,
                  borderRadius: const BorderRadius.all(Radius.circular(999)),
                  border: Border.all(color: palette.outline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 13,
                        color: palette.labelForeground,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Photo pending',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: palette.labelForeground,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

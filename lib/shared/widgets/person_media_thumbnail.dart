import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
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
    final hasPhotoHint = (photoUrl?.trim().isNotEmpty ?? false);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: resolvedPhotoUrl == null
            ? _PhotoFallback(name: name, emphasizeMedia: hasPhotoHint)
            : Image.network(
                resolvedPhotoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _PhotoFallback(name: name, emphasizeMedia: true);
                },
                loadingBuilder: (context, child, progress) {
                  if (progress == null) {
                    return child;
                  }

                  return _PhotoFallback(name: name, emphasizeMedia: true);
                },
              ),
      ),
    );
  }
}

class _PhotoFallback extends StatelessWidget {
  const _PhotoFallback({required this.name, required this.emphasizeMedia});

  final String name;
  final bool emphasizeMedia;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = emphasizeMedia
        ? LinearGradient(
            colors: _emphasizedFallbackColors(colorScheme, name),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: emphasizeMedia
                    ? Colors.white
                    : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 0,
              ),
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.72),
                borderRadius: const BorderRadius.all(Radius.circular(999)),
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
                      Icons.person_rounded,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Photo pending',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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

List<Color> _emphasizedFallbackColors(ColorScheme colorScheme, String name) {
  if (colorScheme.brightness == Brightness.dark) {
    return const [Color(0xFF164E63), Color(0xFF355F7E), Color(0xFF705C95)];
  }

  final hash = name.trim().runes.fold<int>(0, (total, rune) => total + rune);
  final hueOffset = (hash % 72) - 36;

  Color shifted(Color source, {double saturationBoost = 0}) {
    final hsl = HSLColor.fromColor(source);
    return hsl
        .withHue((hsl.hue + hueOffset) % 360)
        .withSaturation((hsl.saturation + saturationBoost).clamp(0.42, 0.68))
        .withLightness(hsl.lightness.clamp(0.42, 0.58))
        .toColor();
  }

  return [
    shifted(colorScheme.primaryContainer, saturationBoost: 0.05),
    shifted(colorScheme.tertiaryContainer, saturationBoost: 0.03),
    shifted(colorScheme.secondaryContainer),
  ];
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '•';
  }

  final first = String.fromCharCodes(parts.first.runes.take(1));
  final second = parts.length > 1
      ? String.fromCharCodes(parts.last.runes.take(1))
      : '';
  return '$first$second'.toUpperCase();
}

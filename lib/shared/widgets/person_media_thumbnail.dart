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
            colors: [
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
              colorScheme.secondaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              colorScheme.surfaceContainerHigh,
              colorScheme.surfaceContainerLowest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Center(
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: emphasizeMedia
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
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

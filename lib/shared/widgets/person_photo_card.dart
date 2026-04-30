import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../../theme/app_theme.dart';
import '../media/media_url.dart';
import 'user_avatar.dart';

/// Photo-backed person card with fallback when photo is unavailable.
/// Shows: photo or gradient monogram fallback, name, age, optional location line.
/// Used in Discover candidates, Matches, Pending likers, Standouts.
class PersonPhotoCard extends StatelessWidget {
  const PersonPhotoCard({
    super.key,
    required this.name,
    this.age,
    this.photoUrl,
    this.location,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final String name;
  final int? age;
  final String? photoUrl;
  final String? location;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final photoRadius = compact ? 22.0 : 28.0;

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.cardRadius,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 8 : 10,
        ),
        child: Row(
          children: [
            // Photo avatar circle
            _PersonPhoto(name: name, photoUrl: photoUrl, radius: photoRadius),
            SizedBox(width: compact ? 10 : 14),
            // Name, age, location
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (age != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '$age',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (location != null) ...[
                    SizedBox(height: compact ? 1 : 2),
                    Text(
                      location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}

/// Internal widget for person photo with network loading and monogram fallback.
class _PersonPhoto extends ConsumerWidget {
  const _PersonPhoto({required this.name, this.photoUrl, required this.radius});

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedUrl = resolveMediaUrl(
      rawUrl: photoUrl,
      baseUrl: ref.watch(appConfigProvider).baseUrl,
    );
    final diameter = radius * 2;

    return SizedBox(
      width: diameter,
      height: diameter,
      child: ClipOval(
        child: resolvedUrl == null
            ? _MonogramFallback(name: name, colorScheme: colorScheme)
            : Image.network(
                resolvedUrl,
                fit: BoxFit.cover,
                width: diameter,
                height: diameter,
                errorBuilder: (_, error, stackTrace) =>
                    _MonogramFallback(name: name, colorScheme: colorScheme),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return _MonogramFallback(
                    name: name,
                    colorScheme: colorScheme,
                  );
                },
              ),
      ),
    );
  }
}

/// Monogram fallback when no photo is available.
class _MonogramFallback extends StatelessWidget {
  const _MonogramFallback({required this.name, required this.colorScheme});

  final String name;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final palette = appPhotoFallbackPalette(context, name);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [palette.surface, palette.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          appPhotoInitials(name),
          style: TextStyle(
            color: palette.labelForeground,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

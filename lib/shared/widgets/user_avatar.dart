import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../media/media_url.dart';

class AppPhotoFallbackPalette {
  const AppPhotoFallbackPalette({
    required this.surface,
    required this.surfaceAlt,
    required this.accent,
    required this.accentSoft,
    required this.labelBackground,
    required this.labelForeground,
    required this.outline,
  });

  final Color surface;
  final Color surfaceAlt;
  final Color accent;
  final Color accentSoft;
  final Color labelBackground;
  final Color labelForeground;
  final Color outline;
}

AppPhotoFallbackPalette appPhotoFallbackPalette(
  BuildContext context,
  String name,
) {
  final colorScheme = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final hash = name.trim().runes.fold<int>(0, (total, rune) => total + rune);
  final baseHue = HSLColor.fromColor(colorScheme.primaryContainer).hue;
  final hue = (baseHue + (hash % 64) - 32 + 360) % 360;

  Color fromHsl(double saturation, double lightness) {
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  if (isDark) {
    final accent = fromHsl(0.62, 0.74);
    return AppPhotoFallbackPalette(
      surface: fromHsl(0.22, 0.22),
      surfaceAlt: fromHsl(0.28, 0.28),
      accent: accent,
      accentSoft: accent.withValues(alpha: 0.18),
      labelBackground: colorScheme.surface.withValues(alpha: 0.74),
      labelForeground: accent,
      outline: accent.withValues(alpha: 0.16),
    );
  }

  final accent = fromHsl(0.56, 0.50);
  return AppPhotoFallbackPalette(
    surface: fromHsl(0.34, 0.93),
    surfaceAlt: fromHsl(0.30, 0.89),
    accent: accent,
    accentSoft: accent.withValues(alpha: 0.12),
    labelBackground: colorScheme.surface.withValues(alpha: 0.88),
    labelForeground: fromHsl(0.44, 0.38),
    outline: accent.withValues(alpha: 0.14),
  );
}

String appPhotoInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) {
    return '•';
  }

  final first = _firstSymbol(parts.first);
  final second = parts.length > 1 ? _firstSymbol(parts.last) : '';
  return '$first$second'.toUpperCase();
}

class UserAvatar extends ConsumerWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 24,
  });

  final String name;
  final String? photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = appPhotoFallbackPalette(context, name);
    final resolvedPhotoUrl = resolveMediaUrl(
      rawUrl: photoUrl,
      baseUrl: ref.watch(appConfigProvider).baseUrl,
    );
    final frameSize = radius * 2;
    final innerPadding = radius >= 28 ? 3.0 : 2.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: frameSize,
      height: frameSize,
      decoration: BoxDecoration(shape: BoxShape.circle, color: palette.outline),
      padding: EdgeInsets.all(innerPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: palette.labelBackground,
        ),
        child: ClipOval(
          child: resolvedPhotoUrl == null
              ? _AvatarFallback(name: name, radius: radius)
              : Image.network(
                  resolvedPhotoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _AvatarFallback(name: name, radius: radius);
                  },
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) {
                      return child;
                    }

                    return _AvatarFallback(name: name, radius: radius);
                  },
                ),
        ),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.name, required this.radius});

  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = appPhotoFallbackPalette(context, name);

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [palette.surface, palette.surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          appPhotoInitials(name),
          style: theme.textTheme.titleMedium?.copyWith(
            color: palette.labelForeground,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.72,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

String _firstSymbol(String value) {
  if (value.isEmpty) {
    return '';
  }

  return String.fromCharCodes(value.runes.take(1));
}

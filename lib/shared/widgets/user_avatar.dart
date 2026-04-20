import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../media/media_url.dart';
import '../../theme/app_theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppTheme.avatarGradient(context),
        boxShadow: AppTheme.softShadow(context),
      ),
      padding: EdgeInsets.all(innerPadding),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
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
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w800,
            fontSize: radius * 0.72,
            letterSpacing: -0.5,
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

  final first = _firstSymbol(parts.first);
  final second = parts.length > 1 ? _firstSymbol(parts.last) : '';
  return '$first$second'.toUpperCase();
}

String _firstSymbol(String value) {
  if (value.isEmpty) {
    return '';
  }

  return String.fromCharCodes(value.runes.take(1));
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ShellHero extends StatelessWidget {
  const ShellHero({
    super.key,
    required this.title,
    required this.description,
    this.eyebrowLabel,
    this.eyebrowIcon,
    this.header,
    this.badges = const <Widget>[],
    this.footer,
    this.compact = false,
    this.centerContent = false,
  });

  final String title;
  final String description;
  final String? eyebrowLabel;
  final IconData? eyebrowIcon;
  final Widget? header;
  final List<Widget> badges;
  final Widget? footer;
  final bool compact;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final titleStyle = compact
        ? theme.textTheme.titleLarge
        : theme.textTheme.headlineSmall;
    final crossAxisAlignment = centerContent
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = centerContent ? TextAlign.center : TextAlign.start;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: AppTheme.heroGradient(context),
        prominent: true,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: compact ? -18 : -24,
            right: compact ? -6 : -10,
            child: _AmbientGlow(
              size: compact ? 78 : 104,
              color: colorScheme.tertiary.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            bottom: compact ? -18 : -22,
            left: compact ? -6 : -10,
            child: _AmbientGlow(
              size: compact ? 58 : 82,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: AppTheme.sectionPadding(compact: compact),
            child: Column(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                if (eyebrowLabel case final eyebrow?) ...[
                  ShellHeroPill(icon: eyebrowIcon, label: eyebrow),
                  SizedBox(height: compact ? 12 : 14),
                ],
                if (header case final heading?) ...[
                  Align(
                    alignment: centerContent
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: heading,
                  ),
                  SizedBox(height: compact ? 14 : 18),
                ],
                Text(title, style: titleStyle, textAlign: textAlign),
                SizedBox(height: compact ? 8 : 10),
                Text(
                  description,
                  textAlign: textAlign,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (badges.isNotEmpty) ...[
                  SizedBox(height: compact ? 14 : 16),
                  Wrap(
                    alignment: centerContent
                        ? WrapAlignment.center
                        : WrapAlignment.start,
                    spacing: 10,
                    runSpacing: 10,
                    children: badges,
                  ),
                ],
                if (footer case final trailing?) ...[
                  SizedBox(height: compact ? 14 : 18),
                  Align(
                    alignment: centerContent
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: trailing,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShellHeroPill extends StatelessWidget {
  const ShellHeroPill({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.glassDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon case final heroIcon) ...[
              Icon(heroIcon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

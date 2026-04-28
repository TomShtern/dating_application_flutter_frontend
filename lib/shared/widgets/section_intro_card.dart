import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SectionIntroCard extends StatelessWidget {
  const SectionIntroCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
    this.badges = const <Widget>[],
    this.iconBackgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;
  final List<Widget> badges;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        iconBackgroundColor ??
                        colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      icon,
                      color: iconColor ?? colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 10, runSpacing: 10, children: badges),
            ],
          ],
        ),
      ),
    );
  }
}

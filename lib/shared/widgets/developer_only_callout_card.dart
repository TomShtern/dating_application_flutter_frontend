import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Visually distinct developer-only surface treatment.
/// Amber/yellow-tinted card with a prominent "Developer only" badge.
/// Used in dev-user picker, settings session controls, browse developer panel,
/// verification debug area.
class DeveloperOnlyCalloutCard extends StatelessWidget {
  const DeveloperOnlyCalloutCard({
    super.key,
    required this.title,
    this.description,
    this.child,
    this.actions = const [],
  });

  final String title;
  final String? description;
  final Widget? child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Amber/yellow tinting using the tertiaryContainer range as specified
    final amberBg = Color.lerp(
      colorScheme.tertiaryContainer,
      const Color(0xFFFFE082), // warm amber
      0.35,
    )!;
    final amberOnBg = Color.lerp(
      colorScheme.onTertiaryContainer,
      const Color(0xFF5D4037), // warm brown
      0.4,
    )!;
    final amberBadge = Color.lerp(amberBg, const Color(0xFFFFc107), 0.5)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: amberBg.withValues(alpha: 0.35),
        borderRadius: AppTheme.cardRadius,
        border: Border.all(color: amberBadge.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge + title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: amberBadge.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    'Developer only',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: amberOnBg,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: amberOnBg,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: amberOnBg.withValues(alpha: 0.8),
                ),
              ),
            ],
            if (child != null) ...[const SizedBox(height: 10), child!],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: actions),
            ],
          ],
        ),
      ),
    );
  }
}

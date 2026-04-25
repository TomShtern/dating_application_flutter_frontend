import 'package:flutter/material.dart';

/// Compact visual representation of compatibility score.
/// Shows a score number + colored bar or stars.
/// Wire to match-quality data only (no fake scores).
class CompatibilityMeter extends StatelessWidget {
  const CompatibilityMeter({
    super.key,
    required this.score,
    this.label,
    this.starDisplay,
    this.compact = false,
  });

  final int score; // 0-100
  final String? label;
  final String? starDisplay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final barWidth = compact ? 60.0 : 90.0;
    final barHeight = compact ? 4.0 : 6.0;

    // Color based on score ranges
    final barColor = score >= 75
        ? colorScheme.primary
        : score >= 50
        ? colorScheme.tertiary
        : colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (starDisplay != null) ...[
          Text(starDisplay!, style: TextStyle(fontSize: compact ? 12 : 14)),
          const SizedBox(width: 4),
        ],
        Text(
          '$score',
          style:
              (compact
                      ? theme.textTheme.labelSmall
                      : theme.textTheme.labelMedium)
                  ?.copyWith(fontWeight: FontWeight.w800, color: barColor),
        ),
        const SizedBox(width: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(barHeight / 2),
          child: SizedBox(
            width: barWidth,
            height: barHeight,
            child: LinearProgressIndicator(
              value: (score.clamp(0, 100)) / 100,
              backgroundColor: colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: barHeight,
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

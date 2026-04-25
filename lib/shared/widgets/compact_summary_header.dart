import 'package:flutter/material.dart';

/// Compact header for name + one-line summary + optional action row.
/// Used in match cards, conversation rows, notification items.
class CompactSummaryHeader extends StatelessWidget {
  const CompactSummaryHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.titleStyle,
    this.dense = false,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTitleStyle =
        titleStyle ??
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: dense ? FontWeight.w600 : FontWeight.w700,
          color: colorScheme.onSurface,
        );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: effectiveTitleStyle,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              if (subtitle != null) ...[
                SizedBox(height: dense ? 1 : 2),
                Text(
                  subtitle!,
                  style: subtitleStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[SizedBox(width: dense ? 8 : 12), trailing!],
      ],
    );
  }
}

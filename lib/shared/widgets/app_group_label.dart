import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AppGroupLabel extends StatelessWidget {
  const AppGroupLabel({
    super.key,
    required this.title,
    this.accentColor,
    this.countText,
    this.trailing,
  });

  final String title;
  final Color? accentColor;
  final String? countText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedAccent = accentColor ?? colorScheme.primary;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 3,
            decoration: BoxDecoration(
              color: resolvedAccent.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
          ),
          const SizedBox(width: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (countText != null) ...[
            const SizedBox(width: 8),
            Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: resolvedAccent.withValues(
                    alpha: theme.brightness == Brightness.dark ? 0.18 : 0.08,
                  ),
                  borderRadius: AppTheme.chipRadius,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  child: Text(
                    countText!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: resolvedAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Align(alignment: Alignment.center, child: trailing!),
          ],
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

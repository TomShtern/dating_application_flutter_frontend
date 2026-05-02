import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'profile_completion.dart';

class ProfileChecklistCard extends StatelessWidget {
  const ProfileChecklistCard({
    super.key,
    required this.fields,
    this.onFieldTap,
  });

  final List<MissingField> fields;
  final void Function(String fieldKey)? onFieldTap;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = isDark
        ? const Color(0xFFF5C542)
        : const Color(0xFFD49A3A);

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
          colorScheme.surfaceContainerLow,
        ),
        borderRadius: AppTheme.cardRadius,
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.22 : 0.14),
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 18,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finish your profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Complete the steps below to start matching.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.cardGap),
            Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.28)),
            const SizedBox(height: AppTheme.compactCardGap),
            for (final field in fields) ...[
              _ChecklistRow(
                field: field,
                accentColor: accentColor,
                onTap: onFieldTap != null ? () => onFieldTap!(field.key) : null,
              ),
              if (field != fields.last)
                const SizedBox(height: AppTheme.compactCardGap),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({
    required this.field,
    required this.accentColor,
    this.onTap,
  });

  final MissingField field;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.cardRadius,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: field.isActionable ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(field.icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!field.isActionable) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Set during sign-up',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (field.isActionable)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
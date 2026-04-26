import 'package:flutter/material.dart';

import '../../models/achievement_summary.dart';
import '../../theme/app_theme.dart';

Future<void> showAchievementDetailSheet({
  required BuildContext context,
  required AchievementSummary achievement,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _AchievementDetailSheet(achievement: achievement),
  );
}

class _AchievementDetailSheet extends StatelessWidget {
  const _AchievementDetailSheet({required this.achievement});

  final AchievementSummary achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: SingleChildScrollView(
        padding: AppTheme.screenPadding(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Achievement detail', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            _DetailRow(label: 'Achievement', value: achievement.title),
            const SizedBox(height: 10),
            _DetailRow(label: 'Status', value: achievement.statusLabel),
            if (achievement.subtitle case final subtitle?) ...[
              const SizedBox(height: 10),
              _DetailRow(label: 'Description', value: subtitle),
            ],
            if (achievement.progress case final progress?) ...[
              const SizedBox(height: 10),
              _DetailRow(label: 'Progress', value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: theme.textTheme.labelLarge),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(value, style: theme.textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}

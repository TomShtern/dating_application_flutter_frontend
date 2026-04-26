import 'package:flutter/material.dart';

import '../../models/user_stats.dart';
import '../../theme/app_theme.dart';

Future<void> showStatDetailSheet({
  required BuildContext context,
  required UserStatItem item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (context) => _StatDetailSheet(item: item),
  );
}

class _StatDetailSheet extends StatelessWidget {
  const _StatDetailSheet({required this.item});

  final UserStatItem item;

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
            Text('Stat detail', style: theme.textTheme.titleLarge),
            const SizedBox(height: 14),
            _DetailRow(label: 'Metric', value: item.label),
            const SizedBox(height: 10),
            _DetailRow(label: 'Backend value', value: item.value),
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

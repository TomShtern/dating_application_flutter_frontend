import 'package:flutter/material.dart';

/// Horizontal scrollable row of highlight chips.
/// Used for match-quality highlights, interest tags.
class HighlightTagRow extends StatelessWidget {
  const HighlightTagRow({super.key, required this.tags, this.icon});

  final List<String> tags;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tags.map((tag) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Chip(
              avatar: icon != null
                  ? Icon(icon, size: 14, color: colorScheme.onSurfaceVariant)
                  : null,
              label: Text(tag),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            ),
          );
        }).toList(),
      ),
    );
  }
}

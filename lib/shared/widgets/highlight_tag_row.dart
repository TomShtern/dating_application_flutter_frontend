import 'package:flutter/material.dart';

/// Wrapping row of highlight chips used for match-quality and interest tags.
class HighlightTagRow extends StatelessWidget {
  const HighlightTagRow({super.key, required this.tags, this.icon});

  final List<String> tags;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags
          .map((tag) {
            return Chip(
              avatar: icon != null
                  ? Icon(icon, size: 14, color: colorScheme.onSurfaceVariant)
                  : null,
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 126),
                child: Text(tag, overflow: TextOverflow.ellipsis),
              ),
              labelStyle: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
            );
          })
          .toList(growable: false),
    );
  }
}

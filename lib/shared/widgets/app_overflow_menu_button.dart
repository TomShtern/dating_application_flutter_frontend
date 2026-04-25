import 'package:flutter/material.dart';

/// Reusable kebab (⋮) overflow menu button that replaces shield-icon patterns.
/// Shows a [PopupMenuButton] with the provided items.
class AppOverflowMenuButton<T> extends StatelessWidget {
  const AppOverflowMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.tooltip = 'More options',
  });

  final List<PopupMenuEntry<T>> items;
  final void Function(T)? onSelected;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      icon: Icon(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 22,
      ),
      tooltip: tooltip,
      padding: const EdgeInsets.all(8),
      itemBuilder: (_) => items,
      onSelected: onSelected,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      color: colorScheme.surfaceContainerHigh,
      elevation: 4,
      position: PopupMenuPosition.under,
    );
  }
}

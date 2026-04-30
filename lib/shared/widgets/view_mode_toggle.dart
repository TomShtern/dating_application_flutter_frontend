import 'package:flutter/material.dart';

/// Toggle between list and grid view modes for browsing surfaces.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.isGrid,
    this.onChanged,
    this.showTextLabels = true,
  });

  final bool isGrid;
  final ValueChanged<bool>? onChanged;
  final bool showTextLabels;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<bool>(
      segments: [
        ButtonSegment<bool>(
          value: true,
          icon: const Icon(Icons.grid_view_rounded, size: 18),
          label: showTextLabels ? const Text('Grid') : null,
          tooltip: 'Grid view',
        ),
        ButtonSegment<bool>(
          value: false,
          icon: const Icon(Icons.view_agenda_outlined, size: 18),
          label: showTextLabels ? const Text('List') : null,
          tooltip: 'List view',
        ),
      ],
      selected: {isGrid},
      onSelectionChanged: (selected) {
        if (onChanged != null && selected.isNotEmpty) {
          onChanged!(selected.first);
        }
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }

          return colorScheme.surface.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark
                ? 0.82
                : 0.96,
          );
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 40)),
      ),
    );
  }
}

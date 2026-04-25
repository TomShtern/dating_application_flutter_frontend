import 'package:flutter/material.dart';

/// Toggle between list and grid view modes for browsing surfaces.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({super.key, required this.isGrid, this.onChanged});

  final bool isGrid;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          value: false,
          icon: Icon(Icons.view_list_outlined, size: 18),
          tooltip: 'List view',
        ),
        ButtonSegment<bool>(
          value: true,
          icon: Icon(Icons.grid_view_outlined, size: 18),
          tooltip: 'Grid view',
        ),
      ],
      selected: {!isGrid ? false : true},
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
          return colorScheme.surfaceContainerLow;
        }),
        foregroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimaryContainer;
          }
          return colorScheme.onSurfaceVariant;
        }),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(0, 34)),
      ),
    );
  }
}

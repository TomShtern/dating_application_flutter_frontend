import 'package:flutter/material.dart';

/// Single-line compact information strip for inline metadata.
/// Shows an icon + label on the left, optional trailing on the right.
/// Used for location, age/distance, recency, status info.
class CompactContextStrip extends StatelessWidget {
  const CompactContextStrip({
    super.key,
    this.leadingIcon,
    this.label,
    this.trailing,
    this.children = const [],
  });

  final IconData? leadingIcon;
  final String? label;
  final Widget? trailing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
        ],
        if (label != null)
          Flexible(
            child: Text(
              label!,
              style: labelStyle,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ...children.map(
          (child) =>
              Padding(padding: const EdgeInsets.only(left: 6), child: child),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

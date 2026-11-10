import 'package:flutter/material.dart';

/// Neutral slot pill (Primary vet, Emergency contact, …).
class RolePill extends StatelessWidget {
  const RolePill({
    super.key,
    required this.label,
    this.leadingIcon,
    this.semanticsIdentifier,
  });

  final String label;
  final IconData? leadingIcon;
  final String? semanticsIdentifier;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.surfaceContainerHighest;
    final fg = theme.colorScheme.onSurfaceVariant;
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (semanticsIdentifier == null) return child;
    return Semantics(identifier: semanticsIdentifier, child: child);
  }
}

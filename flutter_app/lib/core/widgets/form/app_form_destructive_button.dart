import 'package:flutter/material.dart';

/// Destructive outline action separated below the primary save row.
class AppFormDestructiveButton extends StatelessWidget {
  const AppFormDestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.buttonKey,
    this.icon = Icons.delete_outline,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? buttonKey;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      key: buttonKey,
      onPressed: onPressed,
      icon: Icon(icon, color: theme.colorScheme.error),
      style: OutlinedButton.styleFrom(
        foregroundColor: theme.colorScheme.error,
        side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
        minimumSize: const Size.fromHeight(48),
      ),
      label: Text(label),
    );
  }
}

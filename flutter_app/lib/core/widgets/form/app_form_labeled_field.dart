import 'package:flutter/material.dart';

/// Persistent label above a form field (external label pattern).
class AppFormLabeledField extends StatelessWidget {
  const AppFormLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

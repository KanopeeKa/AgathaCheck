import 'package:flutter/material.dart';

/// Persistent label above a form field (external label pattern).
class AppFormLabeledField extends StatelessWidget {
  const AppFormLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.subtitle,
    this.isTextField = true,
  });

  final String label;
  final String? subtitle;
  final Widget child;

  /// When true (default), associates [label] with a single text-field semantics
  /// node. Set false for controls that supply their own semantics (e.g. date
  /// pickers exposed as buttons).
  final bool isTextField;

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
        if (isTextField)
          Semantics(
            label: subtitle == null ? label : '$label. $subtitle',
            child: child,
          )
        else
          child,
      ],
    );
  }
}

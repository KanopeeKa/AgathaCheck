import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Compact inline prompt for missing profile data (not a care recommendation).
class ProfilePromptRow extends StatelessWidget {
  const ProfilePromptRow({
    super.key,
    required this.message,
    required this.icon,
    this.onDismiss,
    this.dismissLabel,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onDismiss;
  final String? dismissLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: AppColorTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          dense: true,
          leading: Icon(icon, color: AppColorTokens.muted, size: 20),
          title: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColorTokens.body,
            ),
          ),
          trailing: onDismiss != null
              ? TextButton(
                  onPressed: onDismiss,
                  child: Text(dismissLabel ?? 'Dismiss'),
                )
              : null,
        ),
      ),
    );
  }
}

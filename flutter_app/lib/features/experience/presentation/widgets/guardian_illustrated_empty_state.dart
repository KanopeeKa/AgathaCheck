import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// A compact, actionable empty state for Guardian dashboard sections.
///
/// The illustration is decorative; the title, detail, and action communicate
/// the same next step to assistive technologies.
class GuardianIllustratedEmptyState extends StatelessWidget {
  const GuardianIllustratedEmptyState({
    super.key,
    required this.title,
    required this.body,
    this.assetPath,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final String body;
  final String? assetPath;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: AppColorTokens.heading,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          body,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assetPath == null)
            text
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: SizedBox(
                    width: 64,
                    height: 56,
                    child: Image.asset(assetPath!, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: text),
              ],
            ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              key: actionKey,
              onPressed: onAction,
              icon: Icon(actionIcon ?? Icons.add, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';

/// Attention role — compact callout with semantic icon and subtle background.
class CareAttentionCallout extends StatelessWidget {
  const CareAttentionCallout({
    super.key,
    required this.message,
    required this.semanticLabel,
    this.icon = Icons.error_outline,
    this.onTap,
  });

  final String message;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final child = Container(
      width: double.infinity,
      padding: CareSurfaceTokens.attentionPadding,
      decoration: BoxDecoration(
        color: CareSurfaceTokens.attentionBackground(colorScheme),
        borderRadius: BorderRadius.circular(CareSurfaceTokens.attentionRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: CareSurfaceTokens.attentionIcon(colorScheme),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: CareSurfaceTokens.attentionForeground(colorScheme),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: onTap == null
          ? child
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius:
                    BorderRadius.circular(CareSurfaceTokens.attentionRadius),
                child: child,
              ),
            ),
    );
  }
}

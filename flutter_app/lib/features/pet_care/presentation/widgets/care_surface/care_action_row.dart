import 'package:flutter/material.dart';

import '../../../../health_tracking/presentation/widgets/health_entry_status.dart';
import 'care_surface_tokens.dart';

/// Action role — care item row with family icon, title, status subtitle, and affordance.
class CareActionRow extends StatelessWidget {
  const CareActionRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    required this.statusTreatment,
    required this.semanticLabel,
    required this.leading,
    required this.trailingLabel,
    this.onPressed,
    this.onTap,
    this.inset = false,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final HealthEntryStatusTreatment statusTreatment;
  final String semanticLabel;
  final Widget leading;
  final String trailingLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onTap;

  /// When true, renders flat on a [CareCollectionInsetList] background (no card chrome).
  final bool inset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final radius = inset ? BorderRadius.zero : BorderRadius.circular(
      CareSurfaceTokens.actionRadius,
    );

    return Semantics(
      label: semanticLabel,
      button: onTap != null || onPressed != null,
      child: Material(
        color: inset ? Colors.transparent : colorScheme.surface,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CareSurfaceTokens.rowMinHeight,
            ),
            child: Padding(
              padding: CareSurfaceTokens.actionPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  leading,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        HealthEntryStatusLabel(
                          text: statusLabel,
                          treatment: statusTreatment,
                          compact: false,
                        ),
                      ],
                    ),
                  ),
                  if (onPressed != null) ...[
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: onPressed,
                      child: Text(trailingLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

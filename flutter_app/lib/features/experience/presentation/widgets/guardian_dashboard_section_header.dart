import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Eyebrow title + optional section-level "All …" action for dashboard sections.
class GuardianDashboardSectionHeader extends StatelessWidget {
  const GuardianDashboardSectionHeader({
    super.key,
    required this.title,
    this.titleColor = AppColorTokens.guardianActive,
    this.actionLabel,
    this.onAction,
    this.actionKey,
  });

  final String title;
  final Color titleColor;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: titleColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          Flexible(
            fit: FlexFit.loose,
            child: TextButton(
              key: actionKey,
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(48, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
      ],
    );
  }
}

/// Responsive width for compact pet selector cards in the dashboard rail.
double guardianDashboardPetCardWidth(double viewportWidth) {
  if (viewportWidth < 600) return 142;
  if (viewportWidth < 900) return 160;
  if (viewportWidth < 1200) return 170;
  return 172;
}

/// Responsive width for the add-pet tile in the dashboard rail.
double guardianDashboardAddPetTileWidth(double viewportWidth) {
  if (viewportWidth < 600) return 72;
  if (viewportWidth < 900) return 76;
  return 80;
}

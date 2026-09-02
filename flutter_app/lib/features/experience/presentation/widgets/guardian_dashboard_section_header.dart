import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Eyebrow title for dashboard sections.
class GuardianDashboardSectionHeader extends StatelessWidget {
  const GuardianDashboardSectionHeader({
    super.key,
    required this.title,
    this.titleColor = AppColorTokens.petCareActive,
  });

  final String title;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelLarge?.copyWith(
        color: titleColor,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Left-aligned "All …" link shown below dashboard section content.
class GuardianDashboardSectionLink extends StatelessWidget {
  const GuardianDashboardSectionLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.linkKey,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: linkKey,
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
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

/// Minimum card width for the guardian full pets list grid (slightly wider than dashboard rail).
double guardianPetsListCardMinWidth(double viewportWidth) {
  if (viewportWidth < 600) return 156;
  if (viewportWidth < 900) return 180;
  return 200;
}

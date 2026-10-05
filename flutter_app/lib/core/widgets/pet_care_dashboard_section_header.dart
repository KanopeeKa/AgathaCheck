import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Eyebrow title for dashboard sections.
class PetCareDashboardSectionHeader extends StatelessWidget {
  const PetCareDashboardSectionHeader({
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

/// Section header row: eyebrow title (optional) + optional trailing "All …" action.
///
/// Use for all dashboard sections with an optional All … action.
class PetCareDashboardSectionChrome extends StatelessWidget {
  const PetCareDashboardSectionChrome({
    super.key,
    this.title,
    this.titleColor = AppColorTokens.petCareActive,
    this.linkLabel,
    this.onLinkPressed,
    this.linkKey,
  });

  final String? title;
  final Color titleColor;
  final String? linkLabel;
  final VoidCallback? onLinkPressed;
  final Key? linkKey;

  @override
  Widget build(BuildContext context) {
    final showTitle = title != null && title!.isNotEmpty;
    final showLink = linkLabel != null && onLinkPressed != null;

    if (!showTitle && !showLink) return const SizedBox.shrink();

    final titleWidget = showTitle
        ? PetCareDashboardSectionHeader(title: title!, titleColor: titleColor)
        : const SizedBox.shrink();
    final linkWidget = showLink
        ? PetCareDashboardSectionLink(
            linkKey: linkKey,
            label: linkLabel!,
            onPressed: onLinkPressed!,
            alignEnd: true,
          )
        : const SizedBox.shrink();

    if (showTitle) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleWidget),
          if (showLink) Flexible(child: linkWidget),
        ],
      );
    }

    return Align(alignment: Alignment.centerRight, child: linkWidget);
  }
}

/// Trailing "All …" link for dashboard section chrome.
class PetCareDashboardSectionLink extends StatelessWidget {
  const PetCareDashboardSectionLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.linkKey,
    this.alignEnd = false,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? linkKey;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
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
double petCareDashboardPetCardWidth(double viewportWidth) {
  if (viewportWidth < 600) return 142;
  if (viewportWidth < 900) return 160;
  if (viewportWidth < 1200) return 170;
  return 172;
}

/// Responsive width for the add-pet tile in the dashboard rail.
double petCareDashboardAddPetTileWidth(double viewportWidth) {
  if (viewportWidth < 600) return 72;
  if (viewportWidth < 900) return 76;
  return 80;
}

/// Minimum card width for the guardian full pets list grid (slightly wider than dashboard rail).
double petCarePetsListCardMinWidth(double viewportWidth) {
  if (viewportWidth < 600) return 156;
  if (viewportWidth < 900) return 180;
  return 200;
}

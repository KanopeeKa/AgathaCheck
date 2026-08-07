import 'package:flutter/material.dart';

import '../../../../core/theme/experience_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Visual states for the foster badge pill on [OrgPersonTile].
enum OrgFosterBadgeState {
  underReview,
  approved,
  needsAttention,
  external;

  static OrgFosterBadgeState? resolve({
    required bool isExternal,
    String? fosterApprovalState,
    bool fosterNeedsAttention = false,
    int activeFosterCount = 0,
  }) {
    if (isExternal) return OrgFosterBadgeState.external;
    final hasRelationship =
        fosterApprovalState != null ||
        activeFosterCount > 0 ||
        fosterNeedsAttention;
    if (!hasRelationship) return null;
    if (fosterNeedsAttention) return OrgFosterBadgeState.needsAttention;
    switch (fosterApprovalState) {
      case 'under_review':
        return OrgFosterBadgeState.underReview;
      case 'approved':
        return OrgFosterBadgeState.approved;
      case 'declined':
      case 'archived':
        return OrgFosterBadgeState.needsAttention;
      default:
        if (activeFosterCount > 0) return OrgFosterBadgeState.approved;
        return fosterApprovalState != null
            ? OrgFosterBadgeState.underReview
            : null;
    }
  }
}

String localizedOrgFosterBadgeLabel(
  AppLocalizations l,
  OrgFosterBadgeState state,
) {
  switch (state) {
    case OrgFosterBadgeState.underReview:
      return l.orgFosterBadgeUnderReview;
    case OrgFosterBadgeState.approved:
      return l.orgFosterBadgeApproved;
    case OrgFosterBadgeState.needsAttention:
      return l.orgFosterBadgeNeedsAttention;
    case OrgFosterBadgeState.external:
      return l.orgFosterBadgeExternal;
  }
}

/// Foster status pill below the person name (D-v4-FOSTER-1).
class OrgFosterBadge extends StatelessWidget {
  const OrgFosterBadge({super.key, required this.state, this.semanticsLabel});

  final OrgFosterBadgeState state;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final xp = context.experienceColors;
    final l = AppLocalizations.of(context)!;
    final label = semanticsLabel ?? localizedOrgFosterBadgeLabel(l, state);

    final BoxDecoration decoration;
    final Color textColor;
    final Widget? leading;

    switch (state) {
      case OrgFosterBadgeState.underReview:
      case OrgFosterBadgeState.external:
        decoration = BoxDecoration(
          color: xp.organizationLight,
          borderRadius: BorderRadius.circular(4),
        );
        textColor = xp.organizationPrimary;
        leading = null;
        break;
      case OrgFosterBadgeState.approved:
        decoration = BoxDecoration(
          color: xp.organizationPrimary,
          borderRadius: BorderRadius.circular(4),
        );
        textColor = Colors.white;
        leading = const Icon(Icons.pets, size: 12, color: Colors.white);
        break;
      case OrgFosterBadgeState.needsAttention:
        decoration = BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: xp.danger, width: 2),
        );
        textColor = colorScheme.onSurface;
        leading = null;
        break;
    }

    return Semantics(
      label: label,
      child: Container(
        key: Key('org_foster_badge_${state.name}'),
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: decoration,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 4)],
            Flexible(
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

OrgFosterBadgeState? fosterBadgeStateForPerson({
  required bool isExternal,
  String? fosterApprovalState,
  bool fosterNeedsAttention = false,
  int activeFosterCount = 0,
}) {
  return OrgFosterBadgeState.resolve(
    isExternal: isExternal,
    fosterApprovalState: fosterApprovalState,
    fosterNeedsAttention: fosterNeedsAttention,
    activeFosterCount: activeFosterCount,
  );
}

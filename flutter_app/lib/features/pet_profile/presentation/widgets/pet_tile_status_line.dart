import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../organization/presentation/utils/foster_placement_display.dart';
import '../../../organization/presentation/utils/org_pets_care_utils.dart';
import '../../../organization/presentation/widgets/org_pets/org_pets_filter_row.dart';
import '../../domain/entities/pet.dart';

/// Which status rules apply when resolving line 2 on a [UnifiedPetTile].
enum PetTileContext { petCare, shelter }

/// Care urgency for Pet Care surfaces (maps from dashboard care state at call site).
enum PetTileCareUrgency { overdue, dueToday, upcoming, clear }

/// Resolved second-line presentation for a unified pet tile.
class PetTileStatusLineData {
  const PetTileStatusLineData({
    required this.label,
    this.icon,
    this.color,
    this.showCareStyling = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;

  /// When true, line 2 uses icon + semantic colour (Pet Care urgency).
  final bool showCareStyling;
}

PetTileStatusLineData resolvePetTileStatusLine({
  required AppLocalizations l,
  required Pet pet,
  required PetTileContext context,
  PetTileCareUrgency? careUrgency,
  OrgPetAttentionReason? attentionReason,
}) {
  if (pet.passedAway) {
    return PetTileStatusLineData(label: l.passedAway);
  }

  return switch (context) {
    PetTileContext.petCare => _resolvePetCareLine(
      l,
      careUrgency ?? PetTileCareUrgency.clear,
    ),
    PetTileContext.shelter => _resolveShelterLine(
      l,
      pet,
      attentionReason: attentionReason,
    ),
  };
}

PetTileStatusLineData _resolvePetCareLine(
  AppLocalizations l,
  PetTileCareUrgency urgency,
) {
  final label = switch (urgency) {
    PetTileCareUrgency.overdue => l.overdue,
    PetTileCareUrgency.dueToday => l.urgencyDueToday,
    PetTileCareUrgency.upcoming => l.careStatusUpcoming,
    PetTileCareUrgency.clear => l.careStatusAllClear,
  };
  final color = switch (urgency) {
    PetTileCareUrgency.overdue => AppColorTokens.danger,
    PetTileCareUrgency.dueToday => AppColorTokens.petCarePrimary,
    PetTileCareUrgency.upcoming => AppColorTokens.organizationActive,
    PetTileCareUrgency.clear => AppColorTokens.success,
  };
  final icon = switch (urgency) {
    PetTileCareUrgency.overdue => Icons.priority_high_rounded,
    PetTileCareUrgency.dueToday => Icons.schedule_outlined,
    PetTileCareUrgency.upcoming => Icons.event_outlined,
    PetTileCareUrgency.clear => Icons.check_circle_outline,
  };
  return PetTileStatusLineData(
    label: label,
    icon: icon,
    color: color,
    showCareStyling: true,
  );
}

PetTileStatusLineData _resolveShelterLine(
  AppLocalizations l,
  Pet pet, {
  OrgPetAttentionReason? attentionReason,
}) {
  final fosterLine = petFosterPlacementCardLine(l, pet);
  if (fosterLine != null && fosterLine.isNotEmpty) {
    return PetTileStatusLineData(label: fosterLine);
  }
  if (attentionReason != null) {
    return PetTileStatusLineData(
      label: localizedAttentionReason(l, attentionReason),
      color: AppColorTokens.danger,
    );
  }
  return const PetTileStatusLineData(label: '');
}

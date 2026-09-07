import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/care_status.dart';
import '../../domain/entities/pet.dart';

/// Which status rules apply when resolving line 2 on a [UnifiedPetTile].
enum PetTileContext { petCare, shelter }

/// Shelter attention reasons retained for API compatibility in frozen layouts.
enum PetTileAttentionReason { overdueVaccination, missingChip, other }

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

  /// When true, line 2 uses icon + semantic colour (Pet Care status).
  final bool showCareStyling;
}

PetTileStatusLineData resolvePetTileStatusLine({
  required AppLocalizations l,
  required Pet pet,
  required PetTileContext context,
  CareStatus? careStatus,
  PetTileAttentionReason? attentionReason,
}) {
  if (pet.passedAway) {
    return PetTileStatusLineData(label: l.passedAway);
  }

  return switch (context) {
    PetTileContext.petCare => _resolvePetCareLine(
      l,
      careStatus ?? CareStatus.allSet,
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
  CareStatus status,
) {
  final label = switch (status) {
    CareStatus.allSet => l.careStatusAllSet,
    CareStatus.worthACheck => l.careStatusWorthACheck,
    CareStatus.timeToFollowUp => l.careStatusTimeToFollowUp,
  };
  final color = switch (status) {
    CareStatus.allSet => AppColorTokens.success,
    CareStatus.worthACheck => AppColorTokens.info,
    CareStatus.timeToFollowUp => AppColorTokens.petCarePrimary,
  };
  final icon = switch (status) {
    CareStatus.allSet => Icons.check_circle_outline,
    CareStatus.worthACheck => Icons.info_outline,
    CareStatus.timeToFollowUp => Icons.schedule_outlined,
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
  PetTileAttentionReason? attentionReason,
}) {
  if (pet.isFoster) {
    return PetTileStatusLineData(label: l.fosterPlacementInProgress);
  }
  if (attentionReason != null) {
    return PetTileStatusLineData(
      label: attentionReason.name,
      color: AppColorTokens.danger,
    );
  }
  return const PetTileStatusLineData(label: '');
}

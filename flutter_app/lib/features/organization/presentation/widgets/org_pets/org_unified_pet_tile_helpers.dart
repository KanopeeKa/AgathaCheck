import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_tile_status_line.dart';
import '../../../domain/entities/foster_placement.dart';
import '../../models/org_pet_list_entry.dart';
import '../../utils/foster_placement_display.dart';
import '../../utils/org_pets_care_utils.dart';

/// Resolves line 2 for shelter org surfaces: foster placement/session first,
/// then optional [OrgPetAttentionReason] when [includeAttentionReason] is true.
PetTileStatusLineData resolveOrgPetTileStatusLine({
  required AppLocalizations l,
  required Pet pet,
  FosterPlacement? activePlacement,
  OrgPetAttentionReason? attentionReason,
  bool includeAttentionReason = false,
}) {
  if (pet.passedAway) {
    return resolvePetTileStatusLine(
      l: l,
      pet: pet,
      context: PetTileContext.shelter,
    );
  }

  if (activePlacement != null &&
      (activePlacement.isActive || activePlacement.isSessionOpen)) {
    final fosterLine = fosterPlacementSummary(
      l,
      status: activePlacement.isNotInFoster ? null : activePlacement.status,
      sessionStatus: activePlacement.isNotInFoster
          ? null
          : activePlacement.sessionStatus,
      fosterName: pet.fosterName,
    );
    if (fosterLine.isNotEmpty) {
      return PetTileStatusLineData(label: fosterLine);
    }
  }

  return resolvePetTileStatusLine(
    l: l,
    pet: pet,
    context: PetTileContext.shelter,
    attentionReason: includeAttentionReason ? attentionReason : null,
  );
}

FosterPlacement? activePlacementForEntry(
  OrgPetListEntry entry,
  List<FosterPlacement> placements,
) {
  if (!entry.isLive) return null;
  return activePlacementForPet(placements, entry.pet!.id);
}

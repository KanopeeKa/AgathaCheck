import '../../../pet_profile/domain/entities/pet.dart';
import '../../domain/entities/archived_pet.dart';
import '../../domain/entities/foster_placement.dart';
import '../../domain/entities/foster_session_status.dart';
import '../models/org_pet_list_entry.dart';

enum OrgPetsTab { needAttention, inFoster, adopted, all }

enum OrgPetAttentionReason { notInFoster, fosterFinishingSoon }

enum OrgPetsActiveFilter { name, fosteredBy, shadow, rainbowBridge }

class OrgPetsFilterState {
  const OrgPetsFilterState({
    this.nameQuery = '',
    this.fosteredByQuery = '',
    this.activeFilters = const {},
  });

  final String nameQuery;
  final String fosteredByQuery;
  final Set<OrgPetsActiveFilter> activeFilters;

  bool get showShadow => activeFilters.contains(OrgPetsActiveFilter.shadow);
  bool get showRainbowBridge =>
      activeFilters.contains(OrgPetsActiveFilter.rainbowBridge);
  bool get nameFilterEnabled =>
      activeFilters.contains(OrgPetsActiveFilter.name);
  bool get fosteredByFilterEnabled =>
      activeFilters.contains(OrgPetsActiveFilter.fosteredBy);

  OrgPetsFilterState copyWith({
    String? nameQuery,
    String? fosteredByQuery,
    Set<OrgPetsActiveFilter>? activeFilters,
  }) {
    return OrgPetsFilterState(
      nameQuery: nameQuery ?? this.nameQuery,
      fosteredByQuery: fosteredByQuery ?? this.fosteredByQuery,
      activeFilters: activeFilters ?? this.activeFilters,
    );
  }
}

const _needAttentionHorizonDays = 10;

FosterPlacement? activePlacementForPet(
  List<FosterPlacement> placements,
  String petId,
) {
  for (final placement in placements.where((p) => p.petId == petId)) {
    if (placement.isActive || placement.isSessionOpen) {
      return placement;
    }
  }
  return null;
}

bool hasPlannedFollowUp(
  List<FosterPlacement> placements,
  String petId,
  FosterPlacement current,
) {
  if (current.isAdoptionInProgress || current.isSessionAdoptionInProgress) {
    return true;
  }

  for (final placement in placements.where((p) => p.petId == petId)) {
    if (placement.id == current.id) continue;
    if (placement.isSessionOpen || placement.isActive || placement.isPending) {
      return true;
    }
    if (placement.isSessionPendingAcceptance ||
        placement.isSessionPreparation ||
        placement.isSessionReadyToStart) {
      return true;
    }
  }
  return false;
}

bool petIsInFoster(Pet pet, List<FosterPlacement> placements) {
  if (pet.passedAway) return false;
  final active = activePlacementForPet(placements, pet.id);
  if (active == null) {
    return _legacyInFosterStatus(pet.fosterPlacementStatus);
  }
  return active.isInProgress ||
      active.isSessionActive ||
      active.isWaitingAdoption ||
      active.isPendingConditions ||
      active.isSessionAdoptionInProgress ||
      active.isSessionEndPending;
}

bool _legacyInFosterStatus(String? status) {
  if (status == null || status.isEmpty) return false;
  return status == 'in_progress' ||
      status == 'waiting_adoption_confirmation' ||
      status == 'pending_adoption_conditions' ||
      status == FosterSessionStatus.active ||
      status == FosterSessionStatus.endPendingConfirmation ||
      status == FosterSessionStatus.adoptionInProgress;
}

OrgPetAttentionReason? needAttentionReason(
  Pet pet,
  List<FosterPlacement> placements, {
  DateTime? fosterEndDate,
  DateTime? now,
}) {
  if (pet.passedAway) return null;

  final active = activePlacementForPet(placements, pet.id);
  final endDate = active?.endDate ?? fosterEndDate;

  if (active == null || active.isNotInFoster) {
    if (_legacyInFosterStatus(pet.fosterPlacementStatus)) {
      return null;
    }
    return OrgPetAttentionReason.notInFoster;
  }

  if (!petIsInFoster(pet, placements)) {
    return OrgPetAttentionReason.notInFoster;
  }

  if (endDate == null) return null;

  final today = now ?? DateTime.now();
  final daysUntilEnd = endDate.difference(
    DateTime(today.year, today.month, today.day),
  ).inDays;
  if (daysUntilEnd > _needAttentionHorizonDays || daysUntilEnd < 0) {
    return null;
  }

  if (hasPlannedFollowUp(placements, pet.id, active)) return null;

  return OrgPetAttentionReason.fosterFinishingSoon;
}

List<OrgPetListEntry> buildOrgPetEntries({
  required List<Pet> pets,
  required List<FosterPlacement> placements,
  required List<ArchivedPet> archivedPets,
  Map<String, DateTime?> fosterEndDates = const {},
}) {
  final live = pets.map((pet) {
    return OrgPetListEntry.live(
      pet: pet,
      fosterEndDate: fosterEndDates[pet.id],
      attentionReason: needAttentionReason(
        pet,
        placements,
        fosterEndDate: fosterEndDates[pet.id],
      ),
    );
  }).toList();

  final archived = archivedPets
      .map((archivedPet) => OrgPetListEntry.archived(archivedPet: archivedPet))
      .toList();

  return [...live, ...archived];
}

List<OrgPetListEntry> filterOrgPetEntries({
  required List<OrgPetListEntry> entries,
  required OrgPetsTab tab,
  required OrgPetsFilterState filters,
  required List<FosterPlacement> placements,
}) {
  Iterable<OrgPetListEntry> rows = entries;

  rows = switch (tab) {
    OrgPetsTab.needAttention => rows.where(
      (entry) => entry.isLive && entry.attentionReason != null,
    ),
    OrgPetsTab.inFoster => rows.where(
      (entry) => entry.isLive && petIsInFoster(entry.pet!, placements),
    ),
    OrgPetsTab.adopted => rows.where(
      (entry) => entry.isArchived && entry.isAdoptedArchive,
    ),
    OrgPetsTab.all => rows.where((entry) {
      if (entry.isLive) {
        if (entry.passedAway && !filters.showRainbowBridge) return false;
        return true;
      }
      return filters.showShadow && entry.isShadow;
    }),
  };

  if (filters.nameFilterEnabled && filters.nameQuery.trim().isNotEmpty) {
    final query = filters.nameQuery.trim().toLowerCase();
    rows = rows.where((entry) => entry.name.toLowerCase().contains(query));
  }

  if (filters.fosteredByFilterEnabled &&
      filters.fosteredByQuery.trim().isNotEmpty) {
    final query = filters.fosteredByQuery.trim().toLowerCase();
    rows = rows.where((entry) {
      final fosterName = entry.fosterName;
      return fosterName != null && fosterName.toLowerCase().contains(query);
    });
  }

  if (filters.showShadow && tab != OrgPetsTab.adopted) {
    final shadowRows = entries.where(
      (entry) => entry.isArchived && entry.isShadow,
    );
    rows = {...rows, ...shadowRows};
  }

  if (filters.showRainbowBridge && tab != OrgPetsTab.needAttention) {
    final passedRows = entries.where(
      (entry) => entry.isLive && entry.passedAway,
    );
    rows = {...rows, ...passedRows};
  }

  return rows.toList();
}

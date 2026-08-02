import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/presentation/models/org_pet_list_entry.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

Pet _pet({
  required String id,
  required String name,
  bool passedAway = false,
  String? fosterName,
  String? fosterPlacementStatus,
}) {
  return Pet(
    id: id,
    name: name,
    species: 'Dog',
    passedAway: passedAway,
    fosterName: fosterName,
    fosterPlacementStatus: fosterPlacementStatus,
  );
}

FosterPlacement _placement({
  required String id,
  required String petId,
  String status = 'in_progress',
  String sessionStatus = 'active',
  DateTime? endDate,
}) {
  return FosterPlacement(
    id: id,
    organizationId: 'org-1',
    petId: petId,
    fosterUserId: 'foster-1',
    status: status,
    sessionStatus: sessionStatus,
    endDate: endDate,
    fosterName: 'Eve Foster',
  );
}

OrgPetListEntry _live(
  Pet pet, {
  OrgPetAttentionReason? attention,
}) {
  return OrgPetListEntry.live(pet: pet, attentionReason: attention);
}

OrgPetListEntry _archived({
  required String id,
  required String name,
  String transferType = 'adoption',
  bool shadow = false,
}) {
  return OrgPetListEntry.archived(
    archivedPet: ArchivedPet(
      id: id,
      petId: 'pet-$id',
      petName: name,
      transferType: transferType,
      shadowSnapshot: shadow ? {'name': name} : null,
    ),
  );
}

void main() {
  final max = _pet(id: 'pet-max', name: 'Max');
  final bella = _pet(
    id: 'pet-bella',
    name: 'Bella',
    fosterName: 'Eve Foster',
    fosterPlacementStatus: 'in_progress',
  );
  final passed = _pet(id: 'pet-rainbow', name: 'Rainbow', passedAway: true);
  final shadowArchive = _archived(
    id: 'arch-shadow',
    name: 'Shadow',
    transferType: 'transfer',
    shadow: true,
  );
  final adoptedArchive = _archived(id: 'arch-adopted', name: 'Adopted');
  final nonShadowArchive = _archived(
    id: 'arch-plain',
    name: 'Plain',
    transferType: 'transfer',
    shadow: false,
  );

  final bellaPlacement = _placement(
    id: 'pl-bella',
    petId: 'pet-bella',
    endDate: DateTime(2026, 8, 30),
  );
  final placements = [bellaPlacement];

  final allEntries = [
    _live(max, attention: OrgPetAttentionReason.notInFoster),
    _live(bella),
    _live(passed),
    shadowArchive,
    adoptedArchive,
    nonShadowArchive,
  ];

  final cases = <({
    String label,
    OrgPetsTab tab,
    OrgPetsFilterState filters,
    List<String> expectedNames,
  })>[
    (
      label: 'needAttention tab keeps only attention pets',
      tab: OrgPetsTab.needAttention,
      filters: const OrgPetsFilterState(),
      expectedNames: ['Max'],
    ),
    (
      label: 'inFoster tab keeps pets in active foster',
      tab: OrgPetsTab.inFoster,
      filters: const OrgPetsFilterState(),
      expectedNames: ['Bella'],
    ),
    (
      label: 'adopted tab keeps adopted archives only',
      tab: OrgPetsTab.adopted,
      filters: const OrgPetsFilterState(),
      expectedNames: ['Adopted'],
    ),
    (
      label: 'all tab excludes passed-away without rainbow bridge',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(),
      expectedNames: ['Max', 'Bella'],
    ),
    (
      label: 'all tab with shadow chip includes shadow archives',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.shadow},
      ),
      expectedNames: ['Max', 'Bella', 'Shadow'],
    ),
    (
      label: 'all tab with rainbow bridge includes passed-away pets',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.rainbowBridge},
      ),
      expectedNames: ['Max', 'Bella', 'Rainbow'],
    ),
    (
      label: 'name filter narrows all tab',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.name},
        nameQuery: 'bel',
      ),
      expectedNames: ['Bella'],
    ),
    (
      label: 'fostered-by filter narrows inFoster tab',
      tab: OrgPetsTab.inFoster,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.fosteredBy},
        fosteredByQuery: 'eve',
      ),
      expectedNames: ['Bella'],
    ),
    (
      label: 'empty name query does not exclude rows',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.name},
        nameQuery: '   ',
      ),
      expectedNames: ['Max', 'Bella'],
    ),
    (
      label: 'shadow union adds shadow rows on needAttention tab',
      tab: OrgPetsTab.needAttention,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.shadow},
      ),
      expectedNames: ['Max', 'Shadow'],
    ),
    (
      label: 'rainbow bridge union on inFoster tab',
      tab: OrgPetsTab.inFoster,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.rainbowBridge},
      ),
      expectedNames: ['Bella', 'Rainbow'],
    ),
    (
      label: 'combined name and fostered-by filters use AND',
      tab: OrgPetsTab.inFoster,
      filters: const OrgPetsFilterState(
        activeFilters: {
          OrgPetsActiveFilter.name,
          OrgPetsActiveFilter.fosteredBy,
        },
        nameQuery: 'bella',
        fosteredByQuery: 'eve',
      ),
      expectedNames: ['Bella'],
    ),
    (
      label: 'passed-away pets excluded from needAttention',
      tab: OrgPetsTab.needAttention,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.rainbowBridge},
      ),
      expectedNames: ['Max'],
    ),
    (
      label: 'non-shadow archive hidden on all without shadow chip',
      tab: OrgPetsTab.all,
      filters: const OrgPetsFilterState(),
      expectedNames: ['Max', 'Bella'],
    ),
    (
      label: 'adopted tab ignores shadow union',
      tab: OrgPetsTab.adopted,
      filters: const OrgPetsFilterState(
        activeFilters: {OrgPetsActiveFilter.shadow},
      ),
      expectedNames: ['Adopted'],
    ),
  ];

  for (final testCase in cases) {
    test(testCase.label, () {
      final filtered = filterOrgPetEntries(
        entries: allEntries,
        tab: testCase.tab,
        filters: testCase.filters,
        placements: placements,
      );
      expect(filtered.map((e) => e.name).toList(), testCase.expectedNames);
    });
  }
}

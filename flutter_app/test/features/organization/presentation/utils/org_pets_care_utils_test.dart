import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

Pet _pet({
  required String id,
  required String name,
  bool passedAway = false,
  String? fosterPlacementStatus,
}) {
  return Pet(
    id: id,
    name: name,
    species: 'Dog',
    passedAway: passedAway,
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

void main() {
  group('needAttentionReason', () {
    test('returns notInFoster when pet has no placement', () {
      expect(
        needAttentionReason(_pet(id: 'pet-1', name: 'Max'), const []),
        OrgPetAttentionReason.notInFoster,
      );
    });

    test('returns fosterFinishingSoon when placement ends within 10 days', () {
      final now = DateTime(2026, 7, 26);
      final pet = _pet(id: 'pet-2', name: 'Bella');
      final placements = [
        _placement(
          id: 'pl-1',
          petId: 'pet-2',
          endDate: now.add(const Duration(days: 5)),
        ),
      ];

      expect(
        needAttentionReason(pet, placements, now: now),
        OrgPetAttentionReason.fosterFinishingSoon,
      );
    });

    test('returns null when adoption is in progress on current placement', () {
      final now = DateTime(2026, 7, 26);
      final pet = _pet(id: 'pet-3', name: 'Luna');
      final placements = [
        _placement(
          id: 'pl-1',
          petId: 'pet-3',
          status: 'waiting_adoption_confirmation',
          sessionStatus: 'adoption_in_progress',
          endDate: now.add(const Duration(days: 3)),
        ),
      ];

      expect(needAttentionReason(pet, placements, now: now), isNull);
    });
  });

  group('filterOrgPetEntries', () {
    test('Need attention tab includes only attention pets', () {
      final max = _pet(id: 'pet-1', name: 'Max');
      final bella = _pet(
        id: 'pet-2',
        name: 'Bella',
        fosterPlacementStatus: 'in_progress',
      );
      final entries = buildOrgPetEntries(
        pets: [max, bella],
        placements: [
          _placement(
            id: 'pl-1',
            petId: 'pet-2',
            endDate: DateTime(2026, 8, 30),
          ),
        ],
        archivedPets: const [],
      );

      final filtered = filterOrgPetEntries(
        entries: entries,
        tab: OrgPetsTab.needAttention,
        filters: const OrgPetsFilterState(),
        placements: [
          _placement(
            id: 'pl-1',
            petId: 'pet-2',
            endDate: DateTime(2026, 8, 30),
          ),
        ],
      );

      expect(filtered.map((e) => e.name), ['Max']);
    });
  });
}

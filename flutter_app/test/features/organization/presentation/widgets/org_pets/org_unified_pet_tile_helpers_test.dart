import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_session_status.dart';
import 'package:pet_profile_app/features/organization/presentation/models/org_pet_list_entry.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/features/organization/presentation/widgets/org_pets/org_unified_pet_tile_helpers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('prefers foster session line over attention reason', () {
    const pet = Pet(
      id: 'pet-1',
      name: 'Luna',
      species: 'Dog',
      organizationId: 'org-1',
      fosterName: 'Alex',
    );
    const placement = FosterPlacement(
      id: 'fp-1',
      organizationId: 'org-1',
      petId: 'pet-1',
      fosterUserId: 'user-1',
      status: 'in_progress',
      sessionStatus: FosterSessionStatus.active,
      fosterName: 'Alex',
      fosterEmail: 'alex@example.com',
    );

    final status = resolveOrgPetTileStatusLine(
      l: l,
      pet: pet,
      activePlacement: placement,
      attentionReason: OrgPetAttentionReason.notInFoster,
      includeAttentionReason: true,
    );

    expect(status.label, contains(l.fosteringSessionStatusActive));
    expect(status.label, contains('Alex'));
  });

  test('shows attention reason when no foster line and flag is on', () {
    const pet = Pet(id: 'pet-1', name: 'Max', species: 'Dog');

    final status = resolveOrgPetTileStatusLine(
      l: l,
      pet: pet,
      attentionReason: OrgPetAttentionReason.notInFoster,
      includeAttentionReason: true,
    );

    expect(status.label, l.orgPetsNeedAttentionNotInFoster);
  });

  test('hides attention reason when includeAttentionReason is false', () {
    const pet = Pet(id: 'pet-1', name: 'Max', species: 'Dog');

    final status = resolveOrgPetTileStatusLine(
      l: l,
      pet: pet,
      attentionReason: OrgPetAttentionReason.notInFoster,
      includeAttentionReason: false,
    );

    expect(status.label, isEmpty);
  });

  test('activePlacementForEntry returns placement for live pet', () {
    const entry = OrgPetListEntry.live(
      pet: Pet(id: 'pet-1', name: 'Max', species: 'Dog'),
    );
    const placements = <FosterPlacement>[
      FosterPlacement(
        id: 'fp-1',
        organizationId: 'org-1',
        petId: 'pet-1',
        fosterUserId: 'user-1',
        status: 'in_progress',
        sessionStatus: FosterSessionStatus.active,
        fosterName: 'Alex',
        fosterEmail: 'alex@example.com',
      ),
    ];

    final placement = activePlacementForEntry(entry, placements);

    expect(placement, isNotNull);
    expect(placement!.petId, 'pet-1');
  });
}

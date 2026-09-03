import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_pets_care_utils.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_tile_status_line.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('pet care line uses icon styling for overdue', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(id: '1', name: 'Miso', species: 'Cat'),
      context: PetTileContext.petCare,
      careUrgency: PetTileCareUrgency.overdue,
    );

    expect(data.label, l.overdue);
    expect(data.showCareStyling, isTrue);
    expect(data.icon, isNotNull);
    expect(data.color, isNotNull);
  });

  test('pet care clear line uses all clear label', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(id: '1', name: 'Miso', species: 'Cat'),
      context: PetTileContext.petCare,
      careUrgency: PetTileCareUrgency.clear,
    );

    expect(data.label, l.careStatusAllClear);
  });

  test('shelter line prefers foster placement summary', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(
        id: '1',
        name: 'Luna',
        species: 'Dog',
        organizationId: 'org-1',
        fosterPlacementStatus: 'in_progress',
        fosterName: 'Alex',
      ),
      context: PetTileContext.shelter,
      attentionReason: OrgPetAttentionReason.notInFoster,
    );

    expect(data.label, contains(l.fosterPlacementInProgress));
    expect(data.showCareStyling, isFalse);
  });

  test('shelter line falls back to attention reason', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(
        id: '1',
        name: 'Luna',
        species: 'Dog',
      ),
      context: PetTileContext.shelter,
      attentionReason: OrgPetAttentionReason.fosterFinishingSoon,
    );

    expect(data.label, l.orgPetsNeedAttentionFosterFinishingSoon);
  });

  test('passed away suppresses care urgency', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(
        id: '1',
        name: 'Old friend',
        species: 'Cat',
        passedAway: true,
      ),
      context: PetTileContext.petCare,
      careUrgency: PetTileCareUrgency.overdue,
    );

    expect(data.label, l.passedAway);
    expect(data.showCareStyling, isFalse);
  });
}

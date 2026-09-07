import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_status.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/pet_tile_status_line.dart';

void main() {
  late AppLocalizations l;

  setUpAll(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  test('time to follow up uses plum styling', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(id: '1', name: 'Miso', species: 'Cat'),
      context: PetTileContext.petCare,
      careStatus: CareStatus.timeToFollowUp,
    );

    expect(data.label, l.careStatusTimeToFollowUp);
    expect(data.showCareStyling, isTrue);
    expect(data.icon, isNotNull);
    expect(data.color, isNotNull);
  });

  test('all set line uses All Set label', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(id: '1', name: 'Miso', species: 'Cat'),
      context: PetTileContext.petCare,
      careStatus: CareStatus.allSet,
    );

    expect(data.label, l.careStatusAllSet);
  });

  test('passed away suppresses care status', () {
    final data = resolvePetTileStatusLine(
      l: l,
      pet: const Pet(
        id: '1',
        name: 'Old friend',
        species: 'Cat',
        passedAway: true,
      ),
      context: PetTileContext.petCare,
      careStatus: CareStatus.timeToFollowUp,
    );

    expect(data.label, l.passedAway);
  });
}

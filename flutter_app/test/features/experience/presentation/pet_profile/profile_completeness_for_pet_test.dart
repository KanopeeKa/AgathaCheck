import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/profile_completeness_kind.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/profile_completeness_for_pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';

void main() {
  test('lists neuter and chip when unknown', () {
    const pet = Pet(
      id: 'p',
      name: 'N',
      species: 'Dog',
      neuterStatus: profileFactStatusUnknown,
      identificationStatus: profileFactStatusUnknown,
    );
    expect(profileCompletenessKindsForPet(pet), [
      ProfileCompletenessKind.neuter,
      ProfileCompletenessKind.chip,
    ]);
  });
}

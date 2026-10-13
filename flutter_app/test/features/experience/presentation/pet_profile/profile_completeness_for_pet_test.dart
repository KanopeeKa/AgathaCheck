import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/profile_completeness_kind.dart';
import 'package:pet_profile_app/features/care_intelligence/presentation/agatha_surface_policy.dart';
import 'package:pet_profile_app/features/experience/presentation/pet_profile/profile_completeness_for_pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';

void main() {
  const policy = AgathaSurfacePolicy();
  final now = DateTime.utc(2026, 10, 1);

  test('lists chip only when identification unknown (neuter via welfare PR-08)', () {
    const pet = Pet(
      id: 'p',
      name: 'N',
      species: 'Dog',
      neuterStatus: profileFactStatusUnknown,
      identificationStatus: profileFactStatusUnknown,
    );
    expect(profileCompletenessKindsForPet(pet, policy: policy, now: now), [
      ProfileCompletenessKind.chip,
    ]);
  });

  test('hides chip when dismissed inside 30d cooldown', () {
    const pet = Pet(
      id: 'p',
      name: 'N',
      species: 'Dog',
      identificationStatus: profileFactStatusUnknown,
      chipDismissed: true,
    );
    final dismissedAt = DateTime.utc(2026, 9, 20);
    expect(
      profileCompletenessKindsForPet(
        pet,
        policy: policy,
        now: now,
        chipDismissedAt: dismissedAt,
      ),
      isEmpty,
    );
  });
}

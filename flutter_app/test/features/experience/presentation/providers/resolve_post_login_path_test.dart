import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

ExperienceEligibility _dual() => ExperienceEligibilityRules.compute(
  pets: const [
    Pet(id: '1', name: 'Mine', species: 'Cat'),
    Pet(
      id: '2',
      name: 'Shelter',
      species: 'Dog',
      organizationId: 'o1',
      organizationName: 'Rescue',
    ),
  ],
  orgMembershipCount: 1,
);

ExperienceEligibility _guardianOnly() =>
    ExperienceEligibilityRules.compute(pets: const [], orgMembershipCount: 0);

ExperienceEligibility _orgOnly() => ExperienceEligibilityRules.compute(
  pets: const [
    Pet(
      id: '2',
      name: 'Shelter',
      species: 'Dog',
      organizationId: 'o1',
      organizationName: 'Rescue',
    ),
  ],
  orgMembershipCount: 1,
);

void main() {
  group('resolvePostLoginPath', () {
    test('guardian-only user lands on guardian home', () {
      expect(resolvePostLoginPath(eligibility: _guardianOnly()), '/g/home');
    });

    test('org-only user lands on organisation home', () {
      expect(resolvePostLoginPath(eligibility: _orgOnly()), '/o/home');
    });

    test('dual-role user without saved default goes to chooser', () {
      expect(resolvePostLoginPath(eligibility: _dual()), '/app/choose');
    });

    test('dual-role user with saved guardian default skips chooser', () {
      expect(
        resolvePostLoginPath(
          eligibility: _dual(),
          savedDefault: AppExperience.guardian,
        ),
        '/g/home',
      );
    });

    test('invalid saved default for org-only falls through to org home', () {
      expect(
        resolvePostLoginPath(
          eligibility: _orgOnly(),
          savedDefault: AppExperience.guardian,
        ),
        '/o/home',
      );
    });

    test('active experience override wins when allowed', () {
      expect(
        resolvePostLoginPath(
          eligibility: _dual(),
          activeExperience: AppExperience.organization,
        ),
        '/o/home',
      );
    });

    test('invalid active experience is ignored', () {
      expect(
        resolvePostLoginPath(
          eligibility: _orgOnly(),
          activeExperience: AppExperience.guardian,
        ),
        '/o/home',
      );
    });
  });
}

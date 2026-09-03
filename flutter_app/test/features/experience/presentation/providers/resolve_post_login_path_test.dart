import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/experience/presentation/providers/experience_providers.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
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
    test('guardian user with pets lands on /pc/home when onboarding done', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [Pet(id: '1', name: 'Mine', species: 'Cat')],
          guardianOnboardingCompleted: true,
        ),
        '/pc/home',
      );
    });

    test('empty account lands on /pc/home when guardian onboarding done', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [],
          guardianOnboardingCompleted: true,
        ),
        '/pc/home',
      );
    });

    test('empty account goes to guardian onboarding when not completed', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [],
          guardianOnboardingCompleted: false,
        ),
        '/pc/onboarding',
      );
    });

    test('org-only user lands on /pc/home when guardian onboarding done', () {
      expect(
        resolvePostLoginPath(
          eligibility: _orgOnly(),
          pets: const [],
          orgs: const [
            Organization(
              id: 'o1',
              name: 'Rescue',
              type: OrganizationType.charity,
            ),
          ],
          guardianOnboardingCompleted: true,
          orgOnboardingCompleted: true,
        ),
        '/pc/home',
      );
    });

    test('dual-role user always lands on /pc/home when onboarding done', () {
      expect(
        resolvePostLoginPath(
          eligibility: _dual(),
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
          orgs: const [
            Organization(
              id: 'o1',
              name: 'Rescue',
              type: OrganizationType.charity,
            ),
          ],
          guardianOnboardingCompleted: true,
        ),
        '/pc/home',
      );
    });

    test('does not restore last organisation section', () {
      expect(
        resolvePostLoginPath(
          eligibility: _dual(),
          pets: const [Pet(id: '1', name: 'Mine', species: 'Cat')],
          orgs: const [
            Organization(
              id: 'o1',
              name: 'Rescue',
              type: OrganizationType.charity,
            ),
          ],
          guardianOnboardingCompleted: true,
        ),
        '/pc/home',
      );
    });
  });
}

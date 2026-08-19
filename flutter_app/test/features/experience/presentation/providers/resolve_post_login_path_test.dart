import 'package:flutter_test/flutter_test.dart';
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
    test('guardian-only user lands on guardian home when onboarding done', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [Pet(id: '1', name: 'Mine', species: 'Cat')],
          guardianOnboardingCompleted: true,
        ),
        '/g/home',
      );
    });

    test('guardian-only user with no pets goes to FTUE', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [],
          guardianOnboardingCompleted: false,
        ),
        '/app/choose',
      );
    });

    test('guardian-only user with no pets and pending invites skips FTUE', () {
      expect(
        resolvePostLoginPath(
          eligibility: _guardianOnly(),
          pets: const [],
          guardianOnboardingCompleted: false,
          hasPendingOrgInvites: true,
        ),
        '/g/onboarding',
      );
    });

    test('org-only user with no pets lands on shelter home', () {
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
          orgOnboardingCompleted: true,
        ),
        '/o/home',
      );
    });

    test(
      'dual-role user with owned pets goes to guardian home not onboarding',
      () {
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
            guardianOnboardingCompleted: false,
          ),
          '/g/home',
        );
      },
    );

    test('org-only user with inventory pet lands on organisation home', () {
      expect(
        resolvePostLoginPath(
          eligibility: _orgOnly(),
          pets: const [
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
          orgOnboardingCompleted: true,
        ),
        '/o/home',
      );
    });

    test('org-only user with no inventory pets goes to onboarding', () {
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
          orgOnboardingCompleted: false,
        ),
        '/o/onboarding',
      );
    });

    test('org-only user lands on organisation home', () {
      expect(
        resolvePostLoginPath(
          eligibility: _orgOnly(),
          pets: const [
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
        ),
        '/o/home',
      );
    });

    test('dual-role user falls back to guardian when pets exist', () {
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
        ),
        '/g/home',
      );
    });

    test('guardian-only empty account goes to FTUE', () {
      expect(resolvePostLoginPath(eligibility: _guardianOnly()), '/app/choose');
    });
  });
}

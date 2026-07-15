import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/experience/domain/services/experience_eligibility.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

Pet _pet({
  String? organizationId,
  String? organizationName,
  bool isShared = false,
  bool isFoster = false,
}) {
  return Pet(
    id: 'p1',
    name: 'Max',
    species: 'Dog',
    organizationId: organizationId,
    organizationName: organizationName,
    isShared: isShared,
    isFoster: isFoster,
  );
}

void main() {
  group('ExperienceEligibilityRules', () {
    test('guardian-only user has guardian context without pets', () {
      final e = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 0,
      );
      expect(e.canUseGuardian, isTrue);
      expect(e.canUseOrganization, isFalse);
      expect(e.showChooser, isFalse);
      expect(e.resolveAutoExperience(), AppExperience.guardian);
    });

    test('org-only admin without guardian pets auto-opens org', () {
      final e = ExperienceEligibilityRules.compute(
        pets: [_pet(organizationId: 'o1', organizationName: 'Shelter')],
        orgMembershipCount: 1,
      );
      expect(e.canUseGuardian, isFalse);
      expect(e.canUseOrganization, isTrue);
      expect(e.showChooser, isFalse);
      expect(e.resolveAutoExperience(), AppExperience.organization);
    });

    test('dual user sees chooser unless default saved', () {
      final e = ExperienceEligibilityRules.compute(
        pets: [
          _pet(),
          _pet(organizationId: 'o1', organizationName: 'Shelter'),
        ],
        orgMembershipCount: 1,
      );
      expect(e.showChooser, isTrue);
      expect(e.resolveAutoExperience(), isNull);
      expect(
        e.resolveAutoExperience(savedDefault: AppExperience.guardian),
        AppExperience.guardian,
      );
    });

    test('foster pet counts as guardian context', () {
      final e = ExperienceEligibilityRules.compute(
        pets: [_pet(isFoster: true, organizationName: 'Shelter')],
        orgMembershipCount: 1,
      );
      expect(e.hasGuardianContext, isTrue);
      expect(e.showChooser, isTrue);
    });

    test('shared pet counts as guardian context', () {
      final e = ExperienceEligibilityRules.compute(
        pets: [_pet(isShared: true)],
        orgMembershipCount: 1,
      );
      expect(e.hasGuardianContext, isTrue);
    });
  });

  group('ExperienceEligibility negative paths', () {
    late ExperienceEligibility dual;
    late ExperienceEligibility guardianOnly;
    late ExperienceEligibility orgOnly;

    setUp(() {
      dual = ExperienceEligibilityRules.compute(
        pets: [
          _pet(),
          _pet(organizationId: 'o1', organizationName: 'Shelter'),
        ],
        orgMembershipCount: 1,
      );
      guardianOnly = ExperienceEligibilityRules.compute(
        pets: const [],
        orgMembershipCount: 0,
      );
      orgOnly = ExperienceEligibilityRules.compute(
        pets: [_pet(organizationId: 'o1', organizationName: 'Shelter')],
        orgMembershipCount: 1,
      );
    });

    test('dual user availableExperiences lists guardian and organization', () {
      expect(dual.availableExperiences, [
        AppExperience.guardian,
        AppExperience.organization,
      ]);
    });

    test('guardian-only availableExperiences excludes organization', () {
      expect(guardianOnly.availableExperiences, [AppExperience.guardian]);
      expect(guardianOnly.canUseOrganization, isFalse);
    });

    test('org-only cannot use guardian shell', () {
      expect(orgOnly.canUseGuardian, isFalse);
      expect(orgOnly.canUseOrganization, isTrue);
      expect(orgOnly.showChooser, isFalse);
    });

    test('dual user without saved default returns null for chooser', () {
      expect(dual.resolveAutoExperience(), isNull);
    });

    test('org-only ignores guardian saved default', () {
      expect(
        orgOnly.resolveAutoExperience(savedDefault: AppExperience.guardian),
        AppExperience.organization,
      );
    });

    test('personal pet without org name still counts as guardian context', () {
      final e = ExperienceEligibilityRules.compute(
        pets: const [Pet(id: '1', name: 'A', species: 'Cat')],
        orgMembershipCount: 1,
      );
      expect(e.hasGuardianContext, isTrue);
      expect(e.showChooser, isTrue);
    });

    test('org inventory pet alone is not guardian context', () {
      expect(
        ExperienceEligibilityRules.hasGuardianContextFromPets([
          _pet(organizationId: 'o1', organizationName: 'Shelter'),
        ]),
        isFalse,
      );
    });
  });
}

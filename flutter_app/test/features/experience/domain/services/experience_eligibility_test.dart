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
}

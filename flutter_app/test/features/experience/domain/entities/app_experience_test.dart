import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';

void main() {
  group('AppExperienceWire', () {
    test('wire values round-trip for petCare', () {
      expect(AppExperience.petCare.wire, 'pet_care');
      expect(AppExperienceWire.fromWire('pet_care'), AppExperience.petCare);
    });

    test('fromWire maps legacy organization wire to pet care', () {
      expect(AppExperienceWire.fromWire('organization'), AppExperience.petCare);
    });

    test('fromWire dual-reads legacy guardian wire', () {
      expect(AppExperienceWire.fromWire('guardian'), AppExperience.petCare);
    });

    test('fromWire returns null for unknown or missing wire', () {
      expect(AppExperienceWire.fromWire('boarding'), isNull);
      expect(AppExperienceWire.fromWire(''), isNull);
      expect(AppExperienceWire.fromWire(null), isNull);
    });

    test('paths are Pet Care only even for deprecated organization enum', () {
      expect(AppExperience.petCare.homePath(), '/pc/home');
      expect(AppExperience.organization.homePath(), '/pc/home');
      expect(AppExperience.organization.homePath(orgId: 'org-abc'), '/pc/home');
      expect(AppExperience.petCare.eventsPath, '/pc/events');
      expect(AppExperience.organization.eventsPath, '/pc/events');
      expect(AppExperience.petCare.settingsPath, '/pc/settings');
      expect(AppExperience.organization.settingsPath, '/pc/settings');
    });
  });
}

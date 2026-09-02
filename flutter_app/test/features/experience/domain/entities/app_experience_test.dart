import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';

void main() {
  group('AppExperienceWire', () {
    test('wire values round-trip for petCare and organization', () {
      expect(AppExperience.petCare.wire, 'pet_care');
      expect(AppExperience.organization.wire, 'organization');
      expect(AppExperienceWire.fromWire('pet_care'), AppExperience.petCare);
      expect(
        AppExperienceWire.fromWire('organization'),
        AppExperience.organization,
      );
    });

    test('fromWire dual-reads legacy guardian wire', () {
      expect(AppExperienceWire.fromWire('guardian'), AppExperience.petCare);
    });

    test('fromWire returns null for unknown or missing wire', () {
      expect(AppExperienceWire.fromWire('boarding'), isNull);
      expect(AppExperienceWire.fromWire(''), isNull);
      expect(AppExperienceWire.fromWire(null), isNull);
    });

    test('homePath returns pet care and organization routes', () {
      expect(AppExperience.petCare.homePath(), '/pc/home');
      expect(AppExperience.organization.homePath(), '/o/home');
      expect(
        AppExperience.organization.homePath(orgId: 'org-abc'),
        '/o/org-abc',
      );
      expect(AppExperience.organization.homePath(orgId: ''), '/o/home');
    });

    test('eventsPath and settingsPath are namespaced per experience', () {
      expect(AppExperience.petCare.eventsPath, '/pc/events');
      expect(AppExperience.organization.eventsPath, '/o/events');
      expect(AppExperience.petCare.settingsPath, '/pc/settings');
      expect(AppExperience.organization.settingsPath, '/o/settings');
    });

    test('deprecated guardian alias points to petCare', () {
      expect(AppExperience.guardian, AppExperience.petCare);
    });
  });
}

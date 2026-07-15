import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';

void main() {
  group('AppExperienceWire', () {
    test('wire values round-trip for guardian and organization', () {
      expect(AppExperience.guardian.wire, 'guardian');
      expect(AppExperience.organization.wire, 'organization');
      expect(AppExperienceWire.fromWire('guardian'), AppExperience.guardian);
      expect(
        AppExperienceWire.fromWire('organization'),
        AppExperience.organization,
      );
    });

    test('fromWire returns null for unknown or missing wire', () {
      expect(AppExperienceWire.fromWire('boarding'), isNull);
      expect(AppExperienceWire.fromWire(''), isNull);
      expect(AppExperienceWire.fromWire(null), isNull);
    });

    test('homePath returns guardian and organization routes', () {
      expect(AppExperience.guardian.homePath(), '/g/home');
      expect(AppExperience.organization.homePath(), '/o/home');
      expect(
        AppExperience.organization.homePath(orgId: 'org-abc'),
        '/o/org-abc',
      );
      expect(AppExperience.organization.homePath(orgId: ''), '/o/home');
    });

    test('eventsPath and settingsPath are namespaced per experience', () {
      expect(AppExperience.guardian.eventsPath, '/g/events');
      expect(AppExperience.organization.eventsPath, '/o/events');
      expect(AppExperience.guardian.settingsPath, '/g/settings');
      expect(AppExperience.organization.settingsPath, '/o/settings');
    });
  });
}

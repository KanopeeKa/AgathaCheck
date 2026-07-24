import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/organization_routes.dart';

void main() {
  group('legacyOrganizationRedirectForPath', () {
    test('maps list path', () {
      expect(legacyOrganizationRedirectForPath('/organizations'), '/o/orgs');
    });

    test('maps nested paths and preserves query', () {
      expect(
        legacyOrganizationRedirectForPath(
          '/organizations/org-1/pets',
          query: 'tab=active',
        ),
        '/o/orgs/org-1/pets?tab=active',
      );
    });

    test('returns null for unrelated paths', () {
      expect(legacyOrganizationRedirectForPath('/o/orgs'), isNull);
    });
  });
}

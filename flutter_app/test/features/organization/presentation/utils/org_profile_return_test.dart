import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_profile_return.dart';

void main() {
  group('parseOrgProfileReturnTo', () {
    test('accepts encoded in-app paths', () {
      expect(
        parseOrgProfileReturnTo(Uri.encodeComponent('/g/home')),
        '/g/home',
      );
      expect(
        parseOrgProfileReturnTo('/g/fostering'),
        '/g/fostering',
      );
    });

    test('rejects unsafe values', () {
      expect(parseOrgProfileReturnTo(null), isNull);
      expect(parseOrgProfileReturnTo(''), isNull);
      expect(parseOrgProfileReturnTo('//evil.example'), isNull);
      expect(parseOrgProfileReturnTo('https://evil.example'), isNull);
    });
  });

  group('orgProfileFallbackReturnPath', () {
    test('defaults to shelters dashboard', () {
      expect(orgProfileFallbackReturnPath(), '/o/orgs');
    });

    test('uses provided return path', () {
      expect(
        orgProfileFallbackReturnPath(returnTo: '/g/home'),
        '/g/home',
      );
    });
  });
}

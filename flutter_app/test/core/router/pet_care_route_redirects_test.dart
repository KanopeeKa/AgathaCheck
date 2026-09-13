import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/pet_care_route_redirects.dart';

void main() {
  group('legacyPetAllCareRedirectForPath', () {
    test('redirects legacy recurring-care path to All care', () {
      expect(
        legacyPetAllCareRedirectForPath('/pet/pet-1/care-rhythms'),
        '/pet/pet-1/events',
      );
    });

    test('returns null for unrelated paths', () {
      expect(legacyPetAllCareRedirectForPath('/pet/pet-1/events'), isNull);
      expect(
        legacyPetAllCareRedirectForPath('/pet/pet-1/care-rhythms/extra'),
        isNull,
      );
    });
  });
}

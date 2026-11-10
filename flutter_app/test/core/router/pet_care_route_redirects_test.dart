import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/pet_care_route_redirects.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';

void main() {
  group('legacyPetAllCareRedirectForPath', () {
    test('redirects legacy recurring-care path to All care', () {
      expect(
        legacyPetAllCareRedirectForPath('/pet/pet-1/care-rhythms'),
        '/pc/events?pet=pet-1',
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

  test('redirectPetScopedAllCareTarget matches globalAllCareLocation', () {
    expect(
      redirectPetScopedAllCareTarget(
        petId: 'pet-1',
        uri: Uri.parse('/pet/pet-1/events'),
      ),
      globalAllCareLocation(petIds: {'pet-1'}),
    );
    expect(
      redirectPetScopedAllCareTarget(
        petId: 'pet-1',
        uri: Uri.parse(
          '/pet/pet-1/events?returnTo=${Uri.encodeComponent('/pet/pet-1')}',
        ),
      ),
      globalAllCareLocation(petIds: {'pet-1'}, returnTo: '/pet/pet-1'),
    );
  });
}

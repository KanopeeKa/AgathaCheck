import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/care_list/global_events_pet_query.dart';

void main() {
  group('globalAllCareLocation', () {
    test('includes pet query for deep link', () {
      expect(
        globalAllCareLocation(petIds: {'pet-b', 'pet-a'}),
        '/pc/events?pet=pet-a%2Cpet-b',
      );
    });

    test('encodes returnTo', () {
      expect(
        globalAllCareLocation(
          petIds: {'pet-1'},
          returnTo: '/pet/pet-1',
        ),
        '/pc/events?pet=pet-1&returnTo=%2Fpet%2Fpet-1',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';

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

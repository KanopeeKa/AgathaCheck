import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/screens/health_entry_form_screen.dart';

void main() {
  group('legacyPetEventEditRedirectForPath', () {
    test('maps legacy health edit path', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/health/edit/entry-9'),
        '/pet/pet-1/events/entry-9/edit',
      );
    });

    test('maps legacy other edit path', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-2/other/edit/entry-3'),
        '/pet/pet-2/events/entry-3/edit',
      );
    });

    test('returns null for unrelated paths', () {
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/events/entry-9/edit'),
        isNull,
      );
      expect(
        legacyPetEventEditRedirectForPath('/pet/pet-1/health/add'),
        isNull,
      );
    });
  });
}

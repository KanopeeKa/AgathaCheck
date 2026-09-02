import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/router/vet_routes.dart';

void main() {
  group('legacyVetRedirectForPath', () {
    test('maps list path', () {
      expect(legacyVetRedirectForPath('/vets'), '/pc/vets');
    });

    test('maps add path', () {
      expect(legacyVetRedirectForPath('/vets/add'), '/pc/vets/add');
    });

    test('maps edit path', () {
      expect(
        legacyVetRedirectForPath('/vets/edit/vet-1'),
        '/pc/vets/edit/vet-1',
      );
    });

    test('returns null for unrelated paths', () {
      expect(legacyVetRedirectForPath('/pc/vets'), isNull);
    });
  });
}

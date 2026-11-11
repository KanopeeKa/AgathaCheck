import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/care_list/global_events_pet_query.dart';

void main() {
  group('GlobalEventsPetQuery', () {
    test('parses comma-separated pet ids', () {
      final ids = GlobalEventsPetQuery.petIdsFromUri(
        Uri.parse('/pc/events?pet=pet-a,pet-b'),
      );
      expect(ids, {'pet-a', 'pet-b'});
    });

    test('drops unknown pet ids', () {
      final ids = GlobalEventsPetQuery.petIdsFromUri(
        Uri.parse('/pc/events?pet=pet-a,unknown'),
        knownPetIds: ['pet-a', 'pet-b'],
      );
      expect(ids, {'pet-a'});
    });

    test('serializes sorted pet ids to query param', () {
      final params = GlobalEventsPetQuery.petIdsToQueryParameters({
        'pet-z',
        'pet-a',
      });
      expect(params[GlobalEventsPetQuery.queryParam], 'pet-a,pet-z');
    });

    test('removes query param when selection cleared', () {
      final params = GlobalEventsPetQuery.petIdsToQueryParameters(
        {},
        base: {'pet': 'pet-a', 'foo': 'bar'},
      );
      expect(params.containsKey('pet'), isFalse);
      expect(params['foo'], 'bar');
    });
  });
}

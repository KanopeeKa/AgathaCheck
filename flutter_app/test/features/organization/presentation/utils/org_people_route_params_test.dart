import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/presentation/utils/org_people_route_params.dart';

void main() {
  group('parseOrgPeopleIdsQuery', () {
    test('returns empty list for null or blank', () {
      expect(parseOrgPeopleIdsQuery(null), isEmpty);
      expect(parseOrgPeopleIdsQuery(''), isEmpty);
      expect(parseOrgPeopleIdsQuery('   '), isEmpty);
    });

    test('parses comma-separated ids', () {
      expect(
        parseOrgPeopleIdsQuery('user-a,user-b,user-c'),
        ['user-a', 'user-b', 'user-c'],
      );
    });

    test('trims whitespace and skips blanks', () {
      expect(
        parseOrgPeopleIdsQuery(' user-a , , user-b '),
        ['user-a', 'user-b'],
      );
    });
  });

  group('encodeOrgPeopleIdsQuery', () {
    test('joins ids with commas', () {
      expect(
        encodeOrgPeopleIdsQuery(['user-a', 'user-b']),
        'user-a,user-b',
      );
    });
  });
}

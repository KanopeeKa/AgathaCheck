import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/presentation/hub/roster_hub_query.dart';

void main() {
  test('legacy professionals filter maps to group selection', () {
    final query = RosterHubQuery.fromUri(
      Uri.parse('/pc/people?filter=professionals&q=vet'),
    );
    expect(query.searchQuery, 'vet');
    expect(query.filterSelections[PeopleRosterFilterIds.group], {
      PeopleRosterFilterIds.groupProfessionals,
    });
    final params = query.toQueryParameters();
    expect(params['filter'], 'professionals');
    expect(params['q'], 'vet');
  });

  test('round-trips multi-value filters', () {
    const query = RosterHubQuery(
      searchQuery: 'buddy',
      filterSelections: {
        PeopleRosterFilterIds.kind: {PeopleRosterFilterIds.kindPerson},
        PeopleRosterFilterIds.pet: {'pet-1'},
      },
    );
    final uri = Uri(
      path: '/pc/people',
      queryParameters: query.toQueryParameters(),
    );
    final parsed = RosterHubQuery.fromUri(uri);
    expect(parsed.searchQuery, 'buddy');
    expect(parsed.filterSelections[PeopleRosterFilterIds.kind], {
      PeopleRosterFilterIds.kindPerson,
    });
    expect(parsed.filterSelections[PeopleRosterFilterIds.pet], {'pet-1'});
  });
}

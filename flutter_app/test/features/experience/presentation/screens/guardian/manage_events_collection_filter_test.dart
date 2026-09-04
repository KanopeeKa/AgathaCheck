import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_collection_filter.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_filters.dart';

void main() {
  test('default global filters are due and overdue only', () {
    expect(const GuardianGlobalEventsFilters().eventFilters.statuses, {
      ManageEventsStatusFilter.dueOverdue,
    });
    expect(const OrgGlobalEventsFilters().eventFilters.statuses, {
      ManageEventsStatusFilter.dueOverdue,
    });
  });

  test('selection round-trip preserves guardian global filters', () {
    const filters = GuardianGlobalEventsFilters(
      eventFilters: ManageEventsFilters(
        types: {ManageEventsTypeFilter.medication},
        statuses: {ManageEventsStatusFilter.dueOverdue},
        recurring: {ManageEventsRecurringFilter.recurring},
        showSkipped: false,
      ),
      cohorts: {GuardianEventsCohortFilter.myPets},
      petIds: {'pet-a', 'pet-b'},
    );

    final selections = selectionsFromGuardianGlobalEventsFilters(filters);
    final roundTrip = guardianGlobalEventsFiltersFromSelections(selections);

    expect(roundTrip.eventFilters.types, filters.eventFilters.types);
    expect(roundTrip.eventFilters.statuses, filters.eventFilters.statuses);
    expect(roundTrip.eventFilters.recurring, filters.eventFilters.recurring);
    expect(roundTrip.eventFilters.showSkipped, isFalse);
    expect(roundTrip.cohorts, filters.cohorts);
    expect(roundTrip.petIds, filters.petIds);
  });
}

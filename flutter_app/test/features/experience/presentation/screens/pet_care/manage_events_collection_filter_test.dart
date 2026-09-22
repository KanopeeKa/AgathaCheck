import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_collection_filter.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/screens/widgets/manage_events_filters.dart';

void main() {
  test('default global filters are due and overdue only', () {
    expect(const PetCareGlobalEventsFilters().eventFilters.statuses, {
      ManageEventsStatusFilter.dueOverdue,
    });
    expect(const OrgGlobalEventsFilters().eventFilters.statuses, {
      ManageEventsStatusFilter.dueOverdue,
    });
  });

  test('selection round-trip preserves guardian global filters', () {
    const filters = PetCareGlobalEventsFilters(
      eventFilters: ManageEventsFilters(
        families: {CareFamily.medication},
        filterGroups: {CareFilterGroup.prevention},
        statuses: {ManageEventsStatusFilter.dueOverdue},
        recurring: {ManageEventsRecurringFilter.recurring},
        showSkipped: false,
      ),
      cohorts: {PetCareEventsCohortFilter.myPets},
      petIds: {'pet-a', 'pet-b'},
    );

    final selections = selectionsFromPetCareGlobalEventsFilters(filters);
    final roundTrip = guardianGlobalEventsFiltersFromSelections(selections);

    expect(roundTrip.eventFilters.families, filters.eventFilters.families);
    expect(
      roundTrip.eventFilters.filterGroups,
      filters.eventFilters.filterGroups,
    );
    expect(roundTrip.eventFilters.statuses, filters.eventFilters.statuses);
    expect(roundTrip.eventFilters.recurring, filters.eventFilters.recurring);
    expect(roundTrip.eventFilters.showSkipped, isFalse);
    expect(roundTrip.cohorts, filters.cohorts);
    expect(roundTrip.petIds, filters.petIds);
  });
}

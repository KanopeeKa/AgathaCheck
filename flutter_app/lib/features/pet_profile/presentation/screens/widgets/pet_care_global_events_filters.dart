import 'manage_events_filters.dart';

/// Cohort filter for the global guardian events list.
enum PetCareEventsCohortFilter { all, myPets, fosterPets }

/// Extended filters for global `/g/events` — manage-events filters plus pet/cohort.
class PetCareGlobalEventsFilters {
  const PetCareGlobalEventsFilters({
    this.eventFilters = defaultGlobalEventsFilters,
    this.cohorts = const {},
    this.petIds = const {},
  });

  final ManageEventsFilters eventFilters;
  final Set<PetCareEventsCohortFilter> cohorts;
  final Set<String> petIds;

  PetCareGlobalEventsFilters copyWith({
    ManageEventsFilters? eventFilters,
    Set<PetCareEventsCohortFilter>? cohorts,
    Set<String>? petIds,
  }) => PetCareGlobalEventsFilters(
    eventFilters: eventFilters ?? this.eventFilters,
    cohorts: cohorts ?? this.cohorts,
    petIds: petIds ?? this.petIds,
  );

  PetCareGlobalEventsFilters toggleCohort(PetCareEventsCohortFilter value) {
    if (value == PetCareEventsCohortFilter.all) {
      return copyWith(cohorts: {});
    }
    final next = Set<PetCareEventsCohortFilter>.from(cohorts);
    next.contains(value) ? next.remove(value) : next.add(value);
    return copyWith(cohorts: next);
  }

  PetCareGlobalEventsFilters togglePetId(String petId) {
    final next = Set<String>.from(petIds);
    next.contains(petId) ? next.remove(petId) : next.add(petId);
    return copyWith(petIds: next);
  }

  bool isCohortSelected(PetCareEventsCohortFilter value) =>
      value == PetCareEventsCohortFilter.all
      ? cohorts.isEmpty
      : cohorts.contains(value);

  bool isPetSelected(String? petId) =>
      petId == null ? petIds.isEmpty : petIds.contains(petId);
}

/// Extended filters for org `/o/events` — manage-events filters plus pet/org scoping.
class OrgGlobalEventsFilters {
  const OrgGlobalEventsFilters({
    this.eventFilters = defaultGlobalEventsFilters,
    this.petIds = const {},
    this.orgNames = const {},
  });

  final ManageEventsFilters eventFilters;
  final Set<String> petIds;
  final Set<String> orgNames;

  OrgGlobalEventsFilters copyWith({
    ManageEventsFilters? eventFilters,
    Set<String>? petIds,
    Set<String>? orgNames,
  }) => OrgGlobalEventsFilters(
    eventFilters: eventFilters ?? this.eventFilters,
    petIds: petIds ?? this.petIds,
    orgNames: orgNames ?? this.orgNames,
  );
}

import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filters.dart';

/// Stable ids for global/manage events collection filter dimensions.
abstract final class ManageEventsCollectionFilterIds {
  static const pet = 'pet';
  static const type = 'type';
  static const status = 'status';
  static const recurring = 'recurring';
  static const skipped = 'skipped';
  static const cohort = 'cohort';
  static const organization = 'organization';

  static const all = 'all';
  static const hideSkipped = 'hide';
  static const myPets = 'myPets';
  static const fosterPets = 'fosterPets';

  static String petChoice(String petId) => 'pet:$petId';

  static const primary = [pet, type, status];
  static const more = [recurring, skipped, cohort];
  static const perPetPrimary = [type, status];
  static const perPetMore = [recurring, skipped];
  static const orgMore = [recurring, skipped, organization];
}

List<CollectionFilterDimension> _manageEventsCoreDimensions(AppLocalizations l) {
  return [
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.type,
      label: l.eventFilterTypeLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.all,
          isDefault: true,
        ),
        CollectionFilterChoice(
          id: ManageEventsTypeFilter.medication.name,
          label: l.medication,
        ),
        CollectionFilterChoice(
          id: ManageEventsTypeFilter.preventive.name,
          label: l.preventive,
        ),
        CollectionFilterChoice(
          id: ManageEventsTypeFilter.vetVisit.name,
          label: l.vetVisit,
        ),
        CollectionFilterChoice(
          id: ManageEventsTypeFilter.other.name,
          label: l.other,
        ),
      ],
    ),
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.status,
      label: l.eventFilterStatusLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.all,
          isDefault: true,
        ),
        CollectionFilterChoice(
          id: ManageEventsStatusFilter.open.name,
          label: l.open,
        ),
        CollectionFilterChoice(
          id: ManageEventsStatusFilter.closed.name,
          label: l.eventFilterClosed,
        ),
        CollectionFilterChoice(
          id: ManageEventsStatusFilter.dueOverdue.name,
          label: l.dueAndOverdue,
        ),
      ],
    ),
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.recurring,
      label: l.eventFilterRecurrenceLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.all,
          isDefault: true,
        ),
        CollectionFilterChoice(
          id: ManageEventsRecurringFilter.recurring.name,
          label: l.eventFilterRecurring,
        ),
        CollectionFilterChoice(
          id: ManageEventsRecurringFilter.oneTime.name,
          label: l.eventFilterOneTime,
        ),
      ],
    ),
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.skipped,
      label: l.eventFilterSkippedLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.eventFilterShowSkipped,
          isDefault: true,
        ),
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.hideSkipped,
          label: l.collectionFilterSkippedHidden,
        ),
      ],
      multiSelect: false,
    ),
  ];
}

CollectionFilterSelections _skippedSelectionsFromShowSkipped(bool showSkipped) {
  if (!showSkipped) {
    return {
      ManageEventsCollectionFilterIds.skipped: {
        ManageEventsCollectionFilterIds.hideSkipped,
      },
    };
  }
  return {ManageEventsCollectionFilterIds.skipped: {}};
}

ManageEventsFilters _manageEventsFiltersFromCoreSelections(
  CollectionFilterSelections selections,
) {
  Set<T> parseEnumSet<T>(
    String dimensionId,
    Iterable<T> values,
    T Function(String name) byName,
  ) {
    final ids = selections[dimensionId] ?? const {};
    return ids.map((id) => byName(id)).toSet();
  }

  final skippedSelected =
      selections[ManageEventsCollectionFilterIds.skipped] ?? const {};
  final showSkipped = !skippedSelected.contains(
    ManageEventsCollectionFilterIds.hideSkipped,
  );

  return ManageEventsFilters(
    types: parseEnumSet(
      ManageEventsCollectionFilterIds.type,
      ManageEventsTypeFilter.values.where(
        (value) => value != ManageEventsTypeFilter.all,
      ),
      (name) => ManageEventsTypeFilter.values.byName(name),
    ),
    statuses: parseEnumSet(
      ManageEventsCollectionFilterIds.status,
      ManageEventsStatusFilter.values.where(
        (value) => value != ManageEventsStatusFilter.all,
      ),
      (name) => ManageEventsStatusFilter.values.byName(name),
    ),
    recurring: parseEnumSet(
      ManageEventsCollectionFilterIds.recurring,
      ManageEventsRecurringFilter.values.where(
        (value) => value != ManageEventsRecurringFilter.all,
      ),
      (name) => ManageEventsRecurringFilter.values.byName(name),
    ),
    showSkipped: showSkipped,
  );
}

CollectionFilterSelections _coreSelectionsFromManageEventsFilters(
  ManageEventsFilters filters,
) {
  return {
    ManageEventsCollectionFilterIds.type: filters.types
        .map((value) => value.name)
        .toSet(),
    ManageEventsCollectionFilterIds.status: filters.statuses
        .map((value) => value.name)
        .toSet(),
    ManageEventsCollectionFilterIds.recurring: filters.recurring
        .map((value) => value.name)
        .toSet(),
    ..._skippedSelectionsFromShowSkipped(filters.showSkipped),
  };
}

/// Builds canonical filter dimensions for the global events list.
List<CollectionFilterDimension> buildGlobalEventsFilterDimensions({
  required AppLocalizations l,
  required List<Pet> shellPets,
}) {
  final sortedPets = [...shellPets]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final dimensions = <CollectionFilterDimension>[
    ..._manageEventsCoreDimensions(l),
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.cohort,
      label: l.eventFilterCohortLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.myPets,
          label: l.myPets,
        ),
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.fosterPets,
          label: l.myFosteredPets,
        ),
      ],
    ),
  ];

  if (sortedPets.length > 1) {
    dimensions.insert(
      0,
      CollectionFilterDimension(
        id: ManageEventsCollectionFilterIds.pet,
        label: l.petsNavLabel,
        choices: [
          CollectionFilterChoice(
            id: ManageEventsCollectionFilterIds.all,
            label: l.allPets,
            isDefault: true,
          ),
          for (final pet in sortedPets)
            CollectionFilterChoice(
              id: ManageEventsCollectionFilterIds.petChoice(pet.id),
              label: pet.name,
            ),
        ],
      ),
    );
  }

  return dimensions;
}

/// Per-pet manage events — Type, Status, Recurrence, Skipped (no pet row).
List<CollectionFilterDimension> buildPerPetManageEventsFilterDimensions(
  AppLocalizations l,
) {
  return _manageEventsCoreDimensions(l);
}

List<String> primaryOrgEventsFilterDimensionIds(List<Pet> shellPets) {
  if (shellPets.length > 1) {
    return ManageEventsCollectionFilterIds.primary;
  }
  return ManageEventsCollectionFilterIds.perPetPrimary;
}

/// Org shell events — pet row when multiple pets; org names in More filters.
List<CollectionFilterDimension> buildOrgEventsFilterDimensions({
  required AppLocalizations l,
  required List<Pet> shellPets,
}) {
  final sortedPets = [...shellPets]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  final orgNames =
      sortedPets
          .map((pet) => pet.organizationName)
          .whereType<String>()
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  final dimensions = <CollectionFilterDimension>[
    ..._manageEventsCoreDimensions(l),
    if (orgNames.isNotEmpty)
      CollectionFilterDimension(
        id: ManageEventsCollectionFilterIds.organization,
        label: l.organizations,
        choices: [
          for (final name in orgNames)
            CollectionFilterChoice(id: name, label: name),
        ],
      ),
  ];

  if (sortedPets.length > 1) {
    dimensions.insert(
      0,
      CollectionFilterDimension(
        id: ManageEventsCollectionFilterIds.pet,
        label: l.petsNavLabel,
        choices: [
          CollectionFilterChoice(
            id: ManageEventsCollectionFilterIds.all,
            label: l.allPets,
            isDefault: true,
          ),
          for (final pet in sortedPets)
            CollectionFilterChoice(
              id: ManageEventsCollectionFilterIds.petChoice(pet.id),
              label: pet.name,
            ),
        ],
      ),
    );
  }

  return dimensions;
}

List<String> primaryGlobalEventsFilterDimensionIds(List<Pet> shellPets) {
  if (shellPets.length > 1) {
    return ManageEventsCollectionFilterIds.primary;
  }
  return [ManageEventsCollectionFilterIds.type, ManageEventsCollectionFilterIds.status];
}

CollectionFilterSelections selectionsFromManageEventsFilters(
  ManageEventsFilters filters,
) {
  return _coreSelectionsFromManageEventsFilters(filters);
}

ManageEventsFilters manageEventsFiltersFromSelections(
  CollectionFilterSelections selections,
) {
  return _manageEventsFiltersFromCoreSelections(selections);
}

CollectionFilterSelections selectionsFromGuardianGlobalEventsFilters(
  GuardianGlobalEventsFilters filters,
) {
  return {
    ..._coreSelectionsFromManageEventsFilters(filters.eventFilters),
    ManageEventsCollectionFilterIds.pet: filters.petIds
        .map(ManageEventsCollectionFilterIds.petChoice)
        .toSet(),
    ManageEventsCollectionFilterIds.cohort: {
      if (filters.cohorts.contains(GuardianEventsCohortFilter.myPets))
        ManageEventsCollectionFilterIds.myPets,
      if (filters.cohorts.contains(GuardianEventsCohortFilter.fosterPets))
        ManageEventsCollectionFilterIds.fosterPets,
    },
  };
}

CollectionFilterSelections selectionsFromOrgGlobalEventsFilters(
  OrgGlobalEventsFilters filters,
) {
  return {
    ..._coreSelectionsFromManageEventsFilters(filters.eventFilters),
    ManageEventsCollectionFilterIds.pet: filters.petIds
        .map(ManageEventsCollectionFilterIds.petChoice)
        .toSet(),
    ManageEventsCollectionFilterIds.organization: Set<String>.from(
      filters.orgNames,
    ),
  };
}

GuardianGlobalEventsFilters guardianGlobalEventsFiltersFromSelections(
  CollectionFilterSelections selections,
) {
  final cohortSelected =
      selections[ManageEventsCollectionFilterIds.cohort] ?? const {};
  final cohorts = <GuardianEventsCohortFilter>{
    if (cohortSelected.contains(ManageEventsCollectionFilterIds.myPets))
      GuardianEventsCohortFilter.myPets,
    if (cohortSelected.contains(ManageEventsCollectionFilterIds.fosterPets))
      GuardianEventsCohortFilter.fosterPets,
  };

  final petSelected = selections[ManageEventsCollectionFilterIds.pet] ?? const {};
  final petIds = petSelected
      .where((id) => id.startsWith('pet:'))
      .map((id) => id.substring(4))
      .toSet();

  return GuardianGlobalEventsFilters(
    eventFilters: _manageEventsFiltersFromCoreSelections(selections),
    cohorts: cohorts,
    petIds: petIds,
  );
}

OrgGlobalEventsFilters orgGlobalEventsFiltersFromSelections(
  CollectionFilterSelections selections,
) {
  final petSelected = selections[ManageEventsCollectionFilterIds.pet] ?? const {};
  final petIds = petSelected
      .where((id) => id.startsWith('pet:'))
      .map((id) => id.substring(4))
      .toSet();

  return OrgGlobalEventsFilters(
    eventFilters: _manageEventsFiltersFromCoreSelections(selections),
    petIds: petIds,
    orgNames: selections[ManageEventsCollectionFilterIds.organization] ??
        const {},
  );
}

/// Canonical collection filter bar for the global guardian events list.
class GuardianGlobalEventsCollectionFilterBar extends StatelessWidget {
  const GuardianGlobalEventsCollectionFilterBar({
    super.key,
    required this.shellPets,
    required this.filters,
    required this.onChanged,
  });

  final List<Pet> shellPets;
  final GuardianGlobalEventsFilters filters;
  final ValueChanged<GuardianGlobalEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildGlobalEventsFilterDimensions(
      l: l,
      shellPets: shellPets,
    );
    final selections = selectionsFromGuardianGlobalEventsFilters(filters);

    return CollectionFilterBar(
      key: const Key('global_events_collection_filter_bar'),
      dimensions: dimensions,
      selections: selections,
      onSelectionsChanged: (next) =>
          onChanged(guardianGlobalEventsFiltersFromSelections(next)),
      primaryDimensionIds: primaryGlobalEventsFilterDimensionIds(shellPets),
      moreDimensionIds: ManageEventsCollectionFilterIds.more,
    );
  }
}

/// Canonical collection filter bar for per-pet manage events.
class PetManageEventsCollectionFilterBar extends StatelessWidget {
  const PetManageEventsCollectionFilterBar({
    super.key,
    required this.filters,
    required this.onChanged,
  });

  final ManageEventsFilters filters;
  final ValueChanged<ManageEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildPerPetManageEventsFilterDimensions(l);
    final selections = selectionsFromManageEventsFilters(filters);

    return CollectionFilterBar(
      key: const Key('pet_manage_events_collection_filter_bar'),
      dimensions: dimensions,
      selections: selections,
      onSelectionsChanged: (next) =>
          onChanged(manageEventsFiltersFromSelections(next)),
      primaryDimensionIds: ManageEventsCollectionFilterIds.perPetPrimary,
      moreDimensionIds: ManageEventsCollectionFilterIds.perPetMore,
    );
  }
}

/// Canonical collection filter bar for org shell events.
class OrgGlobalEventsCollectionFilterBar extends StatelessWidget {
  const OrgGlobalEventsCollectionFilterBar({
    super.key,
    required this.shellPets,
    required this.filters,
    required this.onChanged,
  });

  final List<Pet> shellPets;
  final OrgGlobalEventsFilters filters;
  final ValueChanged<OrgGlobalEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildOrgEventsFilterDimensions(
      l: l,
      shellPets: shellPets,
    );
    final selections = selectionsFromOrgGlobalEventsFilters(filters);

    return CollectionFilterBar(
      key: const Key('org_events_collection_filter_bar'),
      dimensions: dimensions,
      selections: selections,
      onSelectionsChanged: (next) =>
          onChanged(orgGlobalEventsFiltersFromSelections(next)),
      primaryDimensionIds: primaryOrgEventsFilterDimensionIds(shellPets),
      moreDimensionIds: ManageEventsCollectionFilterIds.orgMore,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/features/care_taxonomy/domain/care_family_definition.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/care_family.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/care_family_write.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_family_labels.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/widgets/care_filter_group_labels.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filters.dart';

/// Stable ids for global/manage events collection filter dimensions.
abstract final class ManageEventsCollectionFilterIds {
  static const pet = 'pet';
  static const family = 'family';
  static const filterGroup = 'filterGroup';
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

  static const primary = [pet, filterGroup, family, status];
  static const more = [recurring, skipped, cohort];
  static const perPetPrimary = [filterGroup, family, status];
  static const perPetMore = [recurring, skipped];
  static const orgMore = [recurring, skipped, organization];
}

List<CollectionFilterDimension> manageEventsCoreDimensions(
  AppLocalizations l,
) => _manageEventsCoreDimensions(l);

CollectionFilterSelections coreSelectionsFromManageEventsFilters(
  ManageEventsFilters filters,
) => _coreSelectionsFromManageEventsFilters(filters);

ManageEventsFilters manageEventsFiltersFromCoreSelections(
  CollectionFilterSelections selections,
) => _manageEventsFiltersFromCoreSelections(selections);

List<CollectionFilterDimension> _manageEventsCoreDimensions(
  AppLocalizations l,
) {
  return [
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.filterGroup,
      label: l.eventFilterGroupLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.all,
          isDefault: true,
        ),
        for (final group in CareFilterGroup.values)
          CollectionFilterChoice(
            id: group.name,
            label: careFilterGroupLabel(l, group),
          ),
      ],
    ),
    CollectionFilterDimension(
      id: ManageEventsCollectionFilterIds.family,
      label: l.eventFilterFamilyLabel,
      choices: [
        CollectionFilterChoice(
          id: ManageEventsCollectionFilterIds.all,
          label: l.all,
          isDefault: true,
        ),
        for (final family in kRecurringCareFamilyPickerOptions)
          CollectionFilterChoice(
            id: family.name,
            label: careFamilyLabel(l, family),
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
    families: parseEnumSet(
      ManageEventsCollectionFilterIds.family,
      kRecurringCareFamilyPickerOptions,
      (name) => CareFamily.values.byName(name),
    ),
    filterGroups: parseEnumSet(
      ManageEventsCollectionFilterIds.filterGroup,
      CareFilterGroup.values,
      (name) => CareFilterGroup.values.byName(name),
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
    ManageEventsCollectionFilterIds.family: filters.families
        .map((value) => value.name)
        .toSet(),
    ManageEventsCollectionFilterIds.filterGroup: filters.filterGroups
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

/// Per-pet manage events — Group, Category, Status, Recurrence, Skipped.
List<CollectionFilterDimension> buildPerPetManageEventsFilterDimensions(
  AppLocalizations l,
) {
  return _manageEventsCoreDimensions(l);
}

List<String> primaryGlobalEventsFilterDimensionIds(List<Pet> shellPets) {
  if (shellPets.length > 1) {
    return ManageEventsCollectionFilterIds.primary;
  }
  return [
    ManageEventsCollectionFilterIds.filterGroup,
    ManageEventsCollectionFilterIds.family,
    ManageEventsCollectionFilterIds.status,
  ];
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

CollectionFilterSelections selectionsFromPetCareGlobalEventsFilters(
  PetCareGlobalEventsFilters filters,
) {
  return {
    ..._coreSelectionsFromManageEventsFilters(filters.eventFilters),
    ManageEventsCollectionFilterIds.pet: filters.petIds
        .map(ManageEventsCollectionFilterIds.petChoice)
        .toSet(),
    ManageEventsCollectionFilterIds.cohort: {
      if (filters.cohorts.contains(PetCareEventsCohortFilter.myPets))
        ManageEventsCollectionFilterIds.myPets,
      if (filters.cohorts.contains(PetCareEventsCohortFilter.fosterPets))
        ManageEventsCollectionFilterIds.fosterPets,
    },
  };
}

PetCareGlobalEventsFilters guardianGlobalEventsFiltersFromSelections(
  CollectionFilterSelections selections,
) {
  final cohortSelected =
      selections[ManageEventsCollectionFilterIds.cohort] ?? const {};
  final cohorts = <PetCareEventsCohortFilter>{
    if (cohortSelected.contains(ManageEventsCollectionFilterIds.myPets))
      PetCareEventsCohortFilter.myPets,
    if (cohortSelected.contains(ManageEventsCollectionFilterIds.fosterPets))
      PetCareEventsCohortFilter.fosterPets,
  };

  final petSelected =
      selections[ManageEventsCollectionFilterIds.pet] ?? const {};
  final petIds = petSelected
      .where((id) => id.startsWith('pet:'))
      .map((id) => id.substring(4))
      .toSet();

  return PetCareGlobalEventsFilters(
    eventFilters: _manageEventsFiltersFromCoreSelections(selections),
    cohorts: cohorts,
    petIds: petIds,
  );
}

/// Canonical collection filter bar for the global guardian events list.
class PetCareGlobalEventsCollectionFilterBar extends StatelessWidget {
  const PetCareGlobalEventsCollectionFilterBar({
    super.key,
    required this.shellPets,
    required this.filters,
    required this.onChanged,
  });

  final List<Pet> shellPets;
  final PetCareGlobalEventsFilters filters;
  final ValueChanged<PetCareGlobalEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildGlobalEventsFilterDimensions(
      l: l,
      shellPets: shellPets,
    );
    final selections = selectionsFromPetCareGlobalEventsFilters(filters);

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

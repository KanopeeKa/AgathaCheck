import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_due_events_screen.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_collection_filter.dart';

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
    ...manageEventsCoreDimensions(l),
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

CollectionFilterSelections selectionsFromOrgGlobalEventsFilters(
  OrgGlobalEventsFilters filters,
) {
  return {
    ...coreSelectionsFromManageEventsFilters(filters.eventFilters),
    ManageEventsCollectionFilterIds.pet: filters.petIds
        .map(ManageEventsCollectionFilterIds.petChoice)
        .toSet(),
    ManageEventsCollectionFilterIds.organization: Set<String>.from(
      filters.orgNames,
    ),
  };
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
    eventFilters: manageEventsFiltersFromCoreSelections(selections),
    petIds: petIds,
    orgNames: selections[ManageEventsCollectionFilterIds.organization] ??
        const {},
  );
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

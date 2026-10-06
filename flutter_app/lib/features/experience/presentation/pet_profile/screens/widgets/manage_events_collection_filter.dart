export 'manage_events_filter_dimensions.dart';

import 'package:flutter/material.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'manage_events_filter_dimensions.dart';
import 'manage_events_filters.dart';
import 'pet_care_global_events_filters.dart';

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

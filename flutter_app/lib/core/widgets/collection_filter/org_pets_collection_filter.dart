import 'package:flutter/material.dart';

import '../../../features/organization/presentation/utils/org_pets_care_utils.dart';
import '../../../l10n/app_localizations.dart';
import 'collection_filter.dart';

abstract final class OrgPetsCollectionFilterIds {
  static const refinements = 'refinements';
  static const name = 'name';
  static const fosteredBy = 'fosteredBy';
  static const shadow = 'shadow';
  static const rainbowBridge = 'rainbowBridge';
}

List<CollectionFilterDimension> buildOrgPetsRefinementDimensions(
  AppLocalizations l,
) {
  return [
    CollectionFilterDimension(
      id: OrgPetsCollectionFilterIds.refinements,
      label: l.orgPetsFiltersLabel,
      choices: [
        CollectionFilterChoice(
          id: OrgPetsCollectionFilterIds.name,
          label: l.orgPetsFilterName,
        ),
        CollectionFilterChoice(
          id: OrgPetsCollectionFilterIds.fosteredBy,
          label: l.orgPetsFilterFosteredBy,
        ),
        CollectionFilterChoice(
          id: OrgPetsCollectionFilterIds.shadow,
          label: l.orgPetsFilterShadow,
        ),
        CollectionFilterChoice(
          id: OrgPetsCollectionFilterIds.rainbowBridge,
          label: l.orgPetsFilterRainbowBridge,
        ),
      ],
    ),
  ];
}

CollectionFilterSelections selectionsFromOrgPetsActiveFilters(
  Set<OrgPetsActiveFilter> activeFilters,
) {
  return {
    OrgPetsCollectionFilterIds.refinements: {
      for (final filter in activeFilters) filter.name,
    },
  };
}

Set<OrgPetsActiveFilter> orgPetsActiveFiltersFromSelections(
  CollectionFilterSelections selections,
) {
  final selected =
      selections[OrgPetsCollectionFilterIds.refinements] ?? const {};
  return {
    for (final id in selected) OrgPetsActiveFilter.values.byName(id),
  };
}

class OrgPetsRefinementCollectionFilterBar extends StatelessWidget {
  const OrgPetsRefinementCollectionFilterBar({
    super.key,
    required this.activeFilters,
    required this.onActiveFiltersChanged,
  });

  final Set<OrgPetsActiveFilter> activeFilters;
  final ValueChanged<Set<OrgPetsActiveFilter>> onActiveFiltersChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildOrgPetsRefinementDimensions(l);

    return CollectionFilterBar(
      key: const Key('org_pets_refinement_collection_filter_bar'),
      dimensions: dimensions,
      selections: selectionsFromOrgPetsActiveFilters(activeFilters),
      onSelectionsChanged: (next) =>
          onActiveFiltersChanged(orgPetsActiveFiltersFromSelections(next)),
      primaryDimensionIds: const [OrgPetsCollectionFilterIds.refinements],
      padding: EdgeInsets.zero,
    );
  }
}

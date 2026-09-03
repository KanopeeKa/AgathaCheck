import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'collection_filter.dart';

/// Stable ids for org/cohort context filters (pet list, health dashboard, vets).
abstract final class OrgContextCollectionFilterIds {
  static const context = 'context';
  static const all = 'all';
  static const personal = 'personal';
  static const fostered = 'fostered';

  static String orgByName(String name) => 'orgName:$name';
  static String orgById(String id) => 'orgId:$id';
}

List<CollectionFilterDimension> buildPetListOrgContextDimensions({
  required AppLocalizations l,
  required List<String> orgNames,
  required bool showFosteredChoice,
}) {
  return [
    CollectionFilterDimension(
      id: OrgContextCollectionFilterIds.context,
      label: l.orgPetsFiltersLabel,
      multiSelect: false,
      choices: [
        CollectionFilterChoice(
          id: OrgContextCollectionFilterIds.all,
          label: l.allPets,
          isDefault: true,
        ),
        CollectionFilterChoice(
          id: OrgContextCollectionFilterIds.personal,
          label: l.myPets,
        ),
        if (showFosteredChoice)
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.fostered,
            label: l.myFosteredPets,
          ),
        for (final name in orgNames)
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.orgByName(name),
            label: name,
          ),
      ],
    ),
  ];
}

List<CollectionFilterDimension> buildHealthDashboardOrgContextDimensions({
  required AppLocalizations l,
  required List<String> orgNames,
  required bool organizationScope,
}) {
  return [
    CollectionFilterDimension(
      id: OrgContextCollectionFilterIds.context,
      label: l.organizations,
      multiSelect: false,
      choices: [
        if (!organizationScope) ...[
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.all,
            label: l.allPets,
            isDefault: true,
          ),
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.personal,
            label: l.myPets,
          ),
        ],
        for (final name in orgNames)
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.orgByName(name),
            label: name,
          ),
      ],
    ),
  ];
}

List<CollectionFilterDimension> buildVetOrgContextDimensions({
  required AppLocalizations l,
  required List<({String id, String name})> orgs,
  required bool organizationScope,
}) {
  return [
    CollectionFilterDimension(
      id: OrgContextCollectionFilterIds.context,
      label: l.organizations,
      multiSelect: false,
      choices: [
        if (!organizationScope)
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.all,
            label: l.all,
            isDefault: true,
          ),
        CollectionFilterChoice(
          id: OrgContextCollectionFilterIds.personal,
          label: l.myVets,
        ),
        for (final org in orgs)
          CollectionFilterChoice(
            id: OrgContextCollectionFilterIds.orgById(org.id),
            label: org.name,
          ),
      ],
    ),
  ];
}

CollectionFilterSelections orgContextSelectionsFromNameFilter(String? filter) {
  if (filter == null) {
    return const {};
  }
  if (filter == '_personal') {
    return {
      OrgContextCollectionFilterIds.context: {
        OrgContextCollectionFilterIds.personal,
      },
    };
  }
  if (filter == '_fostered') {
    return {
      OrgContextCollectionFilterIds.context: {
        OrgContextCollectionFilterIds.fostered,
      },
    };
  }
  return {
    OrgContextCollectionFilterIds.context: {
      OrgContextCollectionFilterIds.orgByName(filter),
    },
  };
}

String? orgContextNameFilterFromSelections(CollectionFilterSelections selections) {
  final selected = selections[OrgContextCollectionFilterIds.context] ?? const {};
  if (selected.isEmpty) return null;
  if (selected.contains(OrgContextCollectionFilterIds.personal)) {
    return '_personal';
  }
  if (selected.contains(OrgContextCollectionFilterIds.fostered)) {
    return '_fostered';
  }
  for (final id in selected) {
    if (id.startsWith('orgName:')) return id.substring(8);
  }
  return null;
}

CollectionFilterSelections orgContextSelectionsFromIdFilter(String? filter) {
  if (filter == null) {
    return const {};
  }
  if (filter == '_personal') {
    return {
      OrgContextCollectionFilterIds.context: {
        OrgContextCollectionFilterIds.personal,
      },
    };
  }
  return {
    OrgContextCollectionFilterIds.context: {
      OrgContextCollectionFilterIds.orgById(filter),
    },
  };
}

String? orgContextIdFilterFromSelections(CollectionFilterSelections selections) {
  final selected = selections[OrgContextCollectionFilterIds.context] ?? const {};
  if (selected.isEmpty) return null;
  if (selected.contains(OrgContextCollectionFilterIds.personal)) {
    return '_personal';
  }
  for (final id in selected) {
    if (id.startsWith('orgId:')) return id.substring(6);
  }
  return null;
}

/// Pet list org/cohort filter bar.
class PetListOrgCollectionFilterBar extends StatelessWidget {
  const PetListOrgCollectionFilterBar({
    super.key,
    required this.orgNames,
    required this.showFosteredChoice,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<String> orgNames;
  final bool showFosteredChoice;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildPetListOrgContextDimensions(
      l: l,
      orgNames: orgNames,
      showFosteredChoice: showFosteredChoice,
    );

    return CollectionFilterBar(
      key: const Key('pet_list_org_collection_filter_bar'),
      dimensions: dimensions,
      selections: orgContextSelectionsFromNameFilter(selectedFilter),
      onSelectionsChanged: (next) =>
          onFilterChanged(orgContextNameFilterFromSelections(next)),
      primaryDimensionIds: const [OrgContextCollectionFilterIds.context],
    );
  }
}

/// Legacy `/health` org filter bar.
class HealthDashboardOrgCollectionFilterBar extends StatelessWidget {
  const HealthDashboardOrgCollectionFilterBar({
    super.key,
    required this.orgNames,
    required this.organizationScope,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<String> orgNames;
  final bool organizationScope;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildHealthDashboardOrgContextDimensions(
      l: l,
      orgNames: orgNames,
      organizationScope: organizationScope,
    );

    return CollectionFilterBar(
      key: const Key('health_dashboard_org_collection_filter_bar'),
      dimensions: dimensions,
      selections: orgContextSelectionsFromNameFilter(selectedFilter),
      onSelectionsChanged: (next) =>
          onFilterChanged(orgContextNameFilterFromSelections(next)),
      primaryDimensionIds: const [OrgContextCollectionFilterIds.context],
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    );
  }
}

/// Vet list org filter bar.
class VetOrgCollectionFilterBar extends StatelessWidget {
  const VetOrgCollectionFilterBar({
    super.key,
    required this.orgs,
    required this.organizationScope,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final List<({String id, String name})> orgs;
  final bool organizationScope;
  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (orgs.isEmpty && organizationScope) {
      return const SizedBox.shrink();
    }

    final dimensions = buildVetOrgContextDimensions(
      l: l,
      orgs: orgs,
      organizationScope: organizationScope,
    );

    return CollectionFilterBar(
      key: const Key('vet_org_collection_filter_bar'),
      dimensions: dimensions,
      selections: orgContextSelectionsFromIdFilter(selectedFilter),
      onSelectionsChanged: (next) =>
          onFilterChanged(orgContextIdFilterFromSelections(next)),
      primaryDimensionIds: const [OrgContextCollectionFilterIds.context],
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    );
  }
}

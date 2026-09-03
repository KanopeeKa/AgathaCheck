import 'package:flutter/material.dart';

import '../../../features/organization/presentation/providers/manage_fosters_providers.dart';
import '../../../l10n/app_localizations.dart';
import 'collection_filter.dart';

abstract final class ManageFostersCollectionFilterIds {
  static const approval = 'approval';
  static const underReview = 'underReview';
  static const approved = 'approved';
  static const archived = 'archived';
}

List<CollectionFilterDimension> buildManageFostersApprovalDimensions(
  AppLocalizations l,
) {
  return [
    CollectionFilterDimension(
      id: ManageFostersCollectionFilterIds.approval,
      label: l.manageFostersApprovalFiltersLabel,
      multiSelect: false,
      choices: [
        CollectionFilterChoice(
          id: ManageFostersCollectionFilterIds.underReview,
          label: l.manageFostersFilterUnderReview,
        ),
        CollectionFilterChoice(
          id: ManageFostersCollectionFilterIds.approved,
          label: l.manageFostersFilterApproved,
        ),
        CollectionFilterChoice(
          id: ManageFostersCollectionFilterIds.archived,
          label: l.manageFostersFilterArchived,
        ),
      ],
    ),
  ];
}

CollectionFilterSelections selectionsFromManageFostersApprovalFilter(
  ManageFostersApprovalFilter? filter,
) {
  if (filter == null) return const {};
  return {
    ManageFostersCollectionFilterIds.approval: {filter.name},
  };
}

ManageFostersApprovalFilter? manageFostersApprovalFilterFromSelections(
  CollectionFilterSelections selections,
) {
  final selected =
      selections[ManageFostersCollectionFilterIds.approval] ?? const {};
  if (selected.isEmpty) return null;
  final id = selected.first;
  return ManageFostersApprovalFilter.values.byName(id);
}

class ManageFostersApprovalCollectionFilterBar extends StatelessWidget {
  const ManageFostersApprovalCollectionFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  final ManageFostersApprovalFilter? selectedFilter;
  final ValueChanged<ManageFostersApprovalFilter?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final dimensions = buildManageFostersApprovalDimensions(l);

    return CollectionFilterBar(
      key: const Key('manage_fosters_approval_collection_filter_bar'),
      dimensions: dimensions,
      selections: selectionsFromManageFostersApprovalFilter(selectedFilter),
      onSelectionsChanged: (next) =>
          onFilterChanged(manageFostersApprovalFilterFromSelections(next)),
      primaryDimensionIds: const [ManageFostersCollectionFilterIds.approval],
      padding: EdgeInsets.zero,
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/widgets/collection_filter/org_context_collection_filter.dart';

export '../../../../core/widgets/collection_filter/org_context_collection_filter.dart'
    show VetOrgCollectionFilterBar;

/// Filter bar for vet list: All | My vets (frozen MVP — no per-org filters).
@Deprecated('Use VetOrgCollectionFilterBar')
class VetFilterBar extends StatelessWidget {
  const VetFilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.guardianOnly = false,
  });

  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;
  final bool guardianOnly;

  @override
  Widget build(BuildContext context) {
    return VetOrgCollectionFilterBar(
      orgs: const [],
      organizationScope: guardianOnly,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
    );
  }
}

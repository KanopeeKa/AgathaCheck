import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/collection_filter/org_context_collection_filter.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/organization_providers.dart';

export '../../../../core/widgets/collection_filter/org_context_collection_filter.dart'
    show VetOrgCollectionFilterBar;

/// Filter bar for vet list: All | My vets | per-org.
@Deprecated('Use VetOrgCollectionFilterBar')
class VetFilterBar extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationListProvider);
    final orgs = orgsAsync.valueOrNull ?? <Organization>[];

    return VetOrgCollectionFilterBar(
      orgs: orgs.map((org) => (id: org.id, name: org.name)).toList(),
      organizationScope: guardianOnly,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
    );
  }
}

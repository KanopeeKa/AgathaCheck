import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/widgets/collection_filter/org_context_collection_filter.dart';
import '../../../domain/health_events_scope.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';

export '../../../../../core/widgets/collection_filter/org_context_collection_filter.dart'
    show HealthDashboardOrgCollectionFilterBar;

/// Organization filter for legacy `/health` dashboard entry lists.
@Deprecated('Use HealthDashboardOrgCollectionFilterBar')
class HealthDashboardOrgFilter extends ConsumerWidget {
  const HealthDashboardOrgFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.scope = HealthEventsScope.all,
  });

  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;
  final HealthEventsScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPetsAsync = ref.watch(allPetsIncludingOrgProvider);
    final pets = allPetsAsync.valueOrNull ?? [];
    final scopedPets = switch (scope) {
      HealthEventsScope.organization => PetListController().orgShellPets(pets),
      _ => pets,
    };
    final orgNames =
        scopedPets
            .where(
              (p) =>
                  p.organizationName != null && p.organizationName!.isNotEmpty,
            )
            .map((p) => p.organizationName!)
            .toSet()
            .toList()
          ..sort();
    if (orgNames.isEmpty) return const SizedBox.shrink();

    return HealthDashboardOrgCollectionFilterBar(
      orgNames: orgNames,
      organizationScope: scope == HealthEventsScope.organization,
      selectedFilter: selectedFilter,
      onFilterChanged: onFilterChanged,
    );
  }
}

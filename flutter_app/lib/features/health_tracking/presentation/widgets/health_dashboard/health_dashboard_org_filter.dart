import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/health_events_scope.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';

/// Horizontal row of organization filter chips shown above the entry lists.
///
/// Extracted from `health_dashboard_screen.dart`. Renders nothing when the user
/// has no organization pets. [selectedFilter] uses `null` for "all pets",
/// `'_personal'` for personal pets, or an organization name.
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
    final l = AppLocalizations.of(context)!;
    final allPetsAsync = ref.watch(allPetsIncludingOrgProvider);
    final pets = allPetsAsync.valueOrNull ?? [];
    final scopedPets = switch (scope) {
      HealthEventsScope.organization =>
        PetListController().orgShellPets(pets),
      _ => pets,
    };
    final orgNames =
        scopedPets
            .where((p) => p.organizationName != null && p.organizationName!.isNotEmpty)
            .map((p) => p.organizationName!)
            .toSet()
            .toList()
          ..sort();
    if (orgNames.isEmpty) return const SizedBox.shrink();
    final guardianOnly = scope == HealthEventsScope.organization;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (!guardianOnly) ...[
              FilterChip(
                label: Text(l.allPets),
                selected: selectedFilter == null,
                onSelected: (_) => onFilterChanged(null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l.myPets),
                selected: selectedFilter == '_personal',
                onSelected: (_) => onFilterChanged('_personal'),
              ),
            ],
            ...orgNames.map(
              (name) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilterChip(
                  avatar: const Icon(Icons.business, size: 16),
                  label: Text(name),
                  selected: selectedFilter == name,
                  onSelected: (_) => onFilterChanged(name),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

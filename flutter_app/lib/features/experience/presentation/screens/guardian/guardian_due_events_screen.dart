import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/domain/entities/health_history_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/controllers/pet_list_controller.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../../pet_profile/presentation/screens/widgets/pet_event_entry_list.dart';

import 'global_events_list.dart';
export 'global_events_list.dart' show GlobalEventsList;

// ---------------------------------------------------------------------------
// Filter value types
// ---------------------------------------------------------------------------

/// Cohort filter for the global guardian events list.
enum GuardianEventsCohortFilter { all, myPets, fosterPets }

/// Extended filters for global `/g/events` — manage-events filters plus pet/cohort.
class GuardianGlobalEventsFilters {
  const GuardianGlobalEventsFilters({
    this.eventFilters = const ManageEventsFilters(),
    this.cohorts = const {},
    this.petIds = const {},
  });

  final ManageEventsFilters eventFilters;
  final Set<GuardianEventsCohortFilter> cohorts;
  final Set<String> petIds;

  GuardianGlobalEventsFilters copyWith({
    ManageEventsFilters? eventFilters,
    Set<GuardianEventsCohortFilter>? cohorts,
    Set<String>? petIds,
  }) => GuardianGlobalEventsFilters(
    eventFilters: eventFilters ?? this.eventFilters,
    cohorts: cohorts ?? this.cohorts,
    petIds: petIds ?? this.petIds,
  );

  GuardianGlobalEventsFilters toggleCohort(GuardianEventsCohortFilter value) {
    if (value == GuardianEventsCohortFilter.all) {
      return copyWith(cohorts: {});
    }
    final next = Set<GuardianEventsCohortFilter>.from(cohorts);
    next.contains(value) ? next.remove(value) : next.add(value);
    return copyWith(cohorts: next);
  }

  GuardianGlobalEventsFilters togglePetId(String petId) {
    final next = Set<String>.from(petIds);
    next.contains(petId) ? next.remove(petId) : next.add(petId);
    return copyWith(petIds: next);
  }

  bool isCohortSelected(GuardianEventsCohortFilter value) =>
      value == GuardianEventsCohortFilter.all
      ? cohorts.isEmpty
      : cohorts.contains(value);

  bool isPetSelected(String? petId) =>
      petId == null ? petIds.isEmpty : petIds.contains(petId);
}

/// Extended filters for org `/o/events` — manage-events filters plus pet/org scoping.
class OrgGlobalEventsFilters {
  const OrgGlobalEventsFilters({
    this.eventFilters = const ManageEventsFilters(),
    this.petIds = const {},
    this.orgNames = const {},
  });

  final ManageEventsFilters eventFilters;
  final Set<String> petIds;
  final Set<String> orgNames;

  OrgGlobalEventsFilters copyWith({
    ManageEventsFilters? eventFilters,
    Set<String>? petIds,
    Set<String>? orgNames,
  }) => OrgGlobalEventsFilters(
    eventFilters: eventFilters ?? this.eventFilters,
    petIds: petIds ?? this.petIds,
    orgNames: orgNames ?? this.orgNames,
  );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Histories for all guardian shell-pet entries (global events list).
final guardianGlobalEventHistoriesProvider =
    FutureProvider<Map<String, List<HealthHistoryEntry>>>((ref) async {
      final entries =
          ref.watch(healthEntriesNotifierProvider).valueOrNull ?? [];
      final pets = ref.watch(petListProvider).valueOrNull ?? [];
      final shellPetIds = PetListController()
          .guardianShellPets(pets)
          .map((pet) => pet.id)
          .toSet();
      final scoped = entries.where((e) => shellPetIds.contains(e.petId));
      final histories = <String, List<HealthHistoryEntry>>{};
      await Future.wait(
        scoped.map((entry) async {
          histories[entry.id] = await ref.read(
            entryHistoryProvider(entry.id).future,
          );
        }),
      );
      return histories;
    });

/// Histories for org shell-pet entries (org events list).
final orgGlobalEventHistoriesProvider =
    FutureProvider<Map<String, List<HealthHistoryEntry>>>((ref) async {
      final entries =
          ref.watch(healthEntriesNotifierProvider).valueOrNull ?? [];
      final pets = ref.watch(petListProvider).valueOrNull ?? [];
      final shellPetIds = PetListController()
          .orgShellPets(pets)
          .map((pet) => pet.id)
          .toSet();
      final scoped = entries.where((e) => shellPetIds.contains(e.petId));
      final histories = <String, List<HealthHistoryEntry>>{};
      await Future.wait(
        scoped.map((entry) async {
          histories[entry.id] = await ref.read(
            entryHistoryProvider(entry.id).future,
          );
        }),
      );
      return histories;
    });

// ---------------------------------------------------------------------------
// Pure filter/sort functions
// ---------------------------------------------------------------------------

/// Returns the subset of [shellPets] that match the cohort and pet-id filters.
List<Pet> guardianGlobalEventsPets(
  List<Pet> shellPets,
  GuardianGlobalEventsFilters filters,
) {
  var pets = shellPets;

  if (filters.cohorts.isNotEmpty) {
    pets = pets.where((pet) {
      final matchesMyPets =
          filters.cohorts.contains(GuardianEventsCohortFilter.myPets) &&
          !pet.isFoster;
      final matchesFoster =
          filters.cohorts.contains(GuardianEventsCohortFilter.fosterPets) &&
          pet.isFoster;
      return matchesMyPets || matchesFoster;
    }).toList();
  }

  if (filters.petIds.isNotEmpty) {
    pets = pets.where((pet) => filters.petIds.contains(pet.id)).toList();
  }

  return pets;
}

/// Returns the subset of [shellPets] that match pet-id and org-name filters.
List<Pet> orgGlobalEventsPets(
  List<Pet> shellPets,
  OrgGlobalEventsFilters filters,
) {
  var pets = shellPets;

  if (filters.orgNames.isNotEmpty) {
    pets = pets
        .where(
          (pet) =>
              pet.organizationName != null &&
              filters.orgNames.contains(pet.organizationName),
        )
        .toList();
  }

  if (filters.petIds.isNotEmpty) {
    pets = pets.where((pet) => filters.petIds.contains(pet.id)).toList();
  }

  return pets;
}

/// Filters [entries] to the scoped org pets and applied event filters.
List<HealthEntry> filterOrgGlobalEvents(
  List<HealthEntry> entries,
  List<Pet> scopedPets,
  OrgGlobalEventsFilters filters,
  Map<String, List<HealthHistoryEntry>> histories,
) {
  final petIds = scopedPets.map((pet) => pet.id).toSet();
  return entries
      .where((entry) => petIds.contains(entry.petId))
      .where(
        (entry) => matchesManageEventsFilters(
          entry,
          filters.eventFilters,
          histories[entry.id] ?? const [],
        ),
      )
      .toList();
}

/// Filters and sorts [entries] to the scoped pets and applied event filters.
List<HealthEntry> filterGuardianGlobalEvents(
  List<HealthEntry> entries,
  List<Pet> scopedPets,
  GuardianGlobalEventsFilters filters,
  Map<String, List<HealthHistoryEntry>> histories,
) {
  final petIds = scopedPets.map((pet) => pet.id).toSet();
  // The provider response is already the server-authoritative order for this
  // destination. Apply the manage-event predicates without calling
  // filterAndSortManageEvents, whose dedicated pet-management screens
  // intentionally impose a different local sort.
  return entries
      .where((entry) => petIds.contains(entry.petId))
      .where(
        (entry) => matchesManageEventsFilters(
          entry,
          filters.eventFilters,
          histories[entry.id] ?? const [],
        ),
      )
      .toList();
}

// ---------------------------------------------------------------------------
// Screen widget
// ---------------------------------------------------------------------------

/// Guardian events screen (`/g/events`) — unified list for all shell pets.
class GuardianDueEventsScreen extends ConsumerWidget {
  const GuardianDueEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _PetLoadErrorView(
        message: l.careLoadError,
        onRetry: () => ref.invalidate(petListProvider),
      ),
      data: (allPets) {
        final shellPets = PetListController().guardianShellPets(allPets);
        return GlobalEventsList(shellPets: shellPets);
      },
    );
  }
}

/// Org events screen (`/o/events`) — unified list for org inventory pets.
class OrgDueEventsScreen extends ConsumerWidget {
  const OrgDueEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final petsAsync = ref.watch(petListProvider);

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => _PetLoadErrorView(
        message: l.careLoadError,
        onRetry: () => ref.invalidate(petListProvider),
      ),
      data: (allPets) {
        final shellPets = PetListController().orgShellPets(allPets);
        return GlobalEventsList(
          shellPets: shellPets,
          scope: GlobalEventsListScope.organization,
        );
      },
    );
  }
}

/// Localized, retryable pet-load error shown in [GuardianDueEventsScreen].
class _PetLoadErrorView extends StatelessWidget {
  const _PetLoadErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const Key('pet_load_error_retry'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter bar widget
// ---------------------------------------------------------------------------

/// Pet and cohort filter chips for the global guardian events list.
@Deprecated('Use GuardianGlobalEventsCollectionFilterBar')
class GuardianGlobalEventsFilterBar extends StatelessWidget {
  const GuardianGlobalEventsFilterBar({
    super.key,
    required this.shellPets,
    required this.filters,
    required this.onChanged,
  });

  final List<Pet> shellPets;
  final GuardianGlobalEventsFilters filters;
  final ValueChanged<GuardianGlobalEventsFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sortedPets = [...shellPets]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipRow(
            children: [
              _cohortChip(GuardianEventsCohortFilter.all, l.all),
              _cohortChip(GuardianEventsCohortFilter.myPets, l.myPets),
              _cohortChip(
                GuardianEventsCohortFilter.fosterPets,
                l.myFosteredPets,
              ),
            ],
          ),
          if (sortedPets.length > 1) ...[
            const SizedBox(height: 8),
            _ChipRow(
              children: [
                FilterChip(
                  key: const Key('global_events_pet_all'),
                  label: Text(l.allPets),
                  selected: filters.isPetSelected(null),
                  onSelected: (_) => onChanged(filters.copyWith(petIds: {})),
                ),
                for (final pet in sortedPets)
                  FilterChip(
                    key: Key('global_events_pet_${pet.id}'),
                    label: Text(pet.name),
                    selected: filters.isPetSelected(pet.id),
                    onSelected: (_) => onChanged(filters.togglePetId(pet.id)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cohortChip(GuardianEventsCohortFilter value, String label) {
    return FilterChip(
      key: Key('global_events_cohort_${value.name}'),
      label: Text(label),
      selected: filters.isCohortSelected(value),
      onSelected: (_) => onChanged(filters.toggleCohort(value)),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      ),
    );
  }
}

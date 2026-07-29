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
  }) {
    return GuardianGlobalEventsFilters(
      eventFilters: eventFilters ?? this.eventFilters,
      cohorts: cohorts ?? this.cohorts,
      petIds: petIds ?? this.petIds,
    );
  }

  GuardianGlobalEventsFilters toggleCohort(GuardianEventsCohortFilter value) {
    if (value == GuardianEventsCohortFilter.all) {
      return copyWith(cohorts: {});
    }
    final next = Set<GuardianEventsCohortFilter>.from(cohorts);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    return copyWith(cohorts: next);
  }

  GuardianGlobalEventsFilters togglePetId(String petId) {
    final next = Set<String>.from(petIds);
    if (next.contains(petId)) {
      next.remove(petId);
    } else {
      next.add(petId);
    }
    return copyWith(petIds: next);
  }

  bool isCohortSelected(GuardianEventsCohortFilter value) =>
      value == GuardianEventsCohortFilter.all
      ? cohorts.isEmpty
      : cohorts.contains(value);

  bool isPetSelected(String? petId) =>
      petId == null ? petIds.isEmpty : petIds.contains(petId);
}

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

List<HealthEntry> filterGuardianGlobalEvents(
  List<HealthEntry> entries,
  List<Pet> scopedPets,
  GuardianGlobalEventsFilters filters,
  Map<String, List<HealthHistoryEntry>> histories,
) {
  final petIds = scopedPets.map((pet) => pet.id).toSet();
  final scopedEntries = entries.where((e) => petIds.contains(e.petId)).toList();
  return filterAndSortManageEvents(
    scopedEntries,
    filters.eventFilters,
    histories,
  );
}

/// Guardian events screen (`/g/events`) — unified list for all shell pets.
class GuardianDueEventsScreen extends ConsumerWidget {
  const GuardianDueEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petsAsync = ref.watch(petListProvider);

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (allPets) {
        final shellPets = PetListController().guardianShellPets(allPets);
        return GlobalEventsList(shellPets: shellPets);
      },
    );
  }
}

/// Unified global events list with manage-events filters plus pet/cohort filters.
class GlobalEventsList extends ConsumerStatefulWidget {
  const GlobalEventsList({super.key, required this.shellPets});

  final List<Pet> shellPets;

  @override
  ConsumerState<GlobalEventsList> createState() => _GlobalEventsListState();
}

class _GlobalEventsListState extends ConsumerState<GlobalEventsList> {
  GuardianGlobalEventsFilters _filters = const GuardianGlobalEventsFilters();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final historiesAsync = ref.watch(guardianGlobalEventHistoriesProvider);
    final scopedPets = guardianGlobalEventsPets(widget.shellPets, _filters);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
      data: (entries) {
        return historiesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text(l.errorWithMessage('$error'))),
          data: (histories) {
            final visible = filterGuardianGlobalEvents(
              entries,
              scopedPets,
              _filters,
              histories,
            );

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(healthEntriesNotifierProvider);
                ref.invalidate(guardianGlobalEventHistoriesProvider);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        l.eventsNavLabel,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GuardianGlobalEventsFilterBar(
                      shellPets: widget.shellPets,
                      filters: _filters,
                      onChanged: (filters) =>
                          setState(() => _filters = filters),
                    ),
                    ManageEventsFilterBar(
                      filters: _filters.eventFilters,
                      onChanged: (eventFilters) => setState(
                        () => _filters = _filters.copyWith(
                          eventFilters: eventFilters,
                        ),
                      ),
                    ),
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l.noEntriesYet,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = visible[index];
                          return EventListCard(
                            entry: entry,
                            history: histories[entry.id] ?? const [],
                            petId: entry.petId,
                          );
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Pet and cohort filter chips for the global guardian events list.
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
          _FilterChipRow(
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
            _FilterChipRow(
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

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.children});

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

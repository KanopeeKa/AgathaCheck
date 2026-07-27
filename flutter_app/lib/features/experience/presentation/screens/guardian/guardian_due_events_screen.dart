import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/domain/entities/health_history_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/guardian_add_event_picker_sheet.dart';
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
    this.cohort = GuardianEventsCohortFilter.all,
    this.petId,
  });

  final ManageEventsFilters eventFilters;
  final GuardianEventsCohortFilter cohort;
  final String? petId;

  GuardianGlobalEventsFilters copyWith({
    ManageEventsFilters? eventFilters,
    GuardianEventsCohortFilter? cohort,
    String? petId,
    bool clearPetId = false,
  }) {
    return GuardianGlobalEventsFilters(
      eventFilters: eventFilters ?? this.eventFilters,
      cohort: cohort ?? this.cohort,
      petId: clearPetId ? null : (petId ?? this.petId),
    );
  }
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
  switch (filters.cohort) {
    case GuardianEventsCohortFilter.all:
      break;
    case GuardianEventsCohortFilter.myPets:
      pets = pets.where((pet) => !pet.isFoster).toList();
    case GuardianEventsCohortFilter.fosterPets:
      pets = pets.where((pet) => pet.isFoster).toList();
  }
  if (filters.petId != null) {
    pets = pets.where((pet) => pet.id == filters.petId).toList();
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              l.eventsNavLabel,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => showGuardianAddEventPickerSheet(
                              context,
                              pets: widget.shellPets,
                            ),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l.addAnEvent),
                          ),
                        ],
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
                  selected: filters.petId == null,
                  onSelected: (_) =>
                      onChanged(filters.copyWith(clearPetId: true)),
                ),
                for (final pet in sortedPets)
                  FilterChip(
                    key: Key('global_events_pet_${pet.id}'),
                    label: Text(pet.name),
                    selected: filters.petId == pet.id,
                    onSelected: (_) =>
                        onChanged(filters.copyWith(petId: pet.id)),
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
      selected: filters.cohort == value,
      onSelected: (_) => onChanged(filters.copyWith(cohort: value)),
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

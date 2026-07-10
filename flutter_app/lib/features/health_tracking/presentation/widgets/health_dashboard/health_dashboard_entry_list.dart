import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../domain/entities/health_entry.dart';
import '../../providers/health_providers.dart';
import '../health_entry_card.dart';
import '../mark_complete_sheet.dart';
import '../health_dashboard_actions.dart' show GroupMode;

/// A single tab's grouped list of [HealthEntry] items.
///
/// Extracted from `health_dashboard_screen.dart`; keeps the loading/error/empty
/// states, grouping (by due date / pet / species), and the mark-taken / snooze /
/// undo actions for each entry card.
class HealthDashboardEntryList extends ConsumerWidget {
  const HealthDashboardEntryList({
    super.key,
    this.type,
    required this.groupMode,
    this.orgFilter,
  });

  final HealthEntryType? type;
  final GroupMode groupMode;
  final String? orgFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(filteredHealthEntriesProvider(type));
    final petsAsync = ref.watch(petListProvider);

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              semanticLabel: 'Error',
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text('Error loading entries:\n$error', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(healthEntriesNotifierProvider.notifier).refresh(),
              child: Text(l.retry),
            ),
          ],
        ),
      ),
      data: (allEntries) => petsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                semanticLabel: 'Error',
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text('Error loading pets:\n$error', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(petListProvider),
                child: Text(l.retry),
              ),
            ],
          ),
        ),
        data: (allPets) =>
            _buildEntryList(context, ref, l, allEntries, allPets),
      ),
    );
  }

  Widget _buildEntryList(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l,
    List<HealthEntry> allEntries,
    List<Pet> allPets,
  ) {
    final petMap = {for (final p in allPets) p.id: p};

    final filteredPetIds = orgFilter == null
        ? null
        : orgFilter == '_personal'
        ? allPets
              .where((p) => p.organizationId == null)
              .map((p) => p.id)
              .toSet()
        : allPets
              .where((p) => p.organizationName == orgFilter)
              .map((p) => p.id)
              .toSet();

    final entries = filteredPetIds == null
        ? allEntries
        : allEntries.where((e) => filteredPetIds.contains(e.petId)).toList();
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(
                Icons.list_alt,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              type == null
                  ? l.noEntriesYet
                  : l.noTypeEntriesYet(type!.label.toLowerCase()),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l.tapPlusToAdd,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    final groups = _buildGroups(context, entries, petMap);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(petListProvider);
        await Future.wait([
          ref.read(healthEntriesNotifierProvider.notifier).refresh(),
          ref.read(petListProvider.future),
        ]);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          if (group is _GroupHeader) {
            return _buildHeader(context, group.title);
          }
          final item = group as _GroupEntry;
          final isCareEvent = item.entry.type == HealthEntryType.familyEvent;
          final editRoute = isCareEvent
              ? '/pet/${item.entry.petId}/other/edit/${item.entry.id}'
              : '/health/edit/${item.entry.id}';
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: HealthEntryCard(
              entry: item.entry,
              pet: petMap[item.entry.petId],
              healthIssueName: item.entry.healthIssueName,
              onTap: () => context.go(editRoute),
              onMarkTaken: () => _markTaken(context, ref, item.entry),
              onSnooze: (days) => _snooze(context, ref, item.entry, days),
              onUndoComplete: () => _undoComplete(context, ref, item.entry),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  List<_GroupItem> _buildGroups(
    BuildContext context,
    List<HealthEntry> entries,
    Map<String, Pet> petMap,
  ) {
    switch (groupMode) {
      case GroupMode.dueDate:
        return _groupByDueDate(context, entries);
      case GroupMode.pet:
        return _groupByPet(entries, petMap);
      case GroupMode.petType:
        return _groupByPetType(entries, petMap);
    }
  }

  List<_GroupItem> _groupByDueDate(
    BuildContext context,
    List<HealthEntry> entries,
  ) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));

    final overdue = <HealthEntry>[];
    final todayList = <HealthEntry>[];
    final tomorrowList = <HealthEntry>[];
    final thisWeek = <HealthEntry>[];
    final later = <HealthEntry>[];
    final completed = <HealthEntry>[];

    for (final e in entries) {
      if (e.isCompleted) {
        completed.add(e);
      } else if (e.nextDueDate != null) {
        final due = DateTime(
          e.nextDueDate!.year,
          e.nextDueDate!.month,
          e.nextDueDate!.day,
        );
        if (due.isBefore(today)) {
          overdue.add(e);
        } else if (due.isAtSameMomentAs(today)) {
          todayList.add(e);
        } else if (due.isAtSameMomentAs(tomorrow)) {
          tomorrowList.add(e);
        } else if (due.isBefore(endOfWeek)) {
          thisWeek.add(e);
        } else {
          later.add(e);
        }
      }
    }

    final items = <_GroupItem>[];
    void addGroup(String title, List<HealthEntry> list) {
      if (list.isEmpty) return;
      items.add(_GroupHeader(title));
      items.addAll(list.map((e) => _GroupEntry(e)));
    }

    addGroup(l.overdue, overdue);
    addGroup(l.today, todayList);
    addGroup(l.tomorrow, tomorrowList);
    addGroup(l.thisWeek, thisWeek);
    addGroup(l.later, later);
    addGroup(l.completed, completed);

    return items;
  }

  List<_GroupItem> _groupByPet(
    List<HealthEntry> entries,
    Map<String, Pet> petMap,
  ) {
    final grouped = <String, List<HealthEntry>>{};
    for (final e in entries) {
      final petName = petMap[e.petId]?.name ?? e.petName ?? 'Unknown Pet';
      grouped.putIfAbsent(petName, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final items = <_GroupItem>[];
    for (final name in sortedKeys) {
      items.add(_GroupHeader(name));
      final sorted = grouped[name]!
        ..sort((a, b) {
          final ad = a.nextDueDate ?? DateTime(2100);
          final bd = b.nextDueDate ?? DateTime(2100);
          return ad.compareTo(bd);
        });
      items.addAll(sorted.map((e) => _GroupEntry(e)));
    }
    return items;
  }

  List<_GroupItem> _groupByPetType(
    List<HealthEntry> entries,
    Map<String, Pet> petMap,
  ) {
    final grouped = <String, List<HealthEntry>>{};
    for (final e in entries) {
      final species = petMap[e.petId]?.species ?? 'Other';
      grouped.putIfAbsent(species, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final items = <_GroupItem>[];
    for (final species in sortedKeys) {
      final pluralSpecies = species.endsWith('s') ? species : '${species}s';
      items.add(_GroupHeader(pluralSpecies));
      final sorted = grouped[species]!
        ..sort((a, b) {
          final ad = a.nextDueDate ?? DateTime(2100);
          final bd = b.nextDueDate ?? DateTime(2100);
          return ad.compareTo(bd);
        });
      items.addAll(sorted.map((e) => _GroupEntry(e)));
    }
    return items;
  }

  Future<void> _markTaken(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    final completedOn = await showMarkCompleteSheet(context);
    if (completedOn == null || !context.mounted) return;
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .markTaken(entry.id, completedOn: completedOn);
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.markedAsDone(entry.name))));
    }
  }

  Future<void> _undoComplete(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
  ) async {
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .undoComplete(entry.id);
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.undoCompleteDone(entry.name))));
    }
  }

  Future<void> _snooze(
    BuildContext context,
    WidgetRef ref,
    HealthEntry entry,
    int days,
  ) async {
    await ref
        .read(healthEntriesNotifierProvider.notifier)
        .snooze(entry.id, days);
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.snoozedForDays(entry.name, days, days == 1 ? l.day : l.days),
          ),
        ),
      );
    }
  }
}

sealed class _GroupItem {}

class _GroupHeader extends _GroupItem {
  final String title;
  _GroupHeader(this.title);
}

class _GroupEntry extends _GroupItem {
  final HealthEntry entry;
  _GroupEntry(this.entry);
}

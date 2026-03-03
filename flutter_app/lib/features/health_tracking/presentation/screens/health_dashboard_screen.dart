import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_card.dart';

enum _GroupMode { dueDate, pet, petType }

class HealthDashboardScreen extends ConsumerStatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  ConsumerState<HealthDashboardScreen> createState() =>
      _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  _GroupMode _groupMode = _GroupMode.dueDate;

  static const _tabs = [
    null,
    HealthEntryType.medication,
    HealthEntryType.preventive,
    HealthEntryType.vetVisit,
    HealthEntryType.procedure,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to home',
          onPressed: () => context.go('/'),
        ),
        actions: [
          PopupMenuButton<_GroupMode>(
            icon: const Icon(Icons.sort),
            tooltip: 'Group by',
            onSelected: (mode) => setState(() => _groupMode = mode),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _GroupMode.dueDate,
                child: ListTile(
                  leading: Icon(Icons.schedule,
                      color: _groupMode == _GroupMode.dueDate
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  title: const Text('By Due Date'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _GroupMode.pet,
                child: ListTile(
                  leading: Icon(Icons.pets,
                      color: _groupMode == _GroupMode.pet
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  title: const Text('By Pet'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _GroupMode.petType,
                child: ListTile(
                  leading: Icon(Icons.category,
                      color: _groupMode == _GroupMode.petType
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  title: const Text('By Species'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(key: Key('health_tab_all'), text: 'All'),
            Tab(key: Key('health_tab_medications'), text: 'Medications'),
            Tab(key: Key('health_tab_preventives'), text: 'Preventives'),
            Tab(key: Key('health_tab_vet_visits'), text: 'Vet Visits'),
            Tab(key: Key('health_tab_other'), text: 'Other'),
          ],
          isScrollable: false,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((type) => _EntryList(type: type, groupMode: _groupMode))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_health_entry_button'),
        tooltip: 'Add health entry',
        onPressed: () {
          final tabIndex = _tabController.index;
          final type = tabIndex < _tabs.length ? _tabs[tabIndex] : null;
          if (type != null) {
            context.go('/health/add?type=${type.name}');
          } else {
            context.go('/health/add');
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }

  Future<void> _exportCsv() async {
    try {
      final csv =
          await ref.read(healthRepositoryProvider).exportCsv();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('CSV Export'),
          content: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

class _EntryList extends ConsumerWidget {
  const _EntryList({this.type, required this.groupMode});

  final HealthEntryType? type;
  final _GroupMode groupMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(filteredHealthEntriesProvider(type));
    final petsAsync = ref.watch(petListProvider);

    final pets = petsAsync.valueOrNull ?? <Pet>[];
    final petMap = {for (final p in pets) p.id: p};

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                semanticLabel: 'Error',
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading entries:\n$error',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () =>
                  ref.read(healthEntriesNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            ExcludeSemantics(
              child: Icon(Icons.list_alt,
                    size: 64, color: Theme.of(context).colorScheme.outline),
            ),
                const SizedBox(height: 16),
                Text(
                  type == null
                      ? 'No entries yet'
                      : 'No ${type!.label.toLowerCase()} entries yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap + to add one',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          );
        }

        final groups = _buildGroups(entries, petMap);

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(healthEntriesNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              if (group is _GroupHeader) {
                return _buildHeader(context, group.title);
              }
              final item = group as _GroupEntry;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HealthEntryCard(
                  entry: item.entry,
                  pet: petMap[item.entry.petId],
                  healthIssueName: item.entry.healthIssueName,
                  onTap: () => context.go('/health/edit/${item.entry.id}'),
                  onMarkTaken: () => _markTaken(context, ref, item.entry),
                  onSnooze: (days) => _snooze(context, ref, item.entry, days),
                ),
              );
            },
          ),
        );
      },
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
      List<HealthEntry> entries, Map<String, Pet> petMap) {
    switch (groupMode) {
      case _GroupMode.dueDate:
        return _groupByDueDate(entries);
      case _GroupMode.pet:
        return _groupByPet(entries, petMap);
      case _GroupMode.petType:
        return _groupByPetType(entries, petMap);
    }
  }

  List<_GroupItem> _groupByDueDate(List<HealthEntry> entries) {
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
      } else {
        final due = DateTime(e.nextDueDate.year, e.nextDueDate.month, e.nextDueDate.day);
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

    addGroup('Overdue', overdue);
    addGroup('Today', todayList);
    addGroup('Tomorrow', tomorrowList);
    addGroup('This Week', thisWeek);
    addGroup('Later', later);
    addGroup('Completed', completed);

    return items;
  }

  List<_GroupItem> _groupByPet(
      List<HealthEntry> entries, Map<String, Pet> petMap) {
    final grouped = <String, List<HealthEntry>>{};
    for (final e in entries) {
      final petName = petMap[e.petId]?.name ?? 'Unknown Pet';
      grouped.putIfAbsent(petName, () => []).add(e);
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final items = <_GroupItem>[];
    for (final name in sortedKeys) {
      items.add(_GroupHeader(name));
      final sorted = grouped[name]!..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      items.addAll(sorted.map((e) => _GroupEntry(e)));
    }
    return items;
  }

  List<_GroupItem> _groupByPetType(
      List<HealthEntry> entries, Map<String, Pet> petMap) {
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
      final sorted = grouped[species]!..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      items.addAll(sorted.map((e) => _GroupEntry(e)));
    }
    return items;
  }

  Future<void> _markTaken(BuildContext context, WidgetRef ref, HealthEntry entry) async {
    await ref.read(healthEntriesNotifierProvider.notifier).markTaken(entry.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.name} marked as done')),
      );
    }
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref, HealthEntry entry, int days) async {
    await ref.read(healthEntriesNotifierProvider.notifier).snooze(entry.id, days);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${entry.name} snoozed for $days ${days == 1 ? 'day' : 'days'}')),
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

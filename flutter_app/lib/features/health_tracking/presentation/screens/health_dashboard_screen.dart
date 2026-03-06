import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/app_logo_title.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../../pet_profile/data/services/pdf_saver.dart' as pdf_saver;
import '../../data/services/events_pdf_service.dart';
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
  String? _orgFilter;

  static const _tabs = [
    null,
    HealthEntryType.medication,
    HealthEntryType.preventive,
    HealthEntryType.vetVisit,
    HealthEntryType.procedure,
    HealthEntryType.familyEvent,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: AppLogoTitle(title: l.events),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: l.goBack,
          onPressed: () => context.go('/'),
        ),
        actions: [
          PopupMenuButton<_GroupMode>(
            icon: const Icon(Icons.sort),
            tooltip: l.groupBy,
            onSelected: (mode) => setState(() => _groupMode = mode),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _GroupMode.dueDate,
                child: ListTile(
                  leading: Icon(Icons.schedule,
                      color: _groupMode == _GroupMode.dueDate
                          ? Theme.of(context).colorScheme.primary
                          : null),
                  title: Text(l.byDueDate),
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
                  title: Text(l.byPet),
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
                  title: Text(l.bySpecies),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: l.exportPdf,
            onPressed: _exportPdf,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: l.exportCsv,
            onPressed: _exportCsv,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(key: const Key('health_tab_all'), text: l.all),
            Tab(key: const Key('health_tab_medications'), text: l.medications),
            Tab(key: const Key('health_tab_preventives'), text: l.preventives),
            Tab(key: const Key('health_tab_vet_visits'), text: l.vetVisits),
            Tab(key: const Key('health_tab_other'), text: l.other),
            Tab(key: const Key('health_tab_family'), text: l.familyEvents),
          ],
          isScrollable: true,
        ),
      ),
      body: Column(
        children: [
          Consumer(builder: (context, ref, _) {
            final allPetsAsync = ref.watch(allPetsIncludingOrgProvider);
            final pets = allPetsAsync.valueOrNull ?? [];
            final orgNames = pets
                .where((p) => p.organizationName != null)
                .map((p) => p.organizationName!)
                .toSet()
                .toList()
              ..sort();
            if (orgNames.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l.allPets),
                      selected: _orgFilter == null,
                      onSelected: (_) => setState(() => _orgFilter = null),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l.myPets),
                      selected: _orgFilter == '_personal',
                      onSelected: (_) => setState(() => _orgFilter = '_personal'),
                    ),
                    ...orgNames.map((name) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        avatar: const Icon(Icons.business, size: 16),
                        label: Text(name),
                        selected: _orgFilter == name,
                        onSelected: (_) => setState(() => _orgFilter = name),
                      ),
                    )),
                  ],
                ),
              ),
            );
          }),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs
                  .map((type) => _EntryList(type: type, groupMode: _groupMode, orgFilter: _orgFilter))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_health_entry_button'),
        tooltip: l.addHealthEntry,
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
        label: Text(l.addEntry),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final l = AppLocalizations.of(context)!;
    try {
      final csv =
          await ref.read(healthRepositoryProvider).exportCsv();
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l.csvExport),
          content: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontSize: 12)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.close),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.exportFailed(e.toString()))),
      );
    }
  }

  Future<void> _exportPdf() async {
    final l = AppLocalizations.of(context)!;
    try {
      final tabIndex = _tabController.index;
      final typeFilter = tabIndex < _tabs.length ? _tabs[tabIndex] : null;

      final entriesAsync = ref.read(filteredHealthEntriesProvider(typeFilter));
      final petsAsync = ref.read(allPetsIncludingOrgProvider);
      var entries = entriesAsync.valueOrNull ?? [];
      final pets = petsAsync.valueOrNull ?? <Pet>[];
      final petMap = {for (final p in pets) p.id: p};

      if (_orgFilter != null) {
        final filteredPetIds = _orgFilter == '_personal'
            ? pets.where((p) => p.organizationId == null).map((p) => p.id).toSet()
            : pets.where((p) => p.organizationName == _orgFilter).map((p) => p.id).toSet();
        entries = entries.where((e) => filteredPetIds.contains(e.petId)).toList();
      }

      final groups = _buildPdfGroups(entries, petMap, _groupMode);

      final filterLabel = typeFilter == null ? l.all : typeFilter.label;
      final groupLabel = switch (_groupMode) {
        _GroupMode.dueDate => l.byDueDate,
        _GroupMode.pet => l.byPet,
        _GroupMode.petType => l.bySpecies,
      };

      final bytes = await EventsPdfService().generate(
        groups: groups,
        petMap: petMap,
        filterLabel: filterLabel,
        groupLabel: groupLabel,
        l: l,
      );

      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      await pdf_saver.savePdf(bytes, 'Events_${dateStr}.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.pdfExportFailed(e.toString()))),
      );
    }
  }

  List<MapEntry<String?, List<HealthEntry>>> _buildPdfGroups(
      List<HealthEntry> entries, Map<String, Pet> petMap, _GroupMode mode) {
    switch (mode) {
      case _GroupMode.dueDate:
        return _pdfGroupByDueDate(entries);
      case _GroupMode.pet:
        return _pdfGroupByPet(entries, petMap);
      case _GroupMode.petType:
        return _pdfGroupByPetType(entries, petMap);
    }
  }

  List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByDueDate(
      List<HealthEntry> entries) {
    final l = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(const Duration(days: 7));

    final buckets = <String, List<HealthEntry>>{
      l.overdue: [],
      l.today: [],
      l.tomorrow: [],
      l.thisWeek: [],
      l.later: [],
      l.completed: [],
    };

    for (final e in entries) {
      if (e.isCompleted) {
        buckets[l.completed]!.add(e);
      } else {
        final due = DateTime(e.nextDueDate.year, e.nextDueDate.month, e.nextDueDate.day);
        if (due.isBefore(today)) {
          buckets[l.overdue]!.add(e);
        } else if (due.isAtSameMomentAs(today)) {
          buckets[l.today]!.add(e);
        } else if (due.isAtSameMomentAs(tomorrow)) {
          buckets[l.tomorrow]!.add(e);
        } else if (due.isBefore(endOfWeek)) {
          buckets[l.thisWeek]!.add(e);
        } else {
          buckets[l.later]!.add(e);
        }
      }
    }

    final result = <MapEntry<String?, List<HealthEntry>>>[];
    for (final key in [l.overdue, l.today, l.tomorrow, l.thisWeek, l.later, l.completed]) {
      if (buckets[key]!.isNotEmpty) {
        result.add(MapEntry(key, buckets[key]!));
      }
    }
    return result;
  }

  List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByPet(
      List<HealthEntry> entries, Map<String, Pet> petMap) {
    final grouped = <String, List<HealthEntry>>{};
    for (final e in entries) {
      final petName = petMap[e.petId]?.name ?? 'Unknown Pet';
      grouped.putIfAbsent(petName, () => []).add(e);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((name) {
      final sorted = grouped[name]!..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return MapEntry<String?, List<HealthEntry>>(name, sorted);
    }).toList();
  }

  List<MapEntry<String?, List<HealthEntry>>> _pdfGroupByPetType(
      List<HealthEntry> entries, Map<String, Pet> petMap) {
    final grouped = <String, List<HealthEntry>>{};
    for (final e in entries) {
      final species = petMap[e.petId]?.species ?? 'Other';
      grouped.putIfAbsent(species, () => []).add(e);
    }
    final sortedKeys = grouped.keys.toList()..sort();
    return sortedKeys.map((species) {
      final label = species.endsWith('s') ? species : '${species}s';
      final sorted = grouped[species]!..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return MapEntry<String?, List<HealthEntry>>(label, sorted);
    }).toList();
  }
}

class _EntryList extends ConsumerWidget {
  const _EntryList({this.type, required this.groupMode, this.orgFilter});

  final HealthEntryType? type;
  final _GroupMode groupMode;
  final String? orgFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(filteredHealthEntriesProvider(type));
    final petsAsync = ref.watch(allPetsIncludingOrgProvider);

    final allPets = petsAsync.valueOrNull ?? <Pet>[];
    final petMap = {for (final p in allPets) p.id: p};

    final filteredPetIds = orgFilter == null
        ? null
        : orgFilter == '_personal'
            ? allPets.where((p) => p.organizationId == null).map((p) => p.id).toSet()
            : allPets.where((p) => p.organizationName == orgFilter).map((p) => p.id).toSet();

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
              child: Text(l.retry),
            ),
          ],
        ),
      ),
      data: (allEntries) {
        final entries = filteredPetIds == null
            ? allEntries
            : allEntries.where((e) => filteredPetIds.contains(e.petId)).toList();
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
                      ? l.noEntriesYet
                      : l.noTypeEntriesYet(type!.label.toLowerCase()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l.tapPlusToAdd,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                ),
              ],
            ),
          );
        }

        final groups = _buildGroups(context, entries, petMap);

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
              final isFamilyEvent = item.entry.type == HealthEntryType.familyEvent;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HealthEntryCard(
                  entry: item.entry,
                  pet: petMap[item.entry.petId],
                  healthIssueName: item.entry.healthIssueName,
                  onTap: isFamilyEvent
                      ? () => context.go('/pet/${item.entry.petId}')
                      : () => context.go('/health/edit/${item.entry.id}'),
                  onMarkTaken: isFamilyEvent ? null : () => _markTaken(context, ref, item.entry),
                  onSnooze: isFamilyEvent ? null : (days) => _snooze(context, ref, item.entry, days),
                  onUndoComplete: isFamilyEvent ? null : () => _undoComplete(context, ref, item.entry),
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
      BuildContext context, List<HealthEntry> entries, Map<String, Pet> petMap) {
    switch (groupMode) {
      case _GroupMode.dueDate:
        return _groupByDueDate(context, entries);
      case _GroupMode.pet:
        return _groupByPet(entries, petMap);
      case _GroupMode.petType:
        return _groupByPetType(entries, petMap);
    }
  }

  List<_GroupItem> _groupByDueDate(BuildContext context, List<HealthEntry> entries) {
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

    addGroup(l.overdue, overdue);
    addGroup(l.today, todayList);
    addGroup(l.tomorrow, tomorrowList);
    addGroup(l.thisWeek, thisWeek);
    addGroup(l.later, later);
    addGroup(l.completed, completed);

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
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.markedAsDone(entry.name))),
      );
    }
  }

  Future<void> _undoComplete(BuildContext context, WidgetRef ref, HealthEntry entry) async {
    await ref.read(healthEntriesNotifierProvider.notifier).undoComplete(entry.id);
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.undoCompleteDone(entry.name))),
      );
    }
  }

  Future<void> _snooze(BuildContext context, WidgetRef ref, HealthEntry entry, int days) async {
    await ref.read(healthEntriesNotifierProvider.notifier).snooze(entry.id, days);
    if (context.mounted) {
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.snoozedForDays(entry.name, days, days == 1 ? l.day : l.days))),
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

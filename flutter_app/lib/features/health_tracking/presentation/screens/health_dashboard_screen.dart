import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_card.dart';

/// Dashboard screen displaying health entries organized by type tabs.
///
/// Shows tabs for All, Medications, Preventives, Vet Visits, and Other
/// with a floating action button to add new entries.
class HealthDashboardScreen extends ConsumerStatefulWidget {
  /// Creates the [HealthDashboardScreen].
  const HealthDashboardScreen({super.key});

  @override
  ConsumerState<HealthDashboardScreen> createState() =>
      _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        children: _tabs.map((type) => _EntryList(type: type)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('add_health_entry_button'),
        tooltip: 'Add health entry',
        onPressed: () => context.go('/health/add'),
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
  const _EntryList({this.type});

  final HealthEntryType? type;

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

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(healthEntriesNotifierProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              final pet = petMap[entry.petId];
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: HealthEntryCard(
                  entry: entry,
                  pet: pet,
                  healthIssueName: entry.healthIssueName,
                  onTap: () => context.go('/health/edit/${entry.id}'),
                  onMarkTaken: () => _markTaken(context, ref, entry),
                  onSnooze: (days) => _snooze(context, ref, entry, days),
                ),
              );
            },
          ),
        );
      },
    );
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

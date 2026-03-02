import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/health_entry.dart';
import '../providers/health_providers.dart';
import '../widgets/health_entry_card.dart';

/// Dashboard screen displaying health entries organized by type tabs.
///
/// Shows tabs for All, Medications, Preventives, and Vaccines
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
    HealthEntryType.vaccine,
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
        title: const Text('Health Tracking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
            Tab(text: 'All'),
            Tab(text: 'Medications'),
            Tab(text: 'Preventives'),
            Tab(text: 'Vaccines'),
            Tab(text: 'Procedures'),
          ],
          isScrollable: false,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((type) => _EntryList(type: type)).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
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

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
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
                Icon(Icons.list_alt,
                    size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  type == null
                      ? 'No health entries yet'
                      : 'No ${type!.label.toLowerCase()}s yet',
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
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HealthEntryCard(
                  entry: entry,
                  onTap: () => context.go('/health/edit/${entry.id}'),
                  onMarkTaken: () => _markTaken(context, ref, entry),
                  onDelete: () => ref
                      .read(healthEntriesNotifierProvider.notifier)
                      .delete(entry.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _markTaken(BuildContext context, WidgetRef ref, HealthEntry entry) {
    ref.read(healthEntriesNotifierProvider.notifier).markTaken(entry.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.name} marked as taken')),
    );
  }
}

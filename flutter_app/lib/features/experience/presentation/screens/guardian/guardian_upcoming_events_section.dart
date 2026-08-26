import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/mobile_due_event_row.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../widgets/guardian_illustrated_empty_state.dart';
import 'guardian_dashboard_helpers.dart';

/// A due entry that has been optimistically marked complete on the compact
/// Care preview, retained at [previewIndex] through the real server refresh so
/// its approved completed presentation stays visible in place.
class _OptimisticCompletion {
  const _OptimisticCompletion({
    required this.entry,
    required this.previewIndex,
  });

  /// The entry snapshot captured when the user confirmed completion.
  final HealthEntry entry;

  /// The index this item held in its Care preview at completion.
  final int previewIndex;
}

/// Guardian Care dashboard preview with one combined, date-ordered list.
///
/// Each preview entry is rendered as a [MobileDueEventRow] with a calm,
/// touch-safe completion affordance.
///
/// This widget owns list-level optimistic completion state: after the user
/// confirms completion in the mark-complete sheet, the entry is retained in
/// [_completed] at its original preview index and rendered as completed even
/// after the authoritative due list excludes it. The server remains authoritative —
/// optimistic entries are only removed when the user taps Undo (after
/// [HealthEntriesNotifier.undoComplete] succeeds).
///
/// During a transient [AsyncLoading] state on compact mobile widths the widget
/// renders the merged preview from [_lastDueEntriesSnapshot] (the most recently
/// received due-entry list) so the optimistically-completed row remains visible
/// rather than being replaced by a spinner. The snapshot is only used for this
/// in-flight loading presentation; it is replaced on every [AsyncData] update.
/// A compact progress indicator keeps cached refresh visibly distinct from
/// settled data.
///
class GuardianUpcomingEventsSection extends ConsumerStatefulWidget {
  const GuardianUpcomingEventsSection({
    super.key,
    required this.pets,
    this.onAddEvent,
  });

  final List<Pet> pets;
  final VoidCallback? onAddEvent;

  static const previewLimit = 5;

  @override
  ConsumerState<GuardianUpcomingEventsSection> createState() =>
      _GuardianUpcomingEventsSectionState();
}

class _GuardianUpcomingEventsSectionState
    extends ConsumerState<GuardianUpcomingEventsSection> {
  /// Optimistically-completed entries, keyed by entry id, insertion-ordered.
  final Map<String, _OptimisticCompletion> _completed = {};

  /// The most recently received due-entry list from the Guardian Today
  /// presentation priorities.
  ///
  /// Cached so that, on compact mobile widths, a transient [AsyncLoading] state
  /// (emitted by [HealthEntriesNotifier.markTaken] / [undoComplete] before the
  /// real server result arrives) renders the merged optimistic preview from this
  /// snapshot instead of replacing the list with a spinner.
  ///
  /// Updated on every [AsyncData] frame. Never written from optimistic state.
  List<HealthEntry> _lastDueEntriesSnapshot = const [];

  Future<void> _onMarkDone(HealthEntry entry, int previewIndex) async {
    final result = await HomeEventActions.showCompletionSheet(context);
    if (result == null || !mounted) return;

    // Retain an optimistic completed version at its current preview index so it
    // stays visible in place through the authoritative server refresh.
    setState(() {
      _completed[entry.id] = _OptimisticCompletion(
        entry: entry,
        previewIndex: previewIndex,
      );
    });

    try {
      await HomeEventActions.commitCompletion(context, ref, entry, result);
      // Server refresh removes the entry from the due list; the merge in
      // [build] keeps rendering it as completed until Undo.
    } catch (_) {
      if (!mounted) return;
      setState(() => _completed.remove(entry.id));
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }

  Future<void> _onUndo(HealthEntry entry) async {
    await HomeEventActions.undoCompletion(context, ref, entry);
    if (!mounted) return;
    // Only drop the optimistic completed row once undoComplete has succeeded;
    // the normal due row is restored by the subsequent server refresh.
    setState(() => _completed.remove(entry.id));
  }

  /// Builds the ordered Care preview by merging fresh entries
  /// with retained optimistic-completed items at their original indices.
  ///
  /// Completed items keep their captured [previewIndex]; remaining entries
  /// (excluding any still present that are already tracked as completed) fill
  /// the other slots in order. Total is capped at [previewLimit].
  List<_PreviewItem> _buildMobilePreview(List<HealthEntry> dueEntries) {
    final completedItems = _completed.values.toList()
      ..sort((a, b) => a.previewIndex.compareTo(b.previewIndex));
    final completedIds = completedItems.map((item) => item.entry.id).toSet();

    // Fresh entries that are not currently tracked as optimistically completed
    // in this tab, in server order.
    final freshDue = dueEntries
        .where((e) => !completedIds.contains(e.id))
        .toList();

    final result = <_PreviewItem?>[];

    // Place completed items at their captured indices first.
    for (final c in completedItems) {
      final index = c.previewIndex
          .clamp(0, GuardianUpcomingEventsSection.previewLimit - 1)
          .toInt();
      while (result.length <= index) {
        result.add(null);
      }
      // If the slot is already taken (two completions captured the same index
      // as the list shifted), append at the next free slot instead.
      if (result[index] == null) {
        result[index] = _PreviewItem.completed(c.entry);
      } else {
        result.add(_PreviewItem.completed(c.entry));
      }
    }

    // Fill remaining null slots (and then append) with fresh due entries.
    final dueQueue = List<HealthEntry>.from(freshDue);
    for (var i = 0; i < result.length && dueQueue.isNotEmpty; i++) {
      if (result[i] == null) {
        result[i] = _PreviewItem.due(dueQueue.removeAt(0));
      }
    }
    while (dueQueue.isNotEmpty &&
        result.length < GuardianUpcomingEventsSection.previewLimit) {
      result.add(_PreviewItem.due(dueQueue.removeAt(0)));
    }

    // Compact out any residual nulls and cap at the preview limit.
    final compacted = result.whereType<_PreviewItem>().toList();
    if (compacted.length > GuardianUpcomingEventsSection.previewLimit) {
      return compacted.sublist(0, GuardianUpcomingEventsSection.previewLimit);
    }
    return compacted;
  }

  Widget _buildMobileContent(
    BuildContext ctx,
    List<HealthEntry> dueEntries,
    Map<String, Pet> petMap,
    AppLocalizations l,
    String emptyMessage,
    bool hasAnyCare,
  ) {
    final items = _buildMobilePreview(dueEntries);
    if (items.isEmpty) {
      if (!hasAnyCare) {
        return GuardianIllustratedEmptyState(
          key: const Key('guardian_dashboard_empty_care'),
          assetPath: 'assets/dashboard/guardian-empty-care.png',
          title: l.guardianEmptyCareTitle,
          body: l.guardianEmptyCareBody,
          actionLabel: l.addAnEvent,
          actionKey: const Key('guardian_dashboard_empty_care_action'),
          onAction: widget.onAddEvent,
        );
      }
      return GuardianIllustratedEmptyState(
        key: const Key('guardian_dashboard_empty_care_clear'),
        title: l.guardianEmptyCareClearTitle,
        body: emptyMessage,
        actionLabel: l.viewAll,
        actionIcon: Icons.calendar_month_outlined,
        onAction: () => context.go('/g/events'),
      );
    }
    return _MobileDueEventList(
      items: items,
      petMap: petMap,
      onMarkDone: _onMarkDone,
      onUndo: _onUndo,
      onOpen: (entry) => HomeEventActions.openEntry(context, entry),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final pets = widget.pets;

    return Semantics(
      container: true,
      label: l.careEyebrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.careEyebrow,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColorTokens.guardianActive,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (entriesAsync is AsyncData<List<HealthEntry>>)
            _careData(context, entriesAsync.value, pets, l)
          else if (entriesAsync is AsyncLoading)
            _careLoading(context, pets, l)
          else
            _careError(context, ref, l),
        ],
      ),
    );
  }

  Widget _careData(
    BuildContext context,
    List<HealthEntry> entries,
    List<Pet> pets,
    AppLocalizations l,
  ) {
    final priorities = GuardianTodayCarePriorities.forPets(
      entries: entries,
      pets: pets,
      now: DateTime.now(),
    );
    _lastDueEntriesSnapshot = priorities.all;
    return _careContent(context, priorities, pets, l);
  }

  Widget _careLoading(
    BuildContext context,
    List<Pet> pets,
    AppLocalizations l,
  ) {
    if (_lastDueEntriesSnapshot.isEmpty && _completed.isEmpty) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final priorities = GuardianTodayCarePriorities.forPets(
      entries: _lastDueEntriesSnapshot,
      pets: pets,
      now: DateTime.now(),
    );
    return Column(
      children: [
        _careContent(context, priorities, pets, l),
        const SizedBox(height: 8),
        const SizedBox(
          key: Key('guardian_due_events_refreshing'),
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _careContent(
    BuildContext context,
    GuardianTodayCarePriorities priorities,
    List<Pet> pets,
    AppLocalizations l,
  ) {
    final careEntries = priorities.all;
    final petMap = {for (final pet in pets) pet.id: pet};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildMobileContent(
          context,
          careEntries,
          petMap,
          l,
          l.noCareDue,
          priorities.all.isNotEmpty,
        ),
        if (careEntries.length > GuardianUpcomingEventsSection.previewLimit)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: const Key('guardian_dashboard_care_view_all'),
              onPressed: () => context.go('/g/events'),
              child: Text(l.viewAll),
            ),
          ),
      ],
    );
  }

  Widget _careError(BuildContext context, WidgetRef ref, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, color: AppColorTokens.danger),
        const SizedBox(height: 8),
        Text(l.careLoadError),
        TextButton.icon(
          onPressed: () =>
              ref.read(healthEntriesNotifierProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh, size: 18),
          label: Text(l.retry),
        ),
      ],
    );
  }
}

/// A single item in the merged mobile preview: either a due entry or an
/// optimistically-completed entry.
class _PreviewItem {
  const _PreviewItem._(this.entry, this.isCompleted);

  factory _PreviewItem.due(HealthEntry entry) => _PreviewItem._(entry, false);
  factory _PreviewItem.completed(HealthEntry entry) =>
      _PreviewItem._(entry, true);

  final HealthEntry entry;
  final bool isCompleted;
}

/// Internal widget: renders merged preview items as [MobileDueEventRow] items.
class _MobileDueEventList extends StatelessWidget {
  const _MobileDueEventList({
    required this.items,
    required this.petMap,
    required this.onMarkDone,
    required this.onUndo,
    required this.onOpen,
  });

  final List<_PreviewItem> items;
  final Map<String, Pet> petMap;
  final void Function(HealthEntry entry, int previewIndex) onMarkDone;
  final void Function(HealthEntry entry) onUndo;
  final void Function(HealthEntry entry) onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('mobile_due_event_list'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          MobileDueEventRow(
            key: Key('mobile_due_row_${items[i].entry.id}'),
            entry: items[i].entry,
            pet: petMap[items[i].entry.petId],
            isCompleted: items[i].isCompleted,
            onMarkDone: () => onMarkDone(items[i].entry, i),
            onUndo: () => onUndo(items[i].entry),
            onOpen: () => onOpen(items[i].entry),
          ),
      ],
    );
  }
}

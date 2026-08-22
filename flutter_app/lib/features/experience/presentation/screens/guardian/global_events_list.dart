import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/domain/entities/health_history_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/mobile_due_event_row.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/screens/widgets/pet_event_entry_list.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import 'desktop_care_row.dart';
import 'guardian_due_events_screen.dart';

// ---------------------------------------------------------------------------
// Optimistic-completion model
// ---------------------------------------------------------------------------

/// An entry retained optimistically after the server removes it, anchored at
/// [originalIndex] until the user taps Undo.
///
/// [entry] is the original pre-completion data — kept intact so Undo can
/// restore it. [filterEntry] is a synthetic post-completion copy used only
/// for filter evaluation, so status filters see a correct completed state:
///
/// * One-time series: `completedOn` set → `isHealthEntrySeriesClosed = true`
///   → matches "Closed", excluded by "Open" / "Due/Overdue".
/// * Recurring series: `nextDueDate` moved to far future → series stays open,
///   not due/overdue → matches "Open", excluded by "Closed" / "Due/Overdue".
class _OptimisticCompletion {
  _OptimisticCompletion({required this.entry, required this.originalIndex})
    : filterEntry = _makeFilterEntry(entry);

  final HealthEntry entry;
  final int originalIndex;

  /// Synthetic post-completion entry used only for filter evaluation.
  final HealthEntry filterEntry;

  static HealthEntry _makeFilterEntry(HealthEntry e) {
    if (e.frequency == HealthFrequency.once) {
      // One-time: mark as completed so the series is considered closed.
      return e.copyWith(completedOn: e.completedOn ?? DateTime.now());
    }
    // Recurring: advance next-due to far future; series stays open but is
    // no longer due/overdue for the current occurrence.
    return e.copyWith(nextDueDate: DateTime(9999, 12, 31));
  }
}

class _CareItem {
  const _CareItem._(this.entry, this.isCompleted);

  factory _CareItem.due(HealthEntry entry) => _CareItem._(entry, false);
  factory _CareItem.completed(HealthEntry entry) => _CareItem._(entry, true);

  final HealthEntry entry;
  final bool isCompleted;
}

// ---------------------------------------------------------------------------
// GlobalEventsList
// ---------------------------------------------------------------------------

/// Unified global events list with manage-events filters plus pet/cohort filters.
///
/// Both compact (<[_mobileBreakpoint]dp) and wide layouts expose the same
/// optimistic completion/undo flow so care actions are available on every
/// device. Server ordering authority is preserved — no second ordering model
/// is introduced.
class GlobalEventsList extends ConsumerStatefulWidget {
  const GlobalEventsList({super.key, required this.shellPets});

  final List<Pet> shellPets;

  static const _mobileBreakpoint = 600.0;

  @override
  ConsumerState<GlobalEventsList> createState() => _GlobalEventsListState();
}

class _GlobalEventsListState extends ConsumerState<GlobalEventsList> {
  GuardianGlobalEventsFilters _filters = const GuardianGlobalEventsFilters();
  final Map<String, _OptimisticCompletion> _completed = {};

  // ---- completion callbacks ------------------------------------------------

  Future<void> _onMarkDone(HealthEntry entry, int index) async {
    final result = await HomeEventActions.showCompletionSheet(context);
    if (result == null || !mounted) return;

    setState(() {
      _completed[entry.id] = _OptimisticCompletion(
        entry: entry,
        originalIndex: index,
      );
    });

    try {
      await HomeEventActions.commitCompletion(context, ref, entry, result);
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
    try {
      await HomeEventActions.undoCompletion(context, ref, entry);
    } catch (_) {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.undoCompleteFailed)));
      return;
    }
    if (!mounted) return;
    setState(() => _completed.remove(entry.id));
  }

  // ---- merged list ---------------------------------------------------------

  /// Merges fresh server entries with retained optimistic-completed items,
  /// keeping each completed entry at its captured index. No cap applied.
  ///
  /// Completed items are only reinserted when [filterGuardianGlobalEvents]
  /// would include them under the currently active cohort/pet/event filters —
  /// preventing ghost rows when the user narrows the filter after completing.
  List<_CareItem> _buildMergedList(
    List<HealthEntry> freshEntries,
    List<Pet> scopedPets,
    GuardianGlobalEventsFilters filters,
    Map<String, List<HealthHistoryEntry>> histories,
  ) {
    final fresh = freshEntries
        .where((e) => !_completed.containsKey(e.id))
        .toList();

    // Only retain completed items that pass the current filters.
    // filterEntry is a synthetic post-completion copy so status filters
    // (Open / Closed / Due+Overdue) evaluate the correct completed state
    // rather than the original pre-completion data.
    final visibleCompleted = _completed.values.where((c) {
      final passes = filterGuardianGlobalEvents(
        [c.filterEntry],
        scopedPets,
        filters,
        histories,
      );
      return passes.isNotEmpty;
    }).toList()..sort((a, b) => a.originalIndex.compareTo(b.originalIndex));

    final result = <_CareItem?>[];

    for (final c in visibleCompleted) {
      final idx = c.originalIndex.clamp(0, result.length);
      while (result.length <= idx) {
        result.add(null);
      }
      if (result[idx] == null) {
        result[idx] = _CareItem.completed(c.entry);
      } else {
        result.add(_CareItem.completed(c.entry));
      }
    }

    final queue = List<HealthEntry>.from(fresh);
    for (var i = 0; i < result.length && queue.isNotEmpty; i++) {
      if (result[i] == null) result[i] = _CareItem.due(queue.removeAt(0));
    }
    while (queue.isNotEmpty) {
      result.add(_CareItem.due(queue.removeAt(0)));
    }

    return result.whereType<_CareItem>().toList();
  }

  void _invalidateBoth() {
    ref.invalidate(healthEntriesNotifierProvider);
    ref.invalidate(guardianGlobalEventHistoriesProvider);
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final historiesAsync = ref.watch(guardianGlobalEventHistoriesProvider);
    final scopedPets = guardianGlobalEventsPets(widget.shellPets, _filters);

    return _OperationsDeskTheme(
      child: ColoredBox(
        color: AppColorTokens.operationsDeskCanvas,
        child: RefreshIndicator(
          onRefresh: () async => _invalidateBoth(),
          child: SingleChildScrollView(
            key: const Key('global_events_scroll'),
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
                  onChanged: (f) => setState(() => _filters = f),
                ),
                ManageEventsFilterBar(
                  filters: _filters.eventFilters,
                  onChanged: (ef) => setState(
                    () => _filters = _filters.copyWith(eventFilters: ef),
                  ),
                ),
                _buildBody(l, entriesAsync, historiesAsync, scopedPets),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    AppLocalizations l,
    AsyncValue<List<HealthEntry>> entriesAsync,
    AsyncValue<Map<String, List<HealthHistoryEntry>>> historiesAsync,
    List<Pet> scopedPets,
  ) {
    if (entriesAsync is AsyncError || historiesAsync is AsyncError) {
      return _ErrorRetryView(
        message: l.careLoadError,
        onRetry: _invalidateBoth,
      );
    }

    if (entriesAsync is AsyncLoading || historiesAsync is AsyncLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final entries = entriesAsync.valueOrNull ?? [];
    final histories = historiesAsync.valueOrNull ?? {};
    final visible = filterGuardianGlobalEvents(
      entries,
      scopedPets,
      _filters,
      histories,
    );
    final items = _buildMergedList(visible, scopedPets, _filters, histories);
    final petMap = {for (final p in widget.shellPets) p.id: p};

    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (items.isEmpty) return _EmptyState(label: l.noEntriesYet);
        final useMobile =
            constraints.maxWidth < GlobalEventsList._mobileBreakpoint;
        return useMobile
            ? _buildMobileList(ctx, items, petMap)
            : _buildDesktopList(ctx, items, petMap);
      },
    );
  }

  // ---- mobile --------------------------------------------------------------

  Widget _buildMobileList(
    BuildContext ctx,
    List<_CareItem> items,
    Map<String, Pet> petMap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        key: const Key('global_events_mobile_list'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++)
            MobileDueEventRow(
              key: Key('global_events_mobile_row_${items[i].entry.id}'),
              entry: items[i].entry,
              pet: petMap[items[i].entry.petId],
              isCompleted: items[i].isCompleted,
              onMarkDone: () => _onMarkDone(items[i].entry, i),
              onUndo: () => _onUndo(items[i].entry),
              onOpen: () => _openEntry(ctx, items[i].entry),
            ),
        ],
      ),
    );
  }

  // ---- desktop -------------------------------------------------------------

  Widget _buildDesktopList(
    BuildContext ctx,
    List<_CareItem> items,
    Map<String, Pet> petMap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        key: const Key('global_events_desktop_list'),
        children: [
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DesktopCareRow(
                key: Key('global_events_desktop_row_${items[i].entry.id}'),
                entry: items[i].entry,
                pet: petMap[items[i].entry.petId],
                isCompleted: items[i].isCompleted,
                onMarkDone: () => _onMarkDone(items[i].entry, i),
                onUndo: () => _onUndo(items[i].entry),
                onOpen: () => _openEntry(ctx, items[i].entry),
              ),
            ),
        ],
      ),
    );
  }

  void _openEntry(BuildContext context, HealthEntry entry) {
    if (entry.petId.isEmpty) return;
    context.go('/pet/${entry.petId}/events/${entry.id}');
  }
}

// ---------------------------------------------------------------------------
// Shared presentation helpers
// ---------------------------------------------------------------------------

/// Operations Desk colour theme wrapper — same tokens as the home content.
class _OperationsDeskTheme extends StatelessWidget {
  const _OperationsDeskTheme({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final desk = base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColorTokens.guardianCarePrimary,
        onPrimary: AppColorTokens.inverse,
        primaryContainer: AppColorTokens.operationsPaper,
        onPrimaryContainer: AppColorTokens.guardianCareActive,
        surface: AppColorTokens.operationsSurface,
        onSurface: AppColorTokens.operationsInk,
        surfaceContainerHighest: AppColorTokens.operationsPaper,
        outlineVariant: AppColorTokens.operationsOlive.withValues(alpha: 0.18),
      ),
      scaffoldBackgroundColor: AppColorTokens.operationsDeskCanvas,
      cardTheme: base.cardTheme.copyWith(
        color: AppColorTokens.operationsSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorTokens.guardianCarePrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
    );
    return Theme(data: desk, child: child);
  }
}

/// Inline error icon + retryable action.
class _ErrorRetryView extends StatelessWidget {
  const _ErrorRetryView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 8),
          Text(message),
          TextButton.icon(
            key: const Key('global_events_retry'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(l.retry),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

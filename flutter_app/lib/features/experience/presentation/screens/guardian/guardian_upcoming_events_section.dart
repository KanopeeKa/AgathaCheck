import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import '../../widgets/guardian_care_preview/guardian_care_preview_optimistic.dart';
import '../../widgets/guardian_dashboard_section_header.dart';
import '../../widgets/guardian_illustrated_empty_state.dart';
import '../../widgets/guardian_operations_desk_layout.dart';
import 'guardian_dashboard_helpers.dart';

/// Guardian Care dashboard preview with one combined, date-ordered list.
///
/// Each preview entry is rendered as a [CareEventRow] with a calm,
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
  final Map<String, GuardianCareOptimisticCompletion> _completed = {};

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

    setState(() {
      _completed[entry.id] = GuardianCareOptimisticCompletion(
        entry: entry,
        previewIndex: previewIndex,
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
    await HomeEventActions.undoCompletion(context, ref, entry);
    if (!mounted) return;
    setState(() => _completed.remove(entry.id));
  }

  Widget _buildMobileContent(
    BuildContext ctx,
    List<HealthEntry> dueEntries,
    Map<String, Pet> petMap,
    AppLocalizations l,
    String emptyMessage,
    bool hasAnyCare,
  ) {
    final items = buildGuardianCareMobilePreview(
      dueEntries: dueEntries,
      completed: _completed,
      previewLimit: GuardianUpcomingEventsSection.previewLimit,
    );
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
        actionLabel: l.allCare,
        actionIcon: Icons.calendar_month_outlined,
        onAction: () => context.go('/g/events'),
      );
    }
    return GuardianCarePreviewEventList(
      items: items,
      petMap: petMap,
      onMarkDone: _onMarkDone,
      onUndo: _onUndo,
      onView: (entry) => HomeEventActions.viewEntry(context, entry),
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuardianDashboardSectionHeader(title: l.careEyebrow),
          const SizedBox(height: 10),
          const SizedBox(
            height: 56,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ],
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
    final showAllCare =
        careEntries.length > GuardianUpcomingEventsSection.previewLimit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuardianDashboardSectionHeader(
          title: l.careEyebrow,
          actionLabel: showAllCare ? l.allCare : null,
          onAction: showAllCare ? () => context.go('/g/events') : null,
          actionKey: showAllCare
              ? const Key('guardian_dashboard_care_view_all')
              : null,
        ),
        const SizedBox(height: 10),
        GuardianDeskSectionCard(
          key: const Key('guardian_dashboard_care_section'),
          tint: AppColorTokens.guardianLight,
          child: _buildMobileContent(
            context,
            careEntries,
            petMap,
            l,
            l.noCareDue,
            priorities.all.isNotEmpty,
          ),
        ),
      ],
    );
  }

  Widget _careError(BuildContext context, WidgetRef ref, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GuardianDashboardSectionHeader(title: l.careEyebrow),
        const SizedBox(height: 10),
        GuardianDeskSectionCard(
          tint: AppColorTokens.guardianLight,
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

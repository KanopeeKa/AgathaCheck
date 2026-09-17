import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_collection_inset_list.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import '../../../../health_tracking/presentation/widgets/occurrence_care_actions.dart';
import '../../widgets/pet_care_preview/pet_care_preview_optimistic.dart';
import '../../widgets/pet_care_dashboard_section_header.dart';
import '../../widgets/pet_care_illustrated_empty_state.dart';
import 'pet_care_dashboard_helpers.dart';

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
class PetCareUpcomingEventsSection extends ConsumerStatefulWidget {
  const PetCareUpcomingEventsSection({
    super.key,
    required this.pets,
    this.onAddEvent,
  });

  final List<Pet> pets;
  final VoidCallback? onAddEvent;

  static const previewLimit = 5;

  @override
  ConsumerState<PetCareUpcomingEventsSection> createState() =>
      _PetCareUpcomingEventsSectionState();
}

class _PetCareUpcomingEventsSectionState
    extends ConsumerState<PetCareUpcomingEventsSection> {
  /// Optimistically-completed entries, keyed by entry id, insertion-ordered.
  final Map<String, PetCareCareOptimisticCompletion> _completed = {};

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
    final result = await OccurrenceCareActions.showMarkDoneFlow(
      context,
      ref,
      entry,
    );
    if (result == null || !mounted) return;

    if (result.alreadyPersisted) return;

    setState(() {
      _completed[entry.id] = PetCareCareOptimisticCompletion(
        entry: entry,
        previewIndex: previewIndex,
      );
    });

    try {
      await OccurrenceCareActions.persistCompletion(
        ref,
        entry,
        result.completedOn,
        occurrenceId: result.occurrenceId,
        skipEarlierMissed: result.skipEarlierMissed,
      );
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

  Widget _careCollection(Widget child) {
    return CareCollectionInsetList(
      key: const Key('pet_care_dashboard_care_block'),
      children: [CareCollectionInsetItem(child: child)],
    );
  }

  bool _showAllCareLink(List<HealthEntry> entries) => entries.isNotEmpty;

  List<HealthEntry> _entriesForAsyncState(
    AsyncValue<List<HealthEntry>> entriesAsync,
    List<Pet> pets,
  ) {
    if (entriesAsync is AsyncData<List<HealthEntry>>) {
      final priorities = PetCareTodayCarePriorities.forPets(
        entries: entriesAsync.value,
        pets: pets,
        now: DateTime.now(),
      );
      return priorities.all;
    }
    if (entriesAsync is AsyncLoading<List<HealthEntry>> &&
        (_lastDueEntriesSnapshot.isNotEmpty || _completed.isNotEmpty)) {
      return PetCareTodayCarePriorities.forPets(
        entries: _lastDueEntriesSnapshot,
        pets: pets,
        now: DateTime.now(),
      ).all;
    }
    return const [];
  }

  Widget _buildMobileContent(
    BuildContext ctx,
    List<HealthEntry> dueEntries,
    Map<String, Pet> petMap,
    AppLocalizations l,
    String emptyMessage,
    bool hasAnyCare,
  ) {
    final items = buildPetCareMobilePreview(
      dueEntries: dueEntries,
      completed: _completed,
      previewLimit: PetCareUpcomingEventsSection.previewLimit,
    );
    if (items.isEmpty) {
      if (!hasAnyCare) {
        return PetCareIllustratedEmptyState(
          key: const Key('pet_care_dashboard_empty_care'),
          assetPath: 'assets/dashboard/pet-care-empty-care.png',
          title: l.petCareEmptyCareTitle,
          body: l.petCareEmptyCareBody,
          actionLabel: l.addAnEvent,
          actionKey: const Key('pet_care_dashboard_empty_care_action'),
          onAction: widget.onAddEvent,
        );
      }
      return PetCareIllustratedEmptyState(
        key: const Key('pet_care_dashboard_empty_care_clear'),
        title: l.petCareEmptyCareClearTitle,
        body: emptyMessage,
        actionLabel: l.allCare,
        actionIcon: Icons.calendar_month_outlined,
        onAction: () => context.go('/pc/events'),
      );
    }
    return PetCareCarePreviewEventList(
      collectionKey: const Key('pet_care_dashboard_care_block'),
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
    final careEntries = _entriesForAsyncState(entriesAsync, pets);
    final showAllCare = _showAllCareLink(careEntries);

    return Semantics(
      container: true,
      label: l.careEyebrow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetCareDashboardSectionChrome(
            title: l.careEyebrow,
            linkLabel: showAllCare ? l.allCare : null,
            linkKey: const Key('pet_care_dashboard_care_view_all'),
            onLinkPressed: showAllCare ? () => context.go('/pc/events') : null,
          ),
          const SizedBox(height: 10),
          KeyedSubtree(
            key: const Key('pet_care_dashboard_care_section'),
            child: _buildBody(context, entriesAsync, pets, l, careEntries),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<HealthEntry>> entriesAsync,
    List<Pet> pets,
    AppLocalizations l,
    List<HealthEntry> careEntries,
  ) {
    if (entriesAsync is AsyncData<List<HealthEntry>>) {
      return _careData(context, entriesAsync.value, pets, l);
    }
    if (entriesAsync is AsyncLoading<List<HealthEntry>>) {
      return _careLoading(context, pets, l);
    }
    return _careError(context, ref, l);
  }

  Widget _careData(
    BuildContext context,
    List<HealthEntry> entries,
    List<Pet> pets,
    AppLocalizations l,
  ) {
    final priorities = PetCareTodayCarePriorities.forPets(
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
      return _careCollection(
        const SizedBox(
          height: 56,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    final priorities = PetCareTodayCarePriorities.forPets(
      entries: _lastDueEntriesSnapshot,
      pets: pets,
      now: DateTime.now(),
    );
    return Column(
      children: [
        _careContent(context, priorities, pets, l),
        const SizedBox(height: 8),
        const SizedBox(
          key: Key('pet_care_due_events_refreshing'),
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ],
    );
  }

  Widget _careContent(
    BuildContext context,
    PetCareTodayCarePriorities priorities,
    List<Pet> pets,
    AppLocalizations l,
  ) {
    final careEntries = priorities.all;
    final petMap = {for (final pet in pets) pet.id: pet};

    return _buildMobileContent(
      context,
      careEntries,
      petMap,
      l,
      l.noCareDue,
      priorities.all.isNotEmpty,
    );
  }

  Widget _careError(BuildContext context, WidgetRef ref, AppLocalizations l) {
    return _careCollection(
      Column(
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
    );
  }
}

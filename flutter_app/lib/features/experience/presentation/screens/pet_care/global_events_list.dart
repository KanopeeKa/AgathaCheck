import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/health_tracking.dart';
import '../../../../care_item/care_item.dart';
import '../../../../pet_profile/pet_profile.dart';
import '../../pet_profile/screens/widgets/manage_events_collection_filter.dart';
import '../../pet_profile/screens/widgets/org_events_collection_filter.dart';
import '../../pet_profile/screens/widgets/pet_care_global_events_filters.dart';
import '../../pet_profile/widgets/pet_care_section/pet_care_action_row_builder.dart';
import '../../pet_profile/widgets/pet_list/home_event_actions.dart';
import 'care_list/global_events_collapsible_section.dart';
import 'care_list/global_events_entry_partitions.dart';
import 'care_list/global_events_pet_chip_bar.dart';
import 'care_list/global_events_pet_query.dart';
import '../../../../pet_care/pet_care.dart';
import 'pet_care_due_events_screen.dart';

// ---------------------------------------------------------------------------
// Scope
// ---------------------------------------------------------------------------

enum GlobalEventsListScope { guardian, organization }

// ---------------------------------------------------------------------------
// GlobalEventsList
// ---------------------------------------------------------------------------

/// Unified global events list with manage-events filters plus pet/cohort filters.
///
/// Planned care uses the agenda (D-CIE-025) with server-confirmed Done
/// (UIR-2); paused, ended and recorded-only items follow without a tick.
class GlobalEventsList extends ConsumerStatefulWidget {
  const GlobalEventsList({
    super.key,
    required this.shellPets,
    this.scope = GlobalEventsListScope.guardian,
  });

  final List<Pet> shellPets;
  final GlobalEventsListScope scope;

  @override
  ConsumerState<GlobalEventsList> createState() => _GlobalEventsListState();
}

class _GlobalEventsListState extends ConsumerState<GlobalEventsList> {
  PetCareGlobalEventsFilters _petCareFilters =
      const PetCareGlobalEventsFilters();
  OrgGlobalEventsFilters _orgFilters = const OrgGlobalEventsFilters();
  bool _pausedCareExpanded = false;
  bool _closedCareExpanded = false;

  bool get _isOrg => widget.scope == GlobalEventsListScope.organization;

  PetCareGlobalEventsFilters _guardianFiltersForBuild(BuildContext context) {
    final petIds = GlobalEventsPetQuery.petIdsFromUri(
      GoRouterState.of(context).uri,
      knownPetIds: widget.shellPets.map((p) => p.id),
    );
    return _petCareFilters.copyWith(petIds: petIds);
  }

  void _applyGuardianFilters(PetCareGlobalEventsFilters next) {
    final state = GoRouterState.of(context);
    final knownPetIds = widget.shellPets.map((p) => p.id);
    final currentPetIds = GlobalEventsPetQuery.petIdsFromUri(
      state.uri,
      knownPetIds: knownPetIds,
    );
    setState(
      () => _petCareFilters = PetCareGlobalEventsFilters(
        eventFilters: next.eventFilters,
        cohorts: next.cohorts,
        petIds: const {},
      ),
    );
    if (!_petSetsEqual(currentPetIds, next.petIds)) {
      final params = GlobalEventsPetQuery.petIdsToQueryParameters(
        next.petIds,
        base: state.uri.queryParameters,
      );
      final target = Uri(path: state.uri.path, queryParameters: params);
      context.go(target.toString());
    }
  }

  bool _petSetsEqual(Set<String> a, Set<String> b) =>
      a.length == b.length && a.every(b.contains);

  Future<void> _invalidateBoth() async {
    await ref.read(healthEntriesNotifierProvider.notifier).refresh();
    if (_isOrg) {
      ref.invalidate(orgGlobalEventHistoriesProvider);
    } else {
      ref.invalidate(guardianGlobalEventHistoriesProvider);
    }
  }

  // ---- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final guardianFilters = _isOrg ? null : _guardianFiltersForBuild(context);
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final historiesAsync = _isOrg
        ? ref.watch(orgGlobalEventHistoriesProvider)
        : ref.watch(guardianGlobalEventHistoriesProvider);
    final scopedPets = _isOrg
        ? orgGlobalEventsPets(widget.shellPets, _orgFilters)
        : guardianGlobalEventsPets(widget.shellPets, guardianFilters!);

    return ColoredBox(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.allCare,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.careActionsSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isOrg) ...[
                GlobalEventsPetChipBar(
                  shellPets: widget.shellPets,
                  filters: guardianFilters!,
                  onChanged: _applyGuardianFilters,
                ),
                PetCareGlobalEventsCollectionFilterBar(
                  shellPets: widget.shellPets,
                  filters: guardianFilters,
                  onChanged: _applyGuardianFilters,
                ),
              ] else
                OrgGlobalEventsCollectionFilterBar(
                  shellPets: widget.shellPets,
                  filters: _orgFilters,
                  onChanged: (f) => setState(() => _orgFilters = f),
                ),
              _buildBody(
                l,
                entriesAsync,
                historiesAsync,
                scopedPets,
                guardianFilters,
              ),
            ],
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
    PetCareGlobalEventsFilters? guardianFilters,
  ) {
    if (entriesAsync is AsyncError || historiesAsync is AsyncError) {
      return _ErrorRetryView(
        message: l.careLoadError,
        onRetry: _invalidateBoth,
      );
    }

    final entriesLoading = entriesAsync.isLoading && !entriesAsync.hasValue;
    final historiesLoading =
        historiesAsync.isLoading && !historiesAsync.hasValue;
    if (entriesLoading || historiesLoading) {
      return const Padding(
        padding: EdgeInsets.only(top: 8, bottom: 32),
        child: CareListSkeleton(),
      );
    }

    final entries = entriesAsync.valueOrNull ?? [];
    final histories = historiesAsync.valueOrNull ?? {};
    final visible = _isOrg
        ? filterOrgGlobalEvents(entries, scopedPets, _orgFilters, histories)
        : filterPetCareGlobalEvents(
            entries,
            scopedPets,
            guardianFilters!,
            histories,
          );
    if (visible.isEmpty) return _EmptyState(label: l.noEntriesYet);

    final agendaIds = buildCareAgenda<HealthEntry>(
      visible,
      (e) => e.schedule,
    ).rows.map((r) => r.item.id).toSet();
    final parts = GlobalEventsEntryPartitions.fromVisible(
      visible,
      agendaEntryIds: agendaIds,
    );
    if (parts.isEmpty) return _EmptyState(label: l.noEntriesYet);

    final petMap = {for (final p in widget.shellPets) p.id: p};

    return Padding(
      key: const Key('global_events_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parts.planned.isNotEmpty)
            CareListCollection(
              entries: parts.planned,
              source: CareCommandSource.agenda,
              petNames: {for (final p in widget.shellPets) p.id: p.name},
            ),
          GlobalEventsCollapsibleSection(
            sectionKey: const Key('global_events_paused_section'),
            semanticsIdentifier: 'global_events_paused_care',
            title: l.globalEventsPausedCareSection,
            count: parts.paused.length,
            expanded: _pausedCareExpanded,
            onToggle: () =>
                setState(() => _pausedCareExpanded = !_pausedCareExpanded),
            children: _lifecycleRows(l, parts.paused, petMap),
          ),
          GlobalEventsCollapsibleSection(
            sectionKey: const Key('global_events_closed_section'),
            semanticsIdentifier: 'global_events_closed_care',
            title: l.globalEventsClosedCareSection,
            count: parts.closed.length,
            expanded: _closedCareExpanded,
            onToggle: () =>
                setState(() => _closedCareExpanded = !_closedCareExpanded),
            children: _lifecycleRows(l, parts.closed, petMap),
          ),
        ],
      ),
    );
  }

  List<Widget> _lifecycleRows(
    AppLocalizations l,
    List<HealthEntry> entries,
    Map<String, Pet> petMap,
  ) {
    return [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const SizedBox(height: 8),
        KeyedSubtree(
          key: Key('global_events_row_${entries[i].id}'),
          child: PetCareActionRowBuilder(
            entry: entries[i],
            l10n: l,
            colorScheme: Theme.of(context).colorScheme,
            isEstablished: false,
            subtitlePetNamePrefix: petMap[entries[i].petId]?.name,
            onTap: () => _viewEntry(entries[i]),
          ).build(),
        ),
      ],
    ];
  }

  void _viewEntry(HealthEntry entry) {
    HomeEventActions.viewEntry(context, entry);
  }
}

// ---------------------------------------------------------------------------
// Shared presentation helpers
// ---------------------------------------------------------------------------

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

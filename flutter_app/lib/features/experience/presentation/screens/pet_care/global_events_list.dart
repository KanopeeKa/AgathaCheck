import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/domain/entities/health_history_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../care_item/care_item.dart';
import '../../../../pet_care/presentation/widgets/care_agenda/care_agenda_collection.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../../pet_profile/presentation/widgets/pet_care_section/pet_care_action_row_builder.dart';
import '../../../../pet_profile/presentation/widgets/pet_list/home_event_actions.dart';
import '../../../../pet_profile/presentation/screens/widgets/manage_events_collection_filter.dart';
import '../../../../pet_profile/presentation/screens/widgets/org_events_collection_filter.dart';
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

  bool get _isOrg => widget.scope == GlobalEventsListScope.organization;

  void _invalidateBoth() {
    ref.invalidate(healthEntriesNotifierProvider);
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
    final entriesAsync = ref.watch(healthEntriesNotifierProvider);
    final historiesAsync = _isOrg
        ? ref.watch(orgGlobalEventHistoriesProvider)
        : ref.watch(guardianGlobalEventHistoriesProvider);
    final scopedPets = _isOrg
        ? orgGlobalEventsPets(widget.shellPets, _orgFilters)
        : guardianGlobalEventsPets(widget.shellPets, _petCareFilters);

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
              if (!_isOrg)
                PetCareGlobalEventsCollectionFilterBar(
                  shellPets: widget.shellPets,
                  filters: _petCareFilters,
                  onChanged: (f) => setState(() => _petCareFilters = f),
                )
              else
                OrgGlobalEventsCollectionFilterBar(
                  shellPets: widget.shellPets,
                  filters: _orgFilters,
                  onChanged: (f) => setState(() => _orgFilters = f),
                ),
              _buildBody(l, entriesAsync, historiesAsync, scopedPets),
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
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final entries = entriesAsync.valueOrNull ?? [];
    final histories = historiesAsync.valueOrNull ?? {};
    final visible = _isOrg
        ? filterOrgGlobalEvents(entries, scopedPets, _orgFilters, histories)
        : filterPetCareGlobalEvents(
            entries,
            scopedPets,
            _petCareFilters,
            histories,
          );
    if (visible.isEmpty) return _EmptyState(label: l.noEntriesYet);

    final agendaIds = buildCareAgenda<HealthEntry>(
      visible,
      (e) => e.schedule,
    ).rows.map((r) => r.item.id).toSet();
    final planned = visible.where((e) => agendaIds.contains(e.id)).toList();
    final others = visible.where((e) => !agendaIds.contains(e.id)).toList();
    final petMap = {for (final p in widget.shellPets) p.id: p};

    return Padding(
      key: const Key('global_events_list'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (planned.isNotEmpty)
            CareAgendaCollection(
              entries: planned,
              source: CareCommandSource.agenda,
              petNames: {for (final p in widget.shellPets) p.id: p.name},
            ),
          for (final entry in others) ...[
            const SizedBox(height: 8),
            KeyedSubtree(
              key: Key('global_events_row_${entry.id}'),
              // Paused, ended, recorded only: no tick (DN-8).
              child: PetCareActionRowBuilder(
                entry: entry,
                l10n: l,
                colorScheme: Theme.of(context).colorScheme,
                isEstablished: false,
                statusLineOverride: petMap[entry.petId]?.name,
                onTap: () => _viewEntry(entry),
              ).build(),
            ),
          ],
        ],
      ),
    );
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/presentation/widgets/pet_care_illustrated_empty_state.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../health_tracking/presentation/widgets/add_health_entry_navigation.dart';
import '../../../../health_tracking/presentation/widgets/occurrence_care_actions.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';
import '../../../../pet_care/domain/models/care_temporal_buckets.dart';
import '../../../../pet_care/presentation/providers/care_temporal_grouping_providers.dart';
import '../../providers/care_progression_providers.dart';
import '../care_establishment_helpers.dart';
import '../../widgets/pet_list/home_event_actions.dart';
import '../pet_care_section/pet_care_buckets_filter.dart';
import '../pet_care_section/pet_care_temporal_group_section.dart';
import 'all_care_inactive_section.dart';

/// Pet-scoped All care list with temporal grouping and Child B action rows.
class AllCareList extends ConsumerStatefulWidget {
  const AllCareList({super.key, required this.petId});

  final String petId;

  @override
  ConsumerState<AllCareList> createState() => _AllCareListState();
}

class _AllCareListState extends ConsumerState<AllCareList> {
  final Set<String> _optimisticallyCompletedIds = {};

  Future<void> _onMarkDone(HealthEntry entry) async {
    final result = await OccurrenceCareActions.showMarkDoneFlow(
      context,
      ref,
      entry,
    );
    if (result == null || !mounted) return;
    if (result.alreadyPersisted) return;

    setState(() => _optimisticallyCompletedIds.add(entry.id));

    try {
      await OccurrenceCareActions.persistCompletion(
        ref,
        entry,
        result.completedOn,
        occurrenceId: result.occurrenceId,
        skipEarlierMissed: result.skipEarlierMissed,
      );
      if (!mounted) return;
      setState(() => _optimisticallyCompletedIds.remove(entry.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticallyCompletedIds.remove(entry.id));
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
  }

  List<HealthEntry> _inactiveEntries(
    List<HealthEntry> allEntries,
    CareTemporalBuckets buckets,
  ) {
    final activeIds = {
      for (final group in CareTemporalGroup.values)
        ...buckets.entriesIn(group).map((e) => e.id),
      ..._optimisticallyCompletedIds,
    };
    return sortInactiveAllCareEntries(
      allEntries.where((entry) => !activeIds.contains(entry.id)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));
    final buckets = filterOptimisticallyCompletedBuckets(
      ref.watch(petCareTemporalBucketsProvider(widget.petId)),
      _optimisticallyCompletedIds,
    );
    final establishmentsAsync = ref.watch(
      petCareEstablishmentsProvider(widget.petId),
    );
    final allEntries = entriesAsync.valueOrNull ?? const <HealthEntry>[];
    final establishedIds = establishmentsAsync.maybeWhen(
      data: (establishments) =>
          establishedRhythmEntryIds(establishments, allEntries),
      orElse: () => <String>{},
    );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
      data: (entries) {
        final groups = <Widget>[];
        for (final group in CareTemporalGroup.values) {
          final groupEntries = buckets.entriesIn(group);
          if (groupEntries.isEmpty) continue;
          groups.add(
            PetCareTemporalGroupSection(
              group: group,
              entries: groupEntries,
              establishedEntryIds: establishedIds,
              trailingLabel: l.done,
              onMarkDone: _onMarkDone,
              onViewEntry: (entry) =>
                  HomeEventActions.viewEntry(context, entry),
            ),
          );
        }

        final inactive = _inactiveEntries(entries, buckets);
        final hasActive = groups.isNotEmpty;
        final hasAny = hasActive || inactive.isNotEmpty;

        return SingleChildScrollView(
          key: const Key('all_care_list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!hasAny)
                PetCareIllustratedEmptyState(
                  key: const Key('all_care_empty'),
                  title: l.petCareEmptyCareTitle,
                  body: l.petCareEmptyCareBody,
                  actionLabel: l.addAnEvent,
                  actionIcon: Icons.add,
                  onAction: () =>
                      navigateToAddHealthEntry(context, petId: widget.petId),
                )
              else ...[
                ...groups,
                AllCareInactiveSection(
                  entries: inactive,
                  establishedEntryIds: establishedIds,
                  onMarkDone: _onMarkDone,
                  onViewEntry: (entry) =>
                      HomeEventActions.viewEntry(context, entry),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

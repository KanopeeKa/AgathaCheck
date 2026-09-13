import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../experience/presentation/widgets/pet_care_dashboard_section_header.dart';
import '../../../../experience/presentation/widgets/pet_care_illustrated_empty_state.dart';
import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';
import '../../../../pet_care/presentation/providers/care_temporal_grouping_providers.dart';
import '../../../domain/entities/pet.dart';
import '../../providers/care_progression_providers.dart';
import '../care_establishment_helpers.dart';
import '../../widgets/pet_list/home_event_actions.dart';
import 'pet_care_buckets_filter.dart';
import 'pet_care_temporal_group_section.dart';

/// Pet-scoped `{Pet}'s care` section with temporal grouping (Child D phase 1).
class PetCareSection extends ConsumerStatefulWidget {
  const PetCareSection({super.key, required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  ConsumerState<PetCareSection> createState() => _PetCareSectionState();
}

class _PetCareSectionState extends ConsumerState<PetCareSection> {
  final Set<String> _optimisticallyCompletedIds = {};

  Future<void> _onMarkDone(HealthEntry entry) async {
    final result = await HomeEventActions.showCompletionSheet(context);
    if (result == null || !mounted) return;

    setState(() => _optimisticallyCompletedIds.add(entry.id));

    try {
      await HomeEventActions.commitCompletion(context, ref, entry, result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticallyCompletedIds.remove(entry.id));
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.careCompletionFailed)));
    }
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: entriesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionHeader(title: l.careForPet(widget.pet.name)),
            const SizedBox(height: 10),
            const SizedBox(
              height: 56,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ],
        ),
        error: (error, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionHeader(title: l.careForPet(widget.pet.name)),
            const SizedBox(height: 10),
            Text(
              l.errorLoadingEntries(error.toString()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        data: (_) {
          final groups = <Widget>[];
          for (final group in CareTemporalGroup.values) {
            final entries = buckets.entriesIn(group);
            if (entries.isEmpty) continue;
            groups.add(
              PetCareTemporalGroupSection(
                group: group,
                entries: entries,
                establishedEntryIds: establishedIds,
                trailingLabel: l.done,
                onMarkDone: _onMarkDone,
                onViewEntry: (entry) =>
                    HomeEventActions.viewEntry(context, entry),
              ),
            );
          }

          return Column(
            key: const Key('pet_care_section'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PetCareDashboardSectionHeader(
                title: l.careForPet(widget.pet.name),
              ),
              const SizedBox(height: 10),
              if (groups.isEmpty)
                PetCareIllustratedEmptyState(
                  key: const Key('pet_care_section_empty'),
                  title: l.petCareEmptyCareClearTitle,
                  body: l.homeNoDueEvents,
                  actionLabel: l.allCare,
                  actionIcon: Icons.calendar_month_outlined,
                  onAction: () => context.push('/pet/${widget.petId}/events'),
                )
              else
                ...groups,
              if (!buckets.isEmpty)
                PetCareDashboardSectionLink(
                  linkKey: const Key('pet_care_view_all'),
                  label: l.allCare,
                  onPressed: () => context.push('/pet/${widget.petId}/events'),
                ),
            ],
          );
        },
      ),
    );
  }
}

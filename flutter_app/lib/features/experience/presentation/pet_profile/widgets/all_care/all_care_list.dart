import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/core/widgets/pet_care_illustrated_empty_state.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import '../../widgets/pet_list/home_event_actions.dart';
import 'all_care_inactive_section.dart';

/// Pet-scoped All care: the agenda groups (D-CIE-025) for planned care, then
/// paused, ended and recorded-only items.
class AllCareList extends ConsumerWidget {
  const AllCareList({super.key, required this.petId});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(petId));
    final allEntries = entriesAsync.valueOrNull ?? const <HealthEntry>[];
    final establishedIds = ref
        .watch(petCareEstablishmentsProvider(petId))
        .maybeWhen(
          data: (establishments) =>
              establishedRhythmEntryIds(establishments, allEntries),
          orElse: () => <String>{},
        );

    return entriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(l.errorWithMessage('$error'))),
      data: (entries) {
        final agendaIds = buildCareAgenda<HealthEntry>(
          entries,
          (e) => e.schedule,
        ).rows.map((r) => r.item.id).toSet();
        final active = entries.where((e) => agendaIds.contains(e.id)).toList();
        final inactive = sortInactiveAllCareEntries(
          entries.where((e) => !agendaIds.contains(e.id)).toList(),
        );

        return SingleChildScrollView(
          key: const Key('all_care_list'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (entries.isEmpty)
                PetCareIllustratedEmptyState(
                  key: const Key('all_care_empty'),
                  title: l.petCareEmptyCareTitle,
                  body: l.petCareEmptyCareBody,
                  actionLabel: l.addAnEvent,
                  actionIcon: Icons.add,
                  onAction: () =>
                      navigateToAddHealthEntry(context, petId: petId),
                )
              else ...[
                if (active.isNotEmpty)
                  CareAgendaCollection(
                    entries: active,
                    source: CareCommandSource.agenda,
                  ),
                AllCareInactiveSection(
                  entries: inactive,
                  establishedEntryIds: establishedIds,
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

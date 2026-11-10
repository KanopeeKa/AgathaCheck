import 'package:flutter/material.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/core/widgets/pet_care_dashboard_section_header.dart';
import 'package:pet_profile_app/core/widgets/pet_care_illustrated_empty_state.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/care_list/global_events_pet_query.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Pet-scoped `{Pet}'s care` section: the agenda (D-CIE-025) for one pet.
class PetCareSection extends ConsumerStatefulWidget {
  const PetCareSection({super.key, required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  ConsumerState<PetCareSection> createState() => _PetCareSectionState();
}

class _PetCareSectionState extends ConsumerState<PetCareSection> {
  void _openAllCareForPet() {
    final returnTo = petDetailBackPath(context, widget.petId);
    context.push(
      globalAllCareLocation(petIds: {widget.petId}, returnTo: returnTo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: entriesAsync.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionChrome(
              title: l.careForPet(widget.pet.name),
              titleMaxLines: 2,
            ),
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
            PetCareDashboardSectionChrome(
              title: l.careForPet(widget.pet.name),
              titleMaxLines: 2,
            ),
            const SizedBox(height: 10),
            Text(
              l.errorLoadingEntries(error.toString()),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            TextButton(
              key: const Key('pet_care_section_retry'),
              onPressed: () =>
                  ref.read(healthEntriesNotifierProvider.notifier).refresh(),
              child: Text(l.careRetry),
            ),
          ],
        ),
        data: (entries) => Column(
          key: const Key('pet_care_section'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PetCareDashboardSectionChrome(
              title: l.careForPet(widget.pet.name),
              titleMaxLines: 2,
            ),
            const SizedBox(height: 10),
            CareAgendaCollection(
              entries: entries,
              source: CareCommandSource.agenda,
              empty: PetCareIllustratedEmptyState(
                key: const Key('pet_care_section_empty'),
                title: l.petCareEmptyCareClearTitle,
                body: l.homeNoDueEvents,
                actionLabel: l.viewAllCare,
                actionIcon: Icons.calendar_month_outlined,
                onAction: _openAllCareForPet,
              ),
            ),
            PetCareDashboardSectionLink(
              linkKey: const Key('pet_care_view_all'),
              label: l.viewAllCare,
              onPressed: _openAllCareForPet,
            ),
          ],
        ),
      ),
    );
  }
}

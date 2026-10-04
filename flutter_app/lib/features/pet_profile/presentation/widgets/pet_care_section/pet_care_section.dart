import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../care_item/care_item.dart';
import '../../../../experience/presentation/widgets/pet_care_dashboard_section_header.dart';
import '../../../../experience/presentation/widgets/pet_care_illustrated_empty_state.dart';
import '../../../../health_tracking/presentation/providers/health_providers.dart';
import '../../../../pet_care/presentation/widgets/care_agenda/care_agenda_collection.dart';
import '../../../domain/entities/pet.dart';

/// Pet-scoped `{Pet}'s care` section: the agenda (D-CIE-025) for one pet.
class PetCareSection extends ConsumerStatefulWidget {
  const PetCareSection({super.key, required this.petId, required this.pet});

  final String petId;
  final Pet pet;

  @override
  ConsumerState<PetCareSection> createState() => _PetCareSectionState();
}

class _PetCareSectionState extends ConsumerState<PetCareSection> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(petHealthEntriesByIdProvider(widget.petId));

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
            PetCareDashboardSectionHeader(title: l.careForPet(widget.pet.name)),
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
                onAction: () => context.push('/pet/${widget.petId}/events'),
              ),
            ),
            PetCareDashboardSectionLink(
              linkKey: const Key('pet_care_view_all'),
              label: l.viewAllCare,
              onPressed: () => context.push('/pet/${widget.petId}/events'),
            ),
          ],
        ),
      ),
    );
  }
}

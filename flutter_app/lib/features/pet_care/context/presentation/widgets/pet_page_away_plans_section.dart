import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/widgets/pet_care_dashboard_section_header.dart';
import '../../../../../l10n/app_localizations.dart';
import '../away_plan_copy.dart';
import '../planned_absence_display.dart';
import '../providers/care_context_providers.dart';
import '../../domain/entities/pet_planned_absence_row.dart';

/// Away plans for one pet on the pet profile (CARE-CONTEXT-R-031).
class PetPageAwayPlansSection extends ConsumerWidget {
  const PetPageAwayPlansSection({super.key, required this.petId});

  final String petId;

  static const int _maxVisible = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRows = ref.watch(petPlannedAbsencesProvider(petId));
    return asyncRows.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.items.isEmpty) return const SizedBox.shrink();
        final l = AppLocalizations.of(context)!;
        final visible = result.items.take(_maxVisible).toList(growable: false);
        final hasMore = result.items.length > _maxVisible;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            kPetDetailSectionInsetTop,
            16,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PetCareDashboardSectionChrome(
                title: l.careContextPetPageAwaySectionTitle,
                linkLabel: hasMore ? l.careContextPetPageAllAbsences : null,
                linkKey: const Key('pet_page_all_absences_link'),
                onLinkPressed: hasMore ? () => context.push('/pc/away') : null,
              ),
              const SizedBox(height: kPetDetailSectionTitleGap),
              for (final row in visible) ...[
                _AwayPlanRow(row: row),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AwayPlanRow extends StatelessWidget {
  const _AwayPlanRow({required this.row});

  final PetPlannedAbsenceRow row;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final absence = row.absence;
    final primary = PlannedAbsenceDisplay.primaryLabel(l, absence);
    final dates =
        PlannedAbsenceDisplay.secondaryDateLine(l, absence) ??
        PlannedAbsenceDisplay.dateRangeLabel(l, absence);
    final traveller = PlannedAbsenceDisplay.travellerLine(l, absence);
    final statusLine = AwayPlanCopy.petPillStatusLine(l, row.status);
    final subtitleParts = [
      traveller,
      dates,
      if (statusLine != null && statusLine.isNotEmpty) statusLine,
    ];
    return Semantics(
      button: true,
      identifier: 'pet_page_away_row_${row.absenceId}',
      label: '$primary. ${subtitleParts.join('. ')}',
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          key: Key('pet_page_away_row_${row.absenceId}'),
          onTap: () =>
              context.push('/pc/away/${row.absenceId}/pets/${row.petId}'),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primary,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

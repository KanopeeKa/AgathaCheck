import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_profile/domain/entities/pet.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/health_history_entry.dart';
import 'package:intl/intl.dart';

import '../../widgets/pet_event_documents_strip.dart';
import '../../widgets/pet_event_past_occurrences_section.dart';
import '../../widgets/pet_event_past_iterations_section.dart';
import '../../widgets/pet_event_lifecycle.dart';
import '../../widgets/pet_event_pet_card.dart';
import 'care_item_dates_section.dart';
import 'care_item_established_section.dart';
import '../../widgets/care_category_blocks/care_category_blocks_detail_section.dart';
import 'care_item_info_section.dart';
import 'care_item_absence_section.dart';
import 'care_item_schedule_section.dart';
import '../../providers/care_item_absence_providers.dart';

/// Care Item detail body — spec order: header card, needs attention, schedule, details, history.
class CareItemDetailBody extends ConsumerWidget {
  const CareItemDetailBody({
    super.key,
    required this.petId,
    required this.entry,
    required this.pet,
    required this.history,
    required this.isClosed,
    required this.isEstablished,
    required this.onSeeHistory,
  });

  final String petId;
  final HealthEntry entry;
  final Pet pet;
  final List<HealthHistoryEntry> history;
  final bool isClosed;
  final bool isEstablished;
  final VoidCallback onSeeHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final muted = isClosed;
    final showNeedsAttention = !isClosed && !entry.isCompleted;
    final absenceContext = ref.watch(careItemAbsenceContextProvider(entry.id));
    final absenceBeforeSchedule = absenceContext.maybeWhen(
      data: (model) => model.absences.any((slice) => slice.needsAttention),
      orElse: () => false,
    );
    final absenceSection = CareItemAbsenceSection(
      entryId: entry.id,
      muted: muted,
    );
    final scheduleSection = CareItemScheduleSection(
      entry: entry,
      petId: petId,
      muted: muted,
    );

    return SingleChildScrollView(
      key: const Key('care_item_detail_body'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetEventPetCard(pet: pet),
          const SizedBox(height: 16),
          if (showNeedsAttention)
            CareItemDatesSection(entry: entry, muted: muted)
          else
            _ClosedNeedsAttentionSummary(history: history, muted: muted),
          const SizedBox(height: 16),
          if (absenceBeforeSchedule) ...[
            absenceSection,
            const SizedBox(height: 16),
            scheduleSection,
          ] else ...[
            scheduleSection,
            const SizedBox(height: 16),
            absenceSection,
          ],
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l.careItemDetailsTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          CareCategoryBlocksDetailSection(entry: entry, pet: pet, muted: muted),
          CareItemInfoSection(entry: entry, muted: muted),
          CareItemEstablishedSection(pet: pet, isEstablished: isEstablished),
          if (entry.healthIssueId != null &&
              (entry.healthIssueName?.isNotEmpty ?? false)) ...[
            const SizedBox(height: 16),
            _HealthIssueLink(
              petId: petId,
              issueName: entry.healthIssueName!,
              muted: muted,
            ),
          ],
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Text(
              l.careItemHistoryTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: muted
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          PetEventDocumentsStrip(entryId: entry.id),
          const SizedBox(height: 16),
          PetEventPastOccurrencesSection(entryId: entry.id, muted: muted),
          PetEventPastIterationsSection(
            entry: entry,
            history: history,
            isClosed: isClosed,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('care_item_see_history'),
            onPressed: onSeeHistory,
            icon: const Icon(Icons.history),
            label: Text(l.seeHistory),
          ),
        ],
      ),
    );
  }
}

class _ClosedNeedsAttentionSummary extends StatelessWidget {
  const _ClosedNeedsAttentionSummary({
    required this.history,
    required this.muted,
  });

  final List<HealthHistoryEntry> history;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final last = sortedHistoryDesc(history).firstOrNull;

    return Column(
      key: const Key('care_item_needs_attention_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l.careItemNeedsAttentionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: muted ? colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (last == null)
          Text(
            l.noHistoryYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          Text(
            last.isSkipped
                ? l.occurrenceSkipped
                : last.completedOn != null
                ? l.doneOn(DateFormat.yMMMd().format(last.completedOn!))
                : l.notSet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

class _HealthIssueLink extends StatelessWidget {
  const _HealthIssueLink({
    required this.petId,
    required this.issueName,
    required this.muted,
  });

  final String petId;
  final String issueName;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.relatesToHealthIssue,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: muted ? colorScheme.onSurfaceVariant : null,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          key: const Key('care_item_health_issue_link'),
          onTap: muted ? null : () => context.push('/pet/$petId/health-issues'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  issueName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: muted
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

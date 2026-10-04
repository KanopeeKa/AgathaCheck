import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_attention_callout.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../data/models/health_entry_absence_context_model.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/health_occurrence.dart';
import '../../providers/care_item_absence_providers.dart';
import '../../providers/care_item_absence_resolution_sync.dart';
import '../../providers/care_item_detail_refresh.dart';
import '../../widgets/occurrence_review_flow.dart';

class CareItemAbsenceSection extends ConsumerWidget {
  const CareItemAbsenceSection({
    super.key,
    required this.entry,
    required this.muted,
  });

  final HealthEntry entry;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncContext = ref.watch(careItemAbsenceContextProvider(entry.id));

    return asyncContext.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (contextModel) {
        if (contextModel.absences.isEmpty) {
          return const SizedBox.shrink();
        }
        final primary = contextModel.absences.firstWhere(
          (slice) => slice.needsAttention,
          orElse: () => contextModel.absences.first,
        );
        final summary = _summaryLine(l, primary);
        final needsAttention = primary.needsAttention;

        return CareItemModule(
          key: const Key('care_item_absence_section'),
          semanticLabel: l.careItemAbsenceTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CareItemSectionHeader(
                title: l.careItemAbsenceTitle,
                icon: Icons.flight_takeoff_outlined,
              ),
              const SizedBox(height: 12),
              if (needsAttention && !muted)
                CareAttentionCallout(
                  message: summary,
                  semanticLabel: l.careItemAbsenceNeedsReview,
                )
              else
                Text(summary, style: Theme.of(context).textTheme.bodyMedium),
              if (needsAttention && !muted) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('care_item_absence_keep_date'),
                      onPressed: () => _keepDate(context, ref, primary),
                      child: Text(_keepLabel(l, primary)),
                    ),
                    TextButton(
                      key: const Key('care_item_absence_review_date'),
                      onPressed: () => _reviewDate(context, ref, primary),
                      child: Text(l.careItemAbsenceReviewDateAction),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _keepLabel(AppLocalizations l, HealthEntryAbsenceSlice slice) {
    final carer = slice.carerDisplayName();
    if (carer != null) {
      return l.careItemAbsenceKeepWithCarer(carer);
    }
    return l.careItemAbsenceKeepDuringAbsence;
  }

  String _summaryLine(AppLocalizations l, HealthEntryAbsenceSlice slice) {
    final start = parseCalendarDate(slice.startsOn);
    final end = parseCalendarDate(slice.endsOn);
    final range = start != null && end != null
        ? '${DateFormat.MMMd().format(start)}–${DateFormat.MMMd().format(end)}'
        : '${slice.startsOn}–${slice.endsOn}';

    final conflictDate = primaryAbsenceConflictDate(slice);
    final conflictLabel = conflictDate != null
        ? formatCalendarDateDisplay(parseCalendarDate(conflictDate)!)
        : null;

    switch (slice.uiState) {
      case 'not_reviewed':
        if (conflictLabel != null) {
          return l.careItemAbsenceNotReviewedOnDate(conflictLabel, range);
        }
        return '${l.careItemAbsenceNotReviewed} · $range';
      case 'needs_review':
        return '${l.careItemAbsenceNeedsReview} · $range';
      case 'resolved':
        return l.careItemAbsenceResolved;
      default:
        return l.careItemAbsenceNothingDue(range);
    }
  }

  Future<void> _keepDate(
    BuildContext context,
    WidgetRef ref,
    HealthEntryAbsenceSlice slice,
  ) async {
    final remote = ref.read(healthAbsenceContextRemoteProvider);
    final lookedAfter =
        slice.suggestedLookedAfterBy?.toApiPayload() ??
        slice.petCarer?.toApiPayload();
    await remote.saveResolution(
      absenceId: slice.plannedAbsenceId,
      healthEntryId: entry.id,
      decision: 'keep_date',
      lookedAfterBy: lookedAfter,
    );
    invalidateCareItemDetailData(
      ref,
      entry.id,
      absenceId: slice.plannedAbsenceId,
    );
  }

  Future<void> _reviewDate(
    BuildContext context,
    WidgetRef ref,
    HealthEntryAbsenceSlice slice,
  ) async {
    final review = slice.reviewOccurrence;
    HealthOccurrence? initialOccurrence;
    if (review != null &&
        review.occurrenceId.isNotEmpty &&
        review.scheduledDate.isNotEmpty) {
      final scheduled = parseCalendarDate(review.scheduledDate);
      if (scheduled != null) {
        initialOccurrence = HealthOccurrence(
          id: review.occurrenceId,
          entryId: entry.id,
          scheduledDate: scheduled,
          scheduledTime: review.scheduledTime,
          status: 'pending',
        );
      }
    }
    if (initialOccurrence == null) {
      if (!context.mounted) return;
      final l = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.careCompletionFailed)),
      );
      return;
    }
    await OccurrenceReviewFlow.open(
      context,
      ref,
      entry,
      absenceId: slice.plannedAbsenceId,
      initialOccurrence: initialOccurrence,
    );
    if (context.mounted) {
      invalidateCareItemDetailData(
        ref,
        entry.id,
        absenceId: slice.plannedAbsenceId,
      );
    }
  }
}

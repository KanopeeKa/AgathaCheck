import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_attention_callout.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../data/models/health_entry_absence_context_model.dart';
import '../../providers/care_item_absence_providers.dart';

class CareItemAbsenceSection extends ConsumerWidget {
  const CareItemAbsenceSection({
    super.key,
    required this.entryId,
    required this.muted,
  });

  final String entryId;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final asyncContext = ref.watch(careItemAbsenceContextProvider(entryId));

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
                Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (needsAttention && !muted) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: const Key('care_item_absence_keep_date'),
                      onPressed: () => _save(ref, primary, decision: 'keep_date'),
                      child: Text(l.careItemAbsenceKeepDate),
                    ),
                    TextButton(
                      key: const Key('care_item_absence_nothing_needed'),
                      onPressed: () =>
                          _save(ref, primary, decision: 'nothing_needed'),
                      child: Text(l.careItemAbsenceNothingNeeded),
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

  String _summaryLine(AppLocalizations l, HealthEntryAbsenceSlice slice) {
    final start = parseCalendarDate(slice.startsOn);
    final end = parseCalendarDate(slice.endsOn);
    final range = start != null && end != null
        ? '${DateFormat.MMMd().format(start)}–${DateFormat.MMMd().format(end)}'
        : '${slice.startsOn}–${slice.endsOn}';

    switch (slice.uiState) {
      case 'not_reviewed':
        return '${l.careItemAbsenceNotReviewed} · $range';
      case 'needs_review':
        return '${l.careItemAbsenceNeedsReview} · $range';
      case 'resolved':
        return l.careItemAbsenceResolved;
      default:
        return l.careItemAbsenceNothingDue(range);
    }
  }

  Future<void> _save(
    WidgetRef ref,
    HealthEntryAbsenceSlice slice, {
    required String decision,
  }) async {
    final remote = ref.read(healthAbsenceContextRemoteProvider);
    await remote.saveResolution(
      absenceId: slice.plannedAbsenceId,
      healthEntryId: entryId,
      decision: decision,
    );
    ref.invalidate(careItemAbsenceContextProvider(entryId));
  }
}

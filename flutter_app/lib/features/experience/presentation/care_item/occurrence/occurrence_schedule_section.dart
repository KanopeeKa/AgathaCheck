import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/widgets/care_skip_button.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_occurrence_status_pill.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_absence_section.dart';
import 'occurrence_reschedule.dart';
import 'occurrence_reschedule_icon_button.dart';
import 'occurrence_undo_label.dart';

/// Block 2 — due row, schedule actions, carer, absence, Reopen (CARE-ITEM-R-018).
class OccurrenceScheduleSection extends ConsumerWidget {
  const OccurrenceScheduleSection({
    super.key,
    required this.entryId,
    required this.detail,
    required this.onChanged,
    required this.scheduleActionsBusy,
    this.onChangeDate,
    this.onSkip,
    this.onUndo,
    this.seriesFinished = false,
  });

  final String entryId;
  final OccurrenceDetail detail;
  final Future<void> Function() onChanged;
  final bool scheduleActionsBusy;
  final VoidCallback? onChangeDate;
  final VoidCallback? onSkip;
  final Future<void> Function()? onUndo;
  final bool seriesFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final occ = detail.occurrence;
    final item = detail.item;
    final schedule = detail.schedule;
    final finished = _isFinished(item, schedule);
    final paused = schedule?.status == 'paused' || item.status == 'paused';
    final pill = occurrenceStatusPillStyle(l, occ);
    final overdueDays = _daysOverdue(occ, item.asOf.date);
    final showScheduleActions =
        occ.isOpen && onChangeDate != null && onSkip != null;
    final showReopen = !occ.isOpen && detail.canUndoHere && onUndo != null;
    final showFinishedCopy =
        !occ.isOpen && !detail.canUndoHere && seriesFinished;

    final absenceChild = OccurrenceAbsenceSection(
      entryId: entryId,
      detail: detail,
      onChanged: onChanged,
    );

    return Semantics(
      identifier: 'occurrence_schedule_section',
      container: true,
      child: _ScheduleSurface(
        entryId: entryId,
        detail: detail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.occurrenceDueLabel,
                        key: const Key('occurrence_due_label'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatWhen(context, l, occ),
                        key: const Key('occurrence_scheduled_when'),
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: CareItemOccurrenceStatusPill(
                            key: const Key('occurrence_status'),
                            pill: pill,
                          ),
                        ),
                      ),
                      if (overdueDays != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          l.occurrenceDaysOverdue(overdueDays),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showScheduleActions) ...[
                  OccurrenceRescheduleIconButton(
                    onPressed:
                        scheduleActionsBusy ||
                            !occurrenceShowsReschedule(detail)
                        ? null
                        : onChangeDate,
                  ),
                  const SizedBox(width: 4),
                  CareSkipButton(
                    key: const Key('occurrence_skip'),
                    semanticsIdentifier: 'occurrence_skip',
                    onPressed: scheduleActionsBusy ? null : onSkip,
                  ),
                ],
              ],
            ),
            if (finished || paused) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (finished)
                    CareItemStatusPill(
                      label: l.careItemStatusFinished,
                      tone: CareItemStatusTone.neutral,
                    ),
                  if (paused && !finished)
                    CareItemStatusPill(
                      label: l.careItemPausedStatus,
                      tone: CareItemStatusTone.neutral,
                    ),
                ],
              ),
            ],
            _CarerReadOnly(entryId: entryId, detail: detail),
            if (occ.isOpen) ...[const SizedBox(height: 12), absenceChild],
            if (showReopen) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('occurrence_undo'),
                onPressed: scheduleActionsBusy ? null : () => onUndo!(),
                child: Text(occurrenceUndoLabel(l, detail.lastAction)),
              ),
            ] else if (showFinishedCopy) ...[
              const SizedBox(height: 8),
              Text(
                l.occurrenceCareFinishedNoReopen,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isFinished(CareItemSummary item, CareItemSchedule? schedule) {
    if (item.status == 'completed') return true;
    return schedule?.status == 'completed';
  }

  int? _daysOverdue(CareOccurrence occ, DateTime asOfDate) {
    if (occ.status != CareOccurrenceStatus.overdue) return null;
    final scheduled = DateTime(occ.date.year, occ.date.month, occ.date.day);
    final asOf = DateTime(asOfDate.year, asOfDate.month, asOfDate.day);
    final days = asOf.difference(scheduled).inDays;
    return days > 0 ? days : null;
  }

  String _formatWhen(
    BuildContext context,
    AppLocalizations l,
    CareOccurrence occ,
  ) {
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).format(occ.date);
    final time = occ.time;
    if (time == null || time.isEmpty) return dateStr;
    final parts = time.split(':');
    if (parts.length < 2) return l.occurrenceDateAtTime(dateStr, time);
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
    return l.occurrenceDateAtTime(dateStr, formattedTime);
  }
}

class _ScheduleSurface extends ConsumerWidget {
  const _ScheduleSurface({
    required this.entryId,
    required this.detail,
    required this.child,
  });

  final String entryId;
  final OccurrenceDetail detail;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occ = detail.occurrence;
    if (!occ.isOpen) {
      return CareItemModule(child: child);
    }

    final wireDate = wireDateForOccurrence(occ.date);
    final asyncContext = ref.watch(careItemAbsenceContextProvider(entryId));

    return asyncContext.when(
      loading: () => CareItemModule(child: child),
      error: (_, __) => CareItemModule(child: child),
      data: (model) {
        var hasAbsence = false;
        for (final s in model.absences) {
          if (s.affected && absenceSliceConflictsOnDate(s, wireDate)) {
            hasAbsence = true;
            break;
          }
        }
        if (!hasAbsence) return CareItemModule(child: child);
        return CareItemModule(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColorTokens.awayContextSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(padding: const EdgeInsets.all(12), child: child),
          ),
        );
      },
    );
  }
}

class _CarerReadOnly extends ConsumerWidget {
  const _CarerReadOnly({required this.entryId, required this.detail});

  final String entryId;
  final OccurrenceDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final asyncContext = ref.watch(careItemAbsenceContextProvider(entryId));
    final occ = detail.occurrence;
    final wireDate = wireDateForOccurrence(occ.date);

    return asyncContext.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (model) {
        String? carerName;
        for (final s in model.absences) {
          if (s.affected && absenceSliceConflictsOnDate(s, wireDate)) {
            carerName = s.carerDisplayName();
            break;
          }
        }
        if (carerName == null || carerName.isEmpty) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Text(
                '${l.pdfCarer}: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: Text(
                  carerName,
                  key: const Key('occurrence_carer_read_only'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

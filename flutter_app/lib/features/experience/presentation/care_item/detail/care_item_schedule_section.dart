import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

/// Schedule summary (spec §Schedule) — stat grid + prose; edit via header action.
class CareItemScheduleSection extends ConsumerWidget {
  const CareItemScheduleSection({
    super.key,
    required this.entry,
    required this.petId,
    required this.muted,
  });

  final HealthEntry entry;
  final String petId;
  final bool muted;

  String _frequencyStatValue(AppLocalizations l) {
    if (entry.frequency == HealthFrequency.once) {
      return l.doesNotRepeat;
    }
    final interval = entry.frequencyInterval;
    final period = healthEntryPeriodLabel(l, entry.frequency, interval);
    if (interval == 1) {
      return l.everyPeriod(period);
    }
    return l.everyNPeriods(interval, period);
  }

  String _reminderStatValue(AppLocalizations l) {
    final count = entry.remindDaysBefore;
    final dayLabel = count == 1 ? l.day : l.days;
    return '$count $dayLabel';
  }

  String _typeStatLabel(AppLocalizations l) =>
      l.entryType.replaceAll('*', '').trim();

  String _recurrenceFlexLine(AppLocalizations l) {
    return switch (entry.recurrenceAnchor) {
      RecurrenceAnchor.fromCompletion => l.recurrenceFromCompletion,
      RecurrenceAnchor.fromDueDate => l.recurrenceFromDueDate,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textColor = muted ? colorScheme.onSurfaceVariant : null;

    final editSchedule = muted
        ? null
        : TextButton(
            key: const Key('care_item_edit_schedule'),
            onPressed: () => context.push(healthEntryEditRoute(entry, petId)),
            child: Text(l.careItemEditSchedule),
          );

    return CareItemModule(
      key: const Key('care_item_schedule_section'),
      semanticLabel: l.careItemScheduleTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CareItemSectionHeader(
            title: l.careItemScheduleTitle,
            icon: Icons.event_repeat_outlined,
            trailing: editSchedule,
          ),
          const SizedBox(height: 12),
          CareItemStatRow(
            cells: [
              CareItemStatCellData(
                label: l.frequency,
                value: _frequencyStatValue(l),
                icon: Icons.repeat,
              ),
              CareItemStatCellData(
                label: _typeStatLabel(l),
                value: healthEntryTypeLabel(l, entry.type),
                icon: healthEntryTypeIcon(entry.type),
              ),
              CareItemStatCellData(
                label: l.reminderDaysBefore,
                value: _reminderStatValue(l),
                icon: Icons.notifications_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (entry.nextDueDate != null) ...[
            Text(
              '${l.nextOccurrence}: ${formatHealthEntryCalendarDate(entry.nextDueDate!)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
            if (!muted)
              _ScheduleAbsenceHint(
                entryId: entry.id,
                nextDueWire: toCalendarDateString(entry.nextDueDate!),
              ),
          ] else if (!muted)
            _ScheduleAbsenceHint(entryId: entry.id, nextDueWire: null),
          if (entry.frequency != HealthFrequency.once) ...[
            const SizedBox(height: 4),
            Text(
              _recurrenceFlexLine(l),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleAbsenceHint extends ConsumerWidget {
  const _ScheduleAbsenceHint({
    required this.entryId,
    required this.nextDueWire,
  });

  final String entryId;
  final String? nextDueWire;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final line = ref
        .watch(careItemAbsenceContextProvider(entryId))
        .maybeWhen(
          data: (model) {
            for (final slice in model.absences) {
              if (!slice.affected || !slice.needsAttention) continue;
              final conflict = nextDueWire ?? primaryAbsenceConflictDate(slice);
              if (conflict == null) continue;
              if (!absenceSliceConflictsOnDate(slice, conflict)) continue;
              final parsed = parseCalendarDate(conflict);
              if (parsed == null) continue;
              return l.careItemOccurrenceDuringAbsence(
                formatCalendarDateDisplay(parsed),
              );
            }
            return null;
          },
          orElse: () => null,
        );
    if (line == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        line,
        key: const Key('care_item_schedule_absence_hint'),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

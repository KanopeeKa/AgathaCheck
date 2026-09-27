import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_module.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_section_header.dart';
import '../../../../pet_care/presentation/widgets/care_surface/care_item_stat_row.dart';
import '../../../domain/entities/health_entry.dart';
import '../../../domain/entities/recurrence_anchor.dart';
import '../../widgets/health_entry_form/health_entry_frequency_labels.dart';
import '../../widgets/health_entry_type_labels.dart';
import '../../widgets/pet_event_lifecycle.dart';

/// Schedule summary (spec §Schedule) — stat grid + prose; edit via header action.
class CareItemScheduleSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
          if (entry.nextDueDate != null)
            Text(
              '${l.nextOccurrence}: ${formatHealthEntryCalendarDate(entry.nextDueDate!)}',
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
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

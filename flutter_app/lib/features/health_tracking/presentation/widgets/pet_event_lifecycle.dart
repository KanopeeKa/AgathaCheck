import 'package:flutter/material.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/entities/health_history_entry.dart';
import 'health_entry_form/health_entry_frequency_labels.dart';

/// Whether the event series is closed (W15 close or one-time completed).
bool isHealthEntrySeriesClosed(HealthEntry entry) {
  if (entry.frequency == HealthFrequency.once) {
    return entry.isCompleted;
  }
  if (entry.repeatEndDate == null) return false;
  final today = calendarDateOnly(DateTime.now());
  final end = calendarDateOnly(entry.repeatEndDate!);
  return end.isBefore(today) || end.isAtSameMomentAs(today);
}

String healthEntryEditRoute(HealthEntry entry, String petId) {
  return '/pet/$petId/events/${entry.id}/edit';
}

String formatRecurrenceSummary(AppLocalizations l, HealthEntry entry) {
  if (entry.frequency == HealthFrequency.once) {
    return l.doesNotRepeat;
  }
  final interval = entry.frequencyInterval;
  final period = healthEntryPeriodLabel(l, entry.frequency, interval);
  if (interval == 1) {
    return l.everyPeriod(period);
  }
  if (entry.repeatEndDate != null) {
    return l.recurrenceRepeatsEveryUntil(
      interval,
      period,
      formatHealthEntryCalendarDate(entry.repeatEndDate!),
    );
  }
  return l.everyNPeriods(interval, period);
}

String formatRemindSummary(AppLocalizations l, HealthEntry entry) {
  final count = entry.remindDaysBefore;
  final dayLabel = count == 1 ? l.day : l.days;
  return l.remindedDaysBefore(count, dayLabel);
}

IconData healthEntryTypeIcon(HealthEntryType type) {
  switch (type) {
    case HealthEntryType.medication:
      return Icons.medication;
    case HealthEntryType.preventive:
      return Icons.shield;
    case HealthEntryType.vetVisit:
      return Icons.local_hospital;
    case HealthEntryType.other:
      return Icons.more_horiz;
  }
}

/// History rows sorted by due date (or marked date) descending.
List<HealthHistoryEntry> sortedHistoryDesc(List<HealthHistoryEntry> history) {
  final copy = List<HealthHistoryEntry>.from(history);
  copy.sort((a, b) {
    final ad = a.dueDate ?? a.markedAt;
    final bd = b.dueDate ?? b.markedAt;
    return bd.compareTo(ad);
  });
  return copy;
}

/// Last completed (non-skipped) history row, if any.
HealthHistoryEntry? lastCompletedHistory(List<HealthHistoryEntry> history) {
  final completed = history.where((h) => h.isCompleted).toList()
    ..sort((a, b) {
      final ad = a.dueDate ?? a.markedAt;
      final bd = b.dueDate ?? b.markedAt;
      return bd.compareTo(ad);
    });
  return completed.isEmpty ? null : completed.first;
}

/// Past iterations exclude the current/next occurrence due date when open.
List<HealthHistoryEntry> pastIterationsForEntry(
  HealthEntry entry,
  List<HealthHistoryEntry> history,
) {
  if (entry.frequency == HealthFrequency.once) return const [];
  final sorted = sortedHistoryDesc(history);
  if (!isHealthEntrySeriesClosed(entry) && entry.nextDueDate != null) {
    final nextDay = calendarDateOnly(entry.nextDueDate!);
    return sorted
        .where(
          (h) =>
              h.dueDate == null ||
              !calendarDateOnly(h.dueDate!).isAtSameMomentAs(nextDay),
        )
        .toList();
  }
  if (sorted.length <= 1) return const [];
  return sorted.sublist(1);
}

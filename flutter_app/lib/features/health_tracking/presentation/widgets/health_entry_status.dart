import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

/// Locale-aware `dd MMM yy` (e.g. `01 Jan 26`) for health entry status lines.
final DateFormat healthEntryStatusDateFormat = DateFormat('dd MMM yy');

String formatHealthEntryStatusDate(DateTime date) =>
    healthEntryStatusDateFormat.format(date);

/// Date-only status text: [AppLocalizations.doneOn] when completed, otherwise due date.
String formatHealthEntryStatusLine(HealthEntry entry, AppLocalizations l) {
  if (entry.isCompleted) {
    final doneDate = entry.completedOn ?? entry.updatedAt ?? entry.startDate;
    return l.doneOn(formatHealthEntryStatusDate(doneDate));
  }
  if (entry.nextDueDate == null) return l.notSet;
  return formatHealthEntryStatusDate(entry.nextDueDate!);
}

/// Status color for due/overdue/completed entries (text conveys the date).
Color healthEntryStatusColor(HealthEntry entry, ColorScheme colorScheme) {
  if (entry.isCompleted) return Colors.green;
  if (entry.isOverdue) return colorScheme.error;
  if (entry.isDueToday) return Colors.orange;
  if (entry.isDueSoon) return Colors.amber.shade700;
  return colorScheme.primary;
}

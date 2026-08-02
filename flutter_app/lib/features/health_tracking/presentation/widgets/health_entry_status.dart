import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/utils/calendar_date.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';

/// Locale-aware `dd MMM yy` (e.g. `01 Jan 26`) for health entry status lines.
final DateFormat healthEntryStatusDateFormat = DateFormat('dd MMM yy');

String formatHealthEntryStatusDate(DateTime date) =>
    healthEntryStatusDateFormat.format(calendarDateOnly(date));

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
  if (entry.isCompleted) return AppColorTokens.success;
  if (entry.isOverdue) return colorScheme.error;
  if (entry.isDueToday) return AppColorTokens.warning;
  if (entry.isDueSoon) return AppColorTokens.warning;
  return colorScheme.primary;
}

import 'package:flutter/material.dart';

import 'calendar_date.dart';

/// Locale whose Material date-picker input mode uses day/month/year order.
Locale calendarDatePickerLocale(Locale appLocale) {
  switch (appLocale.languageCode) {
    case 'fr':
      return const Locale('fr', 'FR');
    default:
      return const Locale('en', 'GB');
  }
}

/// Normalized calendar start/end from a Material date-range dialog.
typedef CalendarDateRange = ({DateTime start, DateTime end});

/// Opens a [showDateRangePicker] dialog with dd/mm/yyyy manual entry.
///
/// Returns normalized calendar dates via [calendarDateOnly], or null when
/// cancelled.
Future<CalendarDateRange?> showCalendarDateRangePicker({
  required BuildContext context,
  DateTime? rangeStart,
  DateTime? rangeEnd,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  final appLocale = Localizations.localeOf(context);
  final initialStart = calendarDateOnly(rangeStart ?? rangeEnd ?? firstDate);
  final initialEnd = calendarDateOnly(rangeEnd ?? rangeStart ?? firstDate);
  final normalizedFirst = calendarDateOnly(firstDate);
  final normalizedLast = calendarDateOnly(lastDate);

  return showDateRangePicker(
    context: context,
    locale: calendarDatePickerLocale(appLocale),
    firstDate: normalizedFirst,
    lastDate: normalizedLast,
    initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    helpText: helpText,
    fieldStartHintText: 'dd/mm/yyyy',
    fieldEndHintText: 'dd/mm/yyyy',
  ).then((picked) {
    if (picked == null) return null;
    return (
      start: calendarDateOnly(picked.start),
      end: calendarDateOnly(picked.end),
    );
  });
}

/// Opens a [showDatePicker] dialog with dd/mm/yyyy manual entry.
///
/// Returns a normalized calendar date via [calendarDateOnly], or null when
/// cancelled.
Future<DateTime?> showCalendarDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) {
  final appLocale = Localizations.localeOf(context);
  return showDatePicker(
    context: context,
    locale: calendarDatePickerLocale(appLocale),
    initialDate: initialDate ?? DateTime.now(),
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    fieldHintText: 'dd/mm/yyyy',
  ).then((picked) => picked != null ? calendarDateOnly(picked) : null);
}

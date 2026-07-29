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

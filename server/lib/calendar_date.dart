/// Calendar-date helpers for the Dart shelf server (parity with
/// `server/lib/calendarDate.js` and `flutter_app/lib/core/utils/calendar_date.dart`).

/// Parses API/DB values into a calendar [DateTime] (local date, no time zone shift).
DateTime? parseCalendarDate(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  final datePart = s.split(RegExp(r'[T ]')).first;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  return null;
}

/// Serializes [date] to `YYYY-MM-DD`.
String? toCalendarDateString(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Normalizes request/DB values to `YYYY-MM-DD` for JSON responses and writes.
String? dateToIsoDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return toCalendarDateString(value);
  final parsed = parseCalendarDate(value);
  if (parsed != null) return toCalendarDateString(parsed);
  return null;
}

/// Today's calendar date as `YYYY-MM-DD` in the server local timezone.
String todayCalendarIso() {
  final now = DateTime.now();
  return toCalendarDateString(now)!;
}

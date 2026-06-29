/// Helpers for **calendar dates** (due dates, DOB, weight day, etc.).
///
/// These are wall-clock dates with no meaningful time-of-day. They must be
/// serialized as `YYYY-MM-DD` on the wire — never as UTC timestamps — so users
/// in every timezone see the day they picked.
DateTime? parseCalendarDate(Object? raw) {
  if (raw == null) return null;
  final s = raw.toString().trim();
  if (s.isEmpty) return null;

  final datePart = s.split('T').first;
  final parts = datePart.split('-');
  if (parts.length == 3) {
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y != null && m != null && d != null) {
      return DateTime(y, m, d);
    }
  }
  return DateTime.tryParse(s);
}

/// Serializes [date] to `YYYY-MM-DD` using local calendar components.
String? toCalendarDateString(DateTime? date) {
  if (date == null) return null;
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Strips time from a date-picker value so only the calendar day is kept.
DateTime calendarDateOnly(DateTime date) =>
    DateTime(date.year, date.month, date.day);

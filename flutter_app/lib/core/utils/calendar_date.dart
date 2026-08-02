import 'package:intl/intl.dart';

/// Helpers for **calendar dates** (due dates, DOB, weight day, etc.).
///
/// These are wall-clock dates with no meaningful time-of-day. They must be
/// serialized as `YYYY-MM-DD` on the wire — never as UTC timestamps — so users
/// in every timezone see the day they picked.
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

bool _isUtcMidnight(DateTime date) {
  return date.isUtc &&
      date.hour == 0 &&
      date.minute == 0 &&
      date.second == 0 &&
      date.millisecond == 0 &&
      date.microsecond == 0;
}

/// Wall-clock Y-M-D for [date] in the user's local timezone.
///
/// [showDatePicker] returns local midnight, but on web a [DateTime] can still
/// be UTC-flagged (e.g. July 8 00:00 CEST stored as `…T22:00:00.000Z`). For
/// those instants, normalize through [DateTime.toLocal].
///
/// UTC midnight (`…T00:00:00.000Z`) represents a PostgreSQL `DATE` or a picker
/// value in some web builds — use UTC Y-M-D so users west of UTC do not see the
/// previous day.
DateTime _localCalendarParts(DateTime date) {
  if (date.isUtc) {
    if (_isUtcMidnight(date)) {
      return DateTime(date.year, date.month, date.day);
    }
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
  return DateTime(date.year, date.month, date.day);
}

/// Serializes [date] to `YYYY-MM-DD` using local calendar components.
String? toCalendarDateString(DateTime? date) {
  if (date == null) return null;
  final local = _localCalendarParts(date);
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Strips time from a date-picker value so only the calendar day is kept.
DateTime calendarDateOnly(DateTime date) => _localCalendarParts(date);

/// User-facing calendar date display (`dd/MM/yyyy`).
String formatCalendarDateDisplay(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(calendarDateOnly(date));
}

/// Locale-aware medium calendar date (e.g. `18 Dec 2026`).
String formatCalendarDateMedium(DateTime date) {
  return DateFormat.yMMMd().format(calendarDateOnly(date));
}

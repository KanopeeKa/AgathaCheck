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

/// Wall-clock Y-M-D for [date] in the user's local timezone.
///
/// [showDatePicker] returns local midnight, but on web a [DateTime] can still
/// be UTC-flagged (e.g. July 8 00:00 CEST stored as `…T22:00:00.000Z`). For
/// UTC values, [.year]/[.month]/[.day] read UTC components and shift the day
/// for users east of UTC — always normalize through [DateTime.toLocal] first.
DateTime _localCalendarParts(DateTime date) {
  final local = date.isUtc ? date.toLocal() : date;
  return DateTime(local.year, local.month, local.day);
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

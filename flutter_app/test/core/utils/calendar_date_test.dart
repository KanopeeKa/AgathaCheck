import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';

void main() {
  group('parseCalendarDate', () {
    test('parses date-only string', () {
      final d = parseCalendarDate('2026-06-30');
      expect(d, isNotNull);
      expect(d!.year, 2026);
      expect(d.month, 6);
      expect(d.day, 30);
    });

    test('uses date portion of legacy UTC timestamp', () {
      final d = parseCalendarDate('2026-06-30T00:00:00.000Z');
      expect(d!.day, 30);
    });

    test('parses space-separated legacy timestamp prefix', () {
      final d = parseCalendarDate('2026-06-30 00:00:00.000Z');
      expect(d!.day, 30);
    });

    test('returns null for empty or invalid input', () {
      expect(parseCalendarDate(null), isNull);
      expect(parseCalendarDate(''), isNull);
      expect(parseCalendarDate('not-a-date'), isNull);
    });
  });

  group('toCalendarDateString', () {
    test('serializes local calendar components', () {
      expect(toCalendarDateString(DateTime(2026, 6, 30)), '2026-06-30');
    });

    test('returns null for null input', () {
      expect(toCalendarDateString(null), isNull);
    });

    test('serializes UTC midnight selected day via local wall-clock', () {
      expect(toCalendarDateString(DateTime.utc(2026, 7, 8)), '2026-07-08');
    });
  });

  group('calendarDateOnly', () {
    test('strips time from picker value', () {
      final picked = DateTime(2026, 6, 30, 14, 30);
      final normalized = calendarDateOnly(picked);
      expect(normalized.year, 2026);
      expect(normalized.month, 6);
      expect(normalized.day, 30);
      expect(normalized.hour, 0);
      expect(normalized.minute, 0);
    });

    test('uses local wall-clock for UTC-flagged instants', () {
      // July 8 00:00 CEST == July 7 22:00 UTC. UTC getters yield day 7;
      // calendar dates must use the local wall-clock day the user picked.
      final july8CestMidnightUtc = DateTime.parse('2026-07-07T22:00:00.000Z');
      expect(july8CestMidnightUtc.isUtc, isTrue);
      expect(july8CestMidnightUtc.toUtc().day, 7);

      final normalized = calendarDateOnly(july8CestMidnightUtc);
      expect(
        toCalendarDateString(normalized),
        toCalendarDateString(
          DateTime.parse('2026-07-07T22:00:00.000Z').toLocal(),
        ),
      );
    });
  });
}

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

    test('returns null for empty input', () {
      expect(parseCalendarDate(null), isNull);
      expect(parseCalendarDate(''), isNull);
    });
  });

  group('toCalendarDateString', () {
    test('serializes local calendar components', () {
      expect(
        toCalendarDateString(DateTime(2026, 6, 30)),
        '2026-06-30',
      );
    });

    test('returns null for null input', () {
      expect(toCalendarDateString(null), isNull);
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
  });
}

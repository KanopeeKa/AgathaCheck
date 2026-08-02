import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';

/// Canonical calendar day used across inventory tests (18 Dec 2026).
const calendarFieldYear = 2026;
const calendarFieldMonth = 12;
const calendarFieldDay = 18;
const calendarFieldIso = '2026-12-18';
const calendarFieldLegacyUtc = '2026-12-18T00:00:00.000Z';
const calendarFieldDisplay = '18/12/2026';

/// Web picker: UTC midnight for the calendar day (shifts west of UTC via toLocal).
final calendarFieldUtcMidnightPicker = DateTime.utc(
  calendarFieldYear,
  calendarFieldMonth,
  calendarFieldDay,
);

/// Web picker: local midnight encoded as prior-evening UTC (CEST-style example).
final calendarFieldLocalMidnightPicker =
    DateTime.parse('2026-07-07T22:00:00.000Z');

void expectCalendarDay(DateTime? date) {
  expect(date, isNotNull, reason: 'expected a calendar date');
  expect(date!.year, calendarFieldYear);
  expect(date.month, calendarFieldMonth);
  expect(date.day, calendarFieldDay);
}

void expectCalendarWire(String? wire) {
  expect(wire, calendarFieldIso);
  expect(wire, isNot(contains('T')));
}

void expectCalendarDisplay(DateTime date) {
  expect(formatCalendarDateDisplay(date), calendarFieldDisplay);
}

/// Shared regression checks for any calendar-date field inventory entry.
void expectCalendarDateFieldBehavior({
  required String entity,
  required String field,
  required DateTime? Function() readParsed,
  DateTime? Function()? readFromUtcMidnightPicker,
  String? Function()? readSerializedWire,
}) {
  group('$entity.$field', () {
    test('parse date-only API wire preserves day', () {
      expectCalendarDay(readParsed());
      expectCalendarDisplay(readParsed()!);
    });

    if (readFromUtcMidnightPicker != null) {
      test('serialize UTC-midnight web picker without off-by-one', () {
        final normalized = calendarDateOnly(calendarFieldUtcMidnightPicker);
        expectCalendarDay(normalized);
        expect(toCalendarDateString(normalized), calendarFieldIso);
        expectCalendarDay(readFromUtcMidnightPicker());
      });
    }

    if (readSerializedWire != null) {
      test('serialize to API wire as YYYY-MM-DD', () {
        expectCalendarWire(readSerializedWire());
      });
    }

    test('local-midnight-as-UTC picker uses wall-clock day', () {
      final normalized = calendarDateOnly(calendarFieldLocalMidnightPicker);
      final expectedLocal = calendarFieldLocalMidnightPicker.toLocal();
      expect(normalized.year, expectedLocal.year);
      expect(normalized.month, expectedLocal.month);
      expect(normalized.day, expectedLocal.day);
      expect(
        toCalendarDateString(normalized),
        toCalendarDateString(expectedLocal),
      );
    });
  });
}

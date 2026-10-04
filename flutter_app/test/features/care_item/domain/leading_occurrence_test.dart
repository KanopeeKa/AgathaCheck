import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'care_item_test_data.dart';

void main() {
  group('leadingOccurrence (§18.5)', () {
    test('no open occurrence → null', () {
      expect(
        leadingOccurrence(schedule(const [], at: asOf(10, '09:00'))),
        isNull,
      );
    });

    test('the earliest started occurrence leads', () {
      final s = schedule([
        occ('evening', 10, CareOccurrenceStatus.due, time: '18:00'),
        occ('morning', 10, CareOccurrenceStatus.overdue, time: '08:00'),
        occ('tomorrow', 11, CareOccurrenceStatus.comingUp, time: '08:00'),
      ], at: asOf(10, '10:00'));
      expect(leadingOccurrence(s)?.id, 'morning');
    });

    test('nothing started → the next one to come, even later today', () {
      final s = schedule([
        occ('tomorrow', 11, CareOccurrenceStatus.comingUp),
        occ('evening', 10, CareOccurrenceStatus.due, time: '18:00'),
      ], at: asOf(10, '10:00'));
      expect(leadingOccurrence(s)?.id, 'evening');
    });

    test('a date without a time sorts before timed ones on the same day', () {
      final s = schedule([
        occ('timed', 12, CareOccurrenceStatus.comingUp, time: '07:00'),
        occ('untimed', 12, CareOccurrenceStatus.comingUp),
      ], at: asOf(10, '10:00'));
      expect(leadingOccurrence(s)?.id, 'untimed');
    });
  });

  group('hasEarlierOpenDate (DN-1c)', () {
    test('After it\'s done: a planned date with an earlier overdue one', () {
      final overdue = occ(
        'overdue',
        5,
        CareOccurrenceStatus.overdue,
        origin: CareOccurrenceOrigin.computed,
      );
      final planned = occ(
        'planned',
        1,
        CareOccurrenceStatus.due,
        month: 7,
        origin: CareOccurrenceOrigin.planned,
      );
      final s = schedule(
        [overdue, planned],
        at: asOf(1, '09:00', month: 7),
        fixed: false,
      );
      expect(hasEarlierOpenDate(s, planned), isTrue);
      expect(hasEarlierOpenDate(s, overdue), isFalse);
    });

    test('never for a fixed schedule', () {
      final a = occ('a', 9, CareOccurrenceStatus.notRecorded);
      final b = occ('b', 10, CareOccurrenceStatus.due);
      expect(
        hasEarlierOpenDate(schedule([a, b], at: asOf(10, '09:00')), b),
        isFalse,
      );
    });
  });
}

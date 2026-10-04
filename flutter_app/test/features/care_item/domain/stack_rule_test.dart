import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'care_item_test_data.dart';

void main() {
  group('occurrenceHasStarted (D-CIE-034)', () {
    test('overdue and not recorded have started; coming up has not', () {
      final at = asOf(10, '10:00');
      expect(
        occurrenceHasStarted(occ('a', 9, CareOccurrenceStatus.overdue), at),
        isTrue,
      );
      expect(
        occurrenceHasStarted(occ('b', 8, CareOccurrenceStatus.notRecorded), at),
        isTrue,
      );
      expect(
        occurrenceHasStarted(occ('c', 11, CareOccurrenceStatus.comingUp), at),
        isFalse,
      );
    });

    test('due without a time has started from the beginning of its day', () {
      expect(
        occurrenceHasStarted(
          occ('a', 10, CareOccurrenceStatus.due),
          asOf(10, '00:05'),
        ),
        isTrue,
      );
    });

    test('due with a time starts when the time is reached', () {
      final slot = occ('a', 10, CareOccurrenceStatus.due, time: '18:00');
      expect(occurrenceHasStarted(slot, asOf(10, '17:59')), isFalse);
      expect(occurrenceHasStarted(slot, asOf(10, '18:00')), isTrue);
    });
  });

  group('isStack', () {
    test('DN-1 three not recorded doses of a fixed schedule are a stack', () {
      final s = schedule([
        occ('a', 7, CareOccurrenceStatus.notRecorded),
        occ('b', 8, CareOccurrenceStatus.notRecorded),
        occ('c', 9, CareOccurrenceStatus.overdue),
        occ('d', 11, CareOccurrenceStatus.comingUp),
      ], at: asOf(10, '09:00'));
      expect(isStack(s), isTrue);
      expect(startedOccurrences(s).map((o) => o.id), ['a', 'b', 'c']);
    });

    test(
      'DN-1b daily without a time: yesterday not recorded + today due is a stack (RV-3)',
      () {
        final s = schedule([
          occ('yesterday', 9, CareOccurrenceStatus.notRecorded),
          occ('today', 10, CareOccurrenceStatus.due),
        ], at: asOf(10, '08:00'));
        expect(isStack(s), isTrue);
      },
    );

    test('DN-5b 08:00 overdue with 18:00 later today is not a stack', () {
      final s = schedule([
        occ('morning', 10, CareOccurrenceStatus.overdue, time: '08:00'),
        occ('evening', 10, CareOccurrenceStatus.due, time: '18:00'),
      ], at: asOf(10, '10:00'));
      expect(isStack(s), isFalse);
      expect(isStack(s, asOf: asOf(10, '18:00')), isTrue);
    });

    test('one started slot and coming-up slots are not a stack', () {
      final s = schedule([
        occ('a', 10, CareOccurrenceStatus.due),
        occ('b', 11, CareOccurrenceStatus.comingUp),
      ], at: asOf(10, '09:00'));
      expect(isStack(s), isFalse);
    });

    test('After it\'s done is never a stack (DN-1c is handled separately)', () {
      final s = schedule(
        [
          occ(
            'overdue',
            5,
            CareOccurrenceStatus.overdue,
            origin: CareOccurrenceOrigin.computed,
          ),
          occ(
            'planned',
            9,
            CareOccurrenceStatus.overdue,
            origin: CareOccurrenceOrigin.planned,
          ),
        ],
        at: asOf(10, '09:00'),
        fixed: false,
      );
      expect(isStack(s), isFalse);
    });
  });
}

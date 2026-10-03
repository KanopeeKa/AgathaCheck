import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

import 'care_item_test_data.dart';

CareItemSchedule s(
  List<OpenOccurrence> open, {
  bool fixed = true,
  String family = 'medication',
  int? interval = 30,
  String status = 'active',
  CareAsOf? at,
}) => CareItemSchedule(
  entryId: 'e',
  petId: 'p',
  name: 'Care',
  careFamily: family,
  isFixedSchedule: fixed,
  status: status,
  openOccurrences: open,
  asOf: at ?? asOf(10, '10:00'),
  intervalDays: interval,
);

void main() {
  test('DN-1 a stack opens the Care Item view', () {
    final d = decideDone(
      s([
        occ('a', 8, CareOccurrenceStatus.notRecorded),
        occ('b', 9, CareOccurrenceStatus.notRecorded),
      ]),
    );
    expect(d, isA<DoneOpensCareItem>());
  });

  test('DN-1c After it\'s done with an earlier open date opens the item', () {
    final planned = occ('p', 1, CareOccurrenceStatus.due, month: 7);
    final d = decideDone(
      s(
        [occ('o', 5, CareOccurrenceStatus.overdue), planned],
        fixed: false,
        at: asOf(1, '09:00', month: 7),
      ),
      occurrence: planned,
    );
    expect(d, isA<DoneOpensCareItem>());
  });

  test('DN-2 a weigh-in opens its occurrence with the weight focused', () {
    final d = decideDone(
      s([occ('w', 10, CareOccurrenceStatus.due)], family: 'weight_monitoring'),
    );
    expect(d, isA<DoneOpensOccurrence>());
    expect(
      (d as DoneOpensOccurrence).requirement,
      CompletionRequirement.weight,
    );
    expect(
      decideDone(
        s([
          occ('w', 10, CareOccurrenceStatus.due),
        ], family: 'weight_monitoring'),
        onOccurrenceScreen: true,
      ),
      isA<DoneCompletesToday>(),
    );
  });

  test('DN-3 After it\'s done overdue asks for the date', () {
    final d = decideDone(
      s([occ('o', 5, CareOccurrenceStatus.overdue)], fixed: false),
    );
    expect(d, isA<DoneAsksDate>());
  });

  test('DN-4 more than half an interval early asks to confirm', () {
    expect(
      decideDone(s([occ('m', 30, CareOccurrenceStatus.comingUp)])),
      isA<DoneConfirmsEarly>(),
    );
    expect(
      decideDone(s([occ('m', 20, CareOccurrenceStatus.comingUp)])),
      isA<DoneCompletesToday>(),
    );
  });

  test(
    'DN-5 / DN-5b due completes today; fixed overdue offers Change date',
    () {
      final due = decideDone(s([occ('d', 10, CareOccurrenceStatus.due)]));
      expect((due as DoneCompletesToday).offerChangeDate, isFalse);
      final late = decideDone(
        s([
          occ('m', 10, CareOccurrenceStatus.overdue, time: '08:00'),
          occ('e', 10, CareOccurrenceStatus.due, time: '18:00'),
        ]),
      );
      expect(late, isA<DoneCompletesToday>());
      expect((late as DoneCompletesToday).offerChangeDate, isTrue);
      expect(late.occurrence.id, 'm');
    },
  );

  test('DN-8 paused items open the Care Item view', () {
    expect(
      decideDone(s([occ('d', 10, CareOccurrenceStatus.due)], status: 'paused')),
      isA<DoneOpensCareItem>(),
    );
  });
}

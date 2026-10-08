import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';

OpenOccurrence _open(String id, DateTime date, {String? time}) {
  return OpenOccurrence(
    id: id,
    date: date,
    time: time,
    status: CareOccurrenceStatus.due,
    origin: CareOccurrenceOrigin.schedule,
  );
}

void main() {
  final d1 = DateTime(2026, 6, 10);
  final d2 = DateTime(2026, 6, 12);
  final d3 = DateTime(2026, 6, 15);

  test('returns list successor when current is open in list', () {
    final open = [_open('a', d1), _open('b', d2), _open('c', d3)];
    expect(
      nextOpenOccurrenceAfter(
        openOccurrences: open,
        currentId: 'a',
        currentDate: d1,
      )?.id,
      'b',
    );
  });

  test('returns null when current is last open slot', () {
    final open = [_open('a', d1), _open('b', d2)];
    expect(
      nextOpenOccurrenceAfter(
        openOccurrences: open,
        currentId: 'b',
        currentDate: d2,
      ),
      isNull,
    );
  });

  test('when current not in open, returns first slot after sort key', () {
    final open = [_open('a', d1), _open('b', d2)];
    expect(
      nextOpenOccurrenceAfter(
        openOccurrences: open,
        currentId: 'done-1',
        currentDate: d1,
      )?.id,
      'a',
    );
    expect(
      nextOpenOccurrenceAfter(
        openOccurrences: open,
        currentId: 'done-1',
        currentDate: DateTime(2026, 6, 11),
      )?.id,
      'b',
    );
  });

  test(
    'duplicate instant: first in list with different id wins at compareTo 0',
    () {
      final open = [
        _open('a', d1, time: '09:00'),
        _open('b', d1, time: '09:00'),
      ];
      expect(
        nextOpenOccurrenceAfter(
          openOccurrences: open,
          currentId: 'x',
          currentDate: d1,
          currentTime: '09:00',
        )?.id,
        'a',
      );
    },
  );

  test('in-list index wins over compareTo when current is open', () {
    final open = [_open('a', d1), _open('b', d2)];
    expect(
      nextOpenOccurrenceAfter(
        openOccurrences: open,
        currentId: 'a',
        currentDate: d2,
      )?.id,
      'b',
    );
  });
}

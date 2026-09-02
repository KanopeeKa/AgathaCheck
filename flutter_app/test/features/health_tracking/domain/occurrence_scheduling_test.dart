import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/utils/calendar_date.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_occurrence.dart';
import 'package:pet_profile_app/features/health_tracking/domain/occurrence_scheduling.dart';

void main() {
  HealthOccurrence occ({
    required String id,
    required DateTime date,
    String? time,
    String status = 'pending',
  }) {
    return HealthOccurrence(
      id: id,
      entryId: 'entry-1',
      scheduledDate: date,
      scheduledTime: time,
      status: status,
    );
  }

  group('isOccurrenceMissed', () {
    test('all-day pending yesterday is missed', () {
      final yesterday = calendarDateOnly(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(
        isOccurrenceMissed(occ(id: 'a', date: yesterday), DateTime.now()),
        isTrue,
      );
    });

    test('timed dose today before now is missed', () {
      final today = calendarDateOnly(DateTime.now());
      final now = DateTime.now();
      final pastHour = (now.hour > 0) ? now.hour - 1 : 0;
      final time =
          '${pastHour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      expect(
        isOccurrenceMissed(occ(id: 'a', date: today, time: time), now),
        isTrue,
      );
    });

    test('future timed dose today is not missed', () {
      final today = calendarDateOnly(DateTime.now());
      expect(
        isOccurrenceMissed(occ(id: 'a', date: today, time: '23:59'), DateTime.now()),
        isFalse,
      );
    });
  });

  group('summarizeOpenOccurrences', () {
    test('missed LIFO head and FIFO next', () {
      final today = calendarDateOnly(DateTime.now());
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));
      final now = DateTime(today.year, today.month, today.day, 7, 0);

      final open = [
        occ(id: 'missed-old', date: yesterday, time: '08:00'),
        occ(id: 'missed-new', date: yesterday, time: '20:00'),
        occ(id: 'today-am', date: today, time: '08:00'),
        occ(id: 'today-pm', date: today, time: '20:00'),
        occ(id: 'tomorrow', date: tomorrow, time: '08:00'),
      ];

      final summary = summarizeOpenOccurrences(open, now);
      expect(summary.openCount, 5);
      expect(summary.missedCount, 2);
      expect(summary.missedHead?.id, 'missed-new');
      expect(summary.nextHead?.id, 'today-am');
    });
  });
}

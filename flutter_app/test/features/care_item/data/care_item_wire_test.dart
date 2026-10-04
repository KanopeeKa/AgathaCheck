import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_wire.dart';

import '../application/care_api_fixtures.dart';

void main() {
  test('parses a care item read with open occurrences sorted', () {
    final s = careItemScheduleFromJson(
      careItemJson(
        anchor: 'from_due_date',
        family: 'medication',
        open: [
          {
            'id': 'evening',
            'scheduled_date': '2026-06-10',
            'scheduled_time': '18:00:00',
            'status': 'due',
            'origin': 'schedule',
          },
          {
            'id': 'morning',
            'scheduled_date': '2026-06-10',
            'scheduled_time': '08:00',
            'status': 'overdue',
            'origin': 'schedule',
          },
          {
            'id': 'missed',
            'scheduled_date': '2026-06-09',
            'scheduled_time': '18:00',
            'status': 'not_recorded',
            'origin': 'schedule',
          },
        ],
      ),
    );
    expect(s.isFixedSchedule, isTrue);
    expect(s.careFamily, 'medication');
    expect(s.openOccurrences.map((o) => o.id), [
      'missed',
      'morning',
      'evening',
    ]);
    expect(s.openOccurrences.last.time, '18:00');
    expect(s.openOccurrences.first.status, CareOccurrenceStatus.notRecorded);
    expect(s.asOf.date, DateTime(2026, 6, 10));
    expect(s.asOf.minutes, 9 * 60);
  });

  test('parses estimated next, pause fields and unknown values safely', () {
    final json = careItemJson()
      ..['estimated_next'] = {'date': '2026-07-12', 'basis': 'done_today'}
      ..['status'] = 'paused'
      ..['paused_until'] = '2026-06-20'
      ..['resume_default_date'] = '2026-06-21';
    (json['open_occurrences'] as List).add({
      'id': 'x',
      'scheduled_date': '2026-07-20',
      'status': 'something_new',
      'origin': null,
    });
    final s = careItemScheduleFromJson(json);
    expect(s.estimatedNext?.date, DateTime(2026, 7, 12));
    expect(s.isPaused, isTrue);
    expect(s.pausedUntil, DateTime(2026, 6, 20));
    expect(s.resumeDefaultDate, DateTime(2026, 6, 21));
    expect(s.openOccurrences.last.status, CareOccurrenceStatus.unknown);
    expect(s.openOccurrences.last.origin, CareOccurrenceOrigin.computed);
  });

  test('a read without as_of is rejected', () {
    final json = careItemJson()..remove('as_of');
    expect(() => careItemScheduleFromJson(json), throwsA(isA<TypeError>()));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/data/care_item_wire.dart';

void main() {
  test(
    'occurrenceDetailFromJson parses schedule when entry has open_occurrences',
    () {
      final detail = occurrenceDetailFromJson({
        'occurrence': {
          'id': 'occ-b',
          'scheduled_date': '2026-06-12',
          'status': 'pending',
          'occurrence_status': 'due',
          'origin': 'computed',
        },
        'entry': {
          'id': 'entry-1',
          'pet_id': 'pet-1',
          'name': 'Flea',
          'care_family': 'parasite_prevention',
          'frequency': 'monthly',
          'frequency_interval': 1,
          'recurrence_anchor': 'from_completion',
          'status': 'active',
          'next_due_date': '2026-06-05',
          'open_occurrences': [
            {
              'id': 'occ-a',
              'scheduled_date': '2026-06-05',
              'status': 'overdue',
              'origin': 'computed',
            },
            {
              'id': 'occ-b',
              'scheduled_date': '2026-06-12',
              'status': 'coming_up',
              'origin': 'computed',
            },
          ],
          'as_of': {
            'date': '2026-06-10',
            'time': '09:00',
            'timezone': 'Europe/Paris',
          },
          'estimated_next': null,
        },
        'last_action': null,
      });

      expect(detail.schedule, isNotNull);
      expect(detail.schedule!.openOccurrences, hasLength(2));
      expect(detail.schedule!.intervalDays, 30);
    },
  );

  test('occurrenceDetailFromJson parses neighbour summaries', () {
    final detail = occurrenceDetailFromJson({
      'occurrence': {
        'id': 'occ-mid',
        'scheduled_date': '2026-06-10',
        'status': 'pending',
        'occurrence_status': 'due',
        'origin': 'computed',
      },
      'entry': {
        'id': 'entry-1',
        'pet_id': 'pet-1',
        'name': 'Flea',
        'status': 'active',
        'as_of': {'date': '2026-06-10', 'time': '09:00', 'timezone': 'UTC'},
      },
      'previous_occurrence': {
        'id': 'occ-prev',
        'scheduled_date': '2026-06-05',
        'occurrence_status': 'done',
        'completed_on': '2026-06-05',
      },
      'next_occurrence': {
        'id': 'occ-next',
        'scheduled_date': '2026-06-15',
        'scheduled_time': '08:00',
        'occurrence_status': 'coming_up',
      },
    });

    expect(detail.previousOccurrence?.id, 'occ-prev');
    expect(detail.nextOccurrence?.scheduledTime, '08:00');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/data/models/health_entry_absence_context_model.dart';

void main() {
  test('fromJson parses review_occurrence and planned_care', () {
    final context = HealthEntryAbsenceContext.fromJson({
      'health_entry_id': 'entry-1',
      'pet_id': 'pet-1',
      'absences': [
        {
          'planned_absence_id': 'abs-1',
          'starts_on': '2026-10-01',
          'ends_on': '2026-10-05',
          'affected': true,
          'ui_state': 'not_reviewed',
          'review_occurrence': {
            'occurrence_id': 'occ-review',
            'scheduled_date': '2026-10-02',
            'scheduled_time': '08:00',
          },
          'planned_care': {
            'kind': 'single_once',
            'health_entry_id': 'entry-1',
            'name': 'Meds',
            'occurrence_id': 'occ-review',
            'scheduled_date': '2026-10-02',
          },
        },
      ],
    });

    final slice = context.absences.single;
    expect(slice.reviewOccurrence?.occurrenceId, 'occ-review');
    expect(slice.reviewOccurrence?.scheduledDate, '2026-10-02');
    expect(slice.reviewOccurrence?.scheduledTime, '08:00');
    expect(slice.plannedCare?.resolvedOccurrenceId, 'occ-review');
  });
}

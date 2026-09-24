import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/data/models/care_period_coverage_model.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';

void main() {
  test('fromJson parses planned_care_items and keeps items unchanged', () {
    final result = CarePeriodCoverageModel.fromJson({
      'starts_on': '2026-10-01',
      'ends_on': '2026-10-05',
      'projection_status': 'complete',
      'items': [
        {
          'health_entry_id': 'raw-1',
          'scheduled_date': '2026-10-02',
          'status': 'pending',
          'source': 'projected',
          'name': 'Raw item',
          'type': 'medication',
          'care_family': 'medication',
        },
      ],
      'planned_care_items': [
        {
          'kind': 'single_once',
          'health_entry_id': 'raw-1',
          'name': 'Raw item',
          'type': 'medication',
          'care_family': 'medication',
          'frequency': 'once',
          'frequency_interval': 1,
          'times_of_day': [],
          'scheduled_date': '2026-10-02',
          'status': 'pending',
        },
        {
          'kind': 'recurring_chain',
          'health_entry_id': 'chain-1',
          'name': 'Booster',
          'frequency': 'weekly',
          'frequency_interval': 1,
          'times_of_day': ['09:00'],
          'first_scheduled_date': '2026-10-01',
          'last_scheduled_date': '2026-10-03',
          'open_occurrence': {
            'occurrence_id': 'occ-1',
            'scheduled_date': '2026-09-20',
            'open_status': 'overdue',
          },
          'in_window': {
            'first_date': '2026-10-02',
            'last_date': '2026-10-02',
            'count': 1,
            'date_basis': 'estimated',
          },
          'is_paused': false,
        },
      ],
      'coverage': {
        'policy_version': '1',
        'coverage_state': 'has_items_to_review',
        'reason_codes': [],
        'reassurance_available': true,
      },
    });

    expect(result.items, hasLength(1));
    expect(result.items.first.healthEntryId, 'raw-1');
    expect(result.plannedCareItems, hasLength(2));
    expect(result.plannedCareItems.first.kind, PlannedCareKind.singleOnce);
    expect(result.plannedCareItems.last.kind, PlannedCareKind.recurringChain);
    expect(result.plannedCareItems.last.openOccurrence?.openStatus, 'overdue');
    expect(result.plannedCareItems.last.inWindow?.dateBasis, 'estimated');
    expect(result.showsEstimateFootnote, isTrue);
    expect(result.showsChainAnchorExplainer, isFalse);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_care/context/domain/entities/care_period_coverage.dart';

void main() {
  test('resolvedOccurrenceId prefers open_occurrence id', () {
    const item = PlannedCareItem(
      kind: PlannedCareKind.singleOnce,
      healthEntryId: 'entry-1',
      name: 'Meds',
      occurrenceId: 'row-id',
      openOccurrence: PlannedCareOpenOccurrence(
        occurrenceId: 'open-id',
        scheduledDate: '2026-10-03',
        openStatus: 'in_window',
      ),
    );
    expect(item.resolvedOccurrenceId, 'open-id');
  });

  test('resolvedOccurrenceId falls back to row occurrence_id', () {
    const item = PlannedCareItem(
      kind: PlannedCareKind.singleOnce,
      healthEntryId: 'entry-1',
      name: 'Vet',
      occurrenceId: 'occ-99',
      scheduledDate: '2026-10-03',
    );
    expect(item.resolvedOccurrenceId, 'occ-99');
  });
}

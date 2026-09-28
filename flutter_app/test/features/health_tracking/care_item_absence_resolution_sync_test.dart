import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/presentation/providers/care_item_absence_resolution_sync.dart';

void main() {
  test('inferResolutionDecisionAfterReschedule returns move_before', () {
    expect(
      inferResolutionDecisionAfterReschedule(
        newScheduledDate: '2026-10-20',
        absenceStartsOn: '2026-10-25',
        absenceEndsOn: '2026-10-30',
      ),
      'move_before',
    );
  });

  test('inferResolutionDecisionAfterReschedule returns move_after', () {
    expect(
      inferResolutionDecisionAfterReschedule(
        newScheduledDate: '2026-11-01',
        absenceStartsOn: '2026-10-25',
        absenceEndsOn: '2026-10-30',
      ),
      'move_after',
    );
  });

  test('inferResolutionDecisionAfterReschedule returns null in window', () {
    expect(
      inferResolutionDecisionAfterReschedule(
        newScheduledDate: '2026-10-27',
        absenceStartsOn: '2026-10-25',
        absenceEndsOn: '2026-10-30',
      ),
      isNull,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

import '../../../../../helpers/care_schedule_entries.dart';

void main() {
  test('countCareListAttentionToday excludes upcoming and quiet-done', () {
    final entries = [
      scheduledEntry(id: 'overdue', name: 'Flea', dueInDays: -1),
      scheduledEntry(id: 'today', name: 'Brush', dueInDays: 0),
      scheduledEntry(id: 'up', name: 'Groom', dueInDays: 14),
    ];

    expect(countCareListAttentionToday(entries, (e) => e.schedule), 2);
  });
}

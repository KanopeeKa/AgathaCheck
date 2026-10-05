import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';

import '../../../helpers/care_schedule_entries.dart';

void main() {
  test('partitionOpenOccurrences splits started vs upcoming', () {
    final today = careToday();
    final entry = scheduledEntry(
      id: 'med',
      name: 'Med',
      fixed: true,
      frequency: HealthFrequency.daily,
      asOfTime: '14:00',
      open: [
        OpenOccurrence(
          id: 'past',
          date: today.subtract(const Duration(days: 1)),
          time: '08:00',
          status: CareOccurrenceStatus.overdue,
          origin: CareOccurrenceOrigin.schedule,
        ),
        OpenOccurrence(
          id: 'due-now',
          date: today,
          time: '08:00',
          status: CareOccurrenceStatus.due,
          origin: CareOccurrenceOrigin.schedule,
        ),
        OpenOccurrence(
          id: 'later',
          date: today,
          time: '20:00',
          status: CareOccurrenceStatus.due,
          origin: CareOccurrenceOrigin.schedule,
        ),
        OpenOccurrence(
          id: 'future',
          date: today.add(const Duration(days: 2)),
          time: '08:00',
          status: CareOccurrenceStatus.comingUp,
          origin: CareOccurrenceOrigin.schedule,
        ),
      ],
    );
    final groups = partitionOpenOccurrences(entry.schedule!);
    expect(groups.started.map((o) => o.id), ['past', 'due-now']);
    expect(groups.upcoming.map((o) => o.id), ['later', 'future']);
    expect(
      isLaterTodayUpcoming(groups.upcoming.first, entry.schedule!.asOf),
      isTrue,
    );
  });
}

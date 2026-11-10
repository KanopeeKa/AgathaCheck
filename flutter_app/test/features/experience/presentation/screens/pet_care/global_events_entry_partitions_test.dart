import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/health_tracking/domain/entities/health_entry.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/pet_care/care_list/global_events_entry_partitions.dart';

import '../../../../../helpers/care_schedule_entries.dart';

void main() {
  test('splits agenda, paused and closed entries', () {
    final active = scheduledEntry(id: 'active', name: 'Active', dueInDays: 0);
    final paused = scheduledEntry(
      id: 'paused',
      name: 'Paused',
      dueInDays: 10,
      entryStatus: 'paused',
    );
    final closed = scheduledEntry(
      id: 'closed',
      name: 'Closed',
      dueInDays: 5,
      frequency: HealthFrequency.once,
      entryStatus: 'closed',
    );
    final visible = [active, paused, closed];
    final agendaIds = {active.id};

    final parts = GlobalEventsEntryPartitions.fromVisible(
      visible,
      agendaEntryIds: agendaIds,
    );

    expect(parts.planned.map((e) => e.id), ['active']);
    expect(parts.paused.map((e) => e.id), ['paused']);
    expect(parts.closed.map((e) => e.id), ['closed']);
  });
}

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';

import '../../../pet_profile/widgets/all_care/all_care_closed.dart';
import '../../../pet_profile/widgets/all_care/all_care_inactive_section.dart';

/// Splits filtered global list entries into agenda, paused, and closed buckets.
class GlobalEventsEntryPartitions {
  const GlobalEventsEntryPartitions({
    required this.planned,
    required this.paused,
    required this.closed,
  });

  final List<HealthEntry> planned;
  final List<HealthEntry> paused;
  final List<HealthEntry> closed;

  bool get isEmpty => planned.isEmpty && paused.isEmpty && closed.isEmpty;

  static GlobalEventsEntryPartitions fromVisible(
    List<HealthEntry> visible, {
    required Set<String> agendaEntryIds,
  }) {
    final planned = visible
        .where((e) => agendaEntryIds.contains(e.id))
        .toList();
    final notPlanned = visible
        .where((e) => !agendaEntryIds.contains(e.id))
        .toList();
    final closed = partitionClosedCareEntries(notPlanned);
    final closedIds = closed.map((e) => e.id).toSet();
    final paused = sortInactiveAllCareEntries(
      notPlanned.where((e) => !closedIds.contains(e.id)).toList(),
    );
    return GlobalEventsEntryPartitions(
      planned: planned,
      paused: paused,
      closed: closed,
    );
  }
}

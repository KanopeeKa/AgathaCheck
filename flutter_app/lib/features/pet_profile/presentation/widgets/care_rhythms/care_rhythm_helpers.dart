import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';

/// Recurring [HealthEntry] rows for the Care Rhythms screen (no second engine).
List<HealthEntry> filterCareRhythms(List<HealthEntry> entries) {
  return entries
      .where((entry) => entry.frequency != HealthFrequency.once)
      .toList()
    ..sort(_compareCareRhythms);
}

int _compareCareRhythms(HealthEntry a, HealthEntry b) {
  final aClosed = isHealthEntrySeriesClosed(a);
  final bClosed = isHealthEntrySeriesClosed(b);
  if (aClosed != bClosed) {
    return aClosed ? 1 : -1;
  }
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

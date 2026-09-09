import '../../../../health_tracking/domain/entities/health_entry.dart';
import '../../../../health_tracking/presentation/widgets/pet_event_lifecycle.dart';
import '../../../../pet_care/core/care_family_capabilities.dart';
import '../../../domain/entities/care_establishment.dart';

/// Health entry ids with server-reported establishment for eligible care families.
Set<String> establishedRhythmEntryIds(
  List<CareEstablishment> establishments,
  List<HealthEntry> rhythms,
) {
  final rhythmIds = rhythms.map((e) => e.id).toSet();
  final ids = <String>{};
  for (final establishment in establishments) {
    if (!rhythmIds.contains(establishment.healthEntryId)) continue;
    if (!CareFamilyCapabilityPolicy.supportsEstablishment(
      establishment.careFamily,
    )) {
      continue;
    }
    ids.add(establishment.healthEntryId);
  }
  return ids;
}

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

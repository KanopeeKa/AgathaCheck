import '../../../health_tracking/domain/entities/health_entry.dart';
import '../../domain/entities/care_establishment.dart';
import '../../../pet_care/core/care_family_capabilities.dart';

/// Health entry ids with server-reported establishment for eligible care families.
Set<String> establishedRhythmEntryIds(
  List<CareEstablishment> establishments,
  List<HealthEntry> entries,
) {
  final entryIds = entries.map((e) => e.id).toSet();
  final ids = <String>{};
  for (final establishment in establishments) {
    if (!entryIds.contains(establishment.healthEntryId)) continue;
    if (!CareFamilyCapabilityPolicy.supportsEstablishment(
      establishment.careFamily,
    )) {
      continue;
    }
    ids.add(establishment.healthEntryId);
  }
  return ids;
}

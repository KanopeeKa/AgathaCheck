import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

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

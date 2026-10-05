import 'package:pet_profile_app/features/care_taxonomy/care_taxonomy.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'care_family_write.dart';

/// Effective care family for list filters — persisted value or legacy type default.
CareFamily effectiveCareFamilyForFilter(HealthEntry entry) {
  return entry.careFamily ?? defaultCareFamilyForEntryType(entry.type);
}

/// Filter chip group for an entry, derived from its effective care family.
CareFilterGroup filterGroupForEntry(HealthEntry entry) {
  final family = effectiveCareFamilyForFilter(entry);
  return CareTaxonomy.definitionFor(family)?.filterGroup ??
      CareFilterGroup.lifestyle;
}

bool matchesCareFamilyFilters(HealthEntry entry, Set<CareFamily> families) {
  if (families.isEmpty) return true;
  return families.contains(effectiveCareFamilyForFilter(entry));
}

bool matchesCareFilterGroupFilters(
  HealthEntry entry,
  Set<CareFilterGroup> filterGroups,
) {
  if (filterGroups.isEmpty) return true;
  return filterGroups.contains(filterGroupForEntry(entry));
}

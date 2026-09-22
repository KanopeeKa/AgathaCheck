import '../../../care_taxonomy/domain/care_family_definition.dart';
import '../../../care_taxonomy/domain/care_taxonomy.dart';
import '../../../health_tracking/domain/entities/health_entry.dart';
import '../entities/care_family.dart';
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

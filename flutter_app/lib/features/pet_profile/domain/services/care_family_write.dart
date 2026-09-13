import '../../../health_tracking/domain/entities/health_entry.dart';
import '../entities/care_family.dart';

/// Families guardians may pick when creating a recurring care rhythm manually.
const kRecurringCareFamilyPickerOptions = [
  CareFamily.medication,
  CareFamily.vaccination,
  CareFamily.parasitePrevention,
  CareFamily.wellnessReview,
  CareFamily.dental,
  CareFamily.weightMonitoring,
  CareFamily.grooming,
  CareFamily.nailCare,
  CareFamily.other,
];

/// Default care family when the entry type maps cleanly (non-recurring inference).
CareFamily defaultCareFamilyForEntryType(HealthEntryType type) {
  return switch (type) {
    HealthEntryType.medication => CareFamily.medication,
    HealthEntryType.vetVisit => CareFamily.wellnessReview,
    HealthEntryType.preventive => CareFamily.parasitePrevention,
    HealthEntryType.other => CareFamily.other,
  };
}

/// Whether the recurring write path must send an explicit [care_family] to the API.
bool requiresExplicitCareFamily(HealthFrequency frequency) =>
    frequency != HealthFrequency.once;

/// Resolves the care family to persist on create/update.
///
/// Create always requires an explicit [selected] value (validated before call).
/// Edit keeps [existing] when the carer did not choose a family (uncategorised
/// legacy rows stay valid).
CareFamily? resolveCareFamilyForWrite({
  required HealthFrequency frequency,
  required HealthEntryType type,
  CareFamily? selected,
  CareFamily? existing,
  bool isCreate = false,
}) {
  if (isCreate) {
    return selected;
  }
  if (!requiresExplicitCareFamily(frequency)) {
    return selected ?? existing;
  }
  return selected ?? existing;
}

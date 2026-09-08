import '../../../health_tracking/domain/entities/health_entry.dart';
import '../entities/care_family.dart';

/// Conservative backfill when persisted [CareFamily] is absent.
CareFamily inferCareFamily(HealthEntry entry) {
  if (entry.careFamily != null) return entry.careFamily!;
  return switch (entry.type) {
    HealthEntryType.medication => CareFamily.medication,
    HealthEntryType.vetVisit => CareFamily.wellnessReview,
    HealthEntryType.preventive => CareFamily.other,
    HealthEntryType.other => CareFamily.other,
  };
}

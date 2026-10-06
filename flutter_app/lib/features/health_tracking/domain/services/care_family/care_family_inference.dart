import '../../entities/health_entry.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

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

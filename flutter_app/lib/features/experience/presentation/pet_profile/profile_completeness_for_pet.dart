import 'package:pet_profile_app/features/care_intelligence/care_intelligence.dart';
import 'package:pet_profile_app/features/pet_profile/pet_profile.dart';

/// Which Agatha completeness cards apply for [pet] (experience layer — avoids R6).
List<ProfileCompletenessKind> profileCompletenessKindsForPet(
  Pet pet, {
  required AgathaSurfacePolicy policy,
  required DateTime now,
  DateTime? neuterDismissedAt,
  DateTime? chipDismissedAt,
}) {
  final kinds = <ProfileCompletenessKind>[];
  // Neuter unknown → welfare suggestion (PR-08); chip unknown stays here (PR-04).
  if (policy.shouldOfferCompletenessKind(
    kind: ProfileCompletenessKind.chip,
    statusUnknown: pet.identificationStatus == profileFactStatusUnknown,
    dismissedOnPet: pet.chipDismissed,
    dismissedAt: chipDismissedAt,
    now: now,
  )) {
    kinds.add(ProfileCompletenessKind.chip);
  }
  return kinds;
}

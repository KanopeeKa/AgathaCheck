import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Refreshes care item detail and away-plan surfaces after absence resolution.
void invalidateCareItemDetailWithAbsence(
  WidgetRef ref,
  String entryId, {
  String? absenceId,
}) {
  invalidateCareItemDetailData(ref, entryId);
  if (absenceId != null && absenceId.isNotEmpty) {
    ref.invalidate(absenceCarePlanProvider(absenceId));
  }
  ref.invalidate(carePeriodCoverageProvider);
}

import 'package:flutter/material.dart';

import 'package:pet_profile_app/l10n/app_localizations.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

String petCareTemporalGroupLabel(
  AppLocalizations l10n,
  CareTemporalGroup group,
) {
  return switch (group) {
    CareTemporalGroup.needsAttention => l10n.careStatusTimeToFollowUp,
    CareTemporalGroup.today => l10n.urgencyDueToday,
    CareTemporalGroup.upcoming => l10n.occurrenceZoneComingUp,
  };
}

IconData petCareTemporalGroupIcon(CareTemporalGroup group) {
  return switch (group) {
    CareTemporalGroup.needsAttention => Icons.error_outline,
    CareTemporalGroup.today => Icons.today_outlined,
    CareTemporalGroup.upcoming => Icons.schedule_outlined,
  };
}

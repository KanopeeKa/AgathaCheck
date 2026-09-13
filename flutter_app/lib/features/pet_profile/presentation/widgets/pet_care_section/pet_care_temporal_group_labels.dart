import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../pet_care/domain/care_temporal_group.dart';

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

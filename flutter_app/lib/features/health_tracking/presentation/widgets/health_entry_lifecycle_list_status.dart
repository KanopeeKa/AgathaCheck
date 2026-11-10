import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_entry.dart';
import '../../domain/health_entry_series_closed.dart';
import 'health_entry_status.dart';
import 'pet_event_lifecycle.dart';

/// Paused or closed rows on care lists (CARE-STATUS-MODEL-R-026–R-028).
bool healthEntryUsesLifecycleListRow(HealthEntry entry) {
  if (entry.isPaused) return true;
  if (entry.status == 'closed' || entry.status == 'completed') return true;
  return isHealthEntrySeriesClosed(entry);
}

String? careClosedReasonForDisplay(HealthEntry entry) {
  if (entry.status == 'closed') return entry.careClosedReason;
  return null;
}

String formatHealthEntryLifecycleStatusLabel(
  HealthEntry entry,
  AppLocalizations l,
) {
  if (entry.isPaused) return l.careItemPausedStatus;
  return formatHealthEntryClosedStatusLabel(
    l,
    careClosedReasonForDisplay(entry),
  );
}

String formatHealthEntryClosedStatusLabel(
  AppLocalizations l,
  String? careClosedReason,
) {
  if (careClosedReason == kCareClosedReasonStoppedByUser) {
    return l.careItemClosedByYou;
  }
  return l.careItemEndedStatus;
}

HealthEntryStatusTreatment healthEntryLifecycleStatusTreatment(
  HealthEntry entry,
  ColorScheme colorScheme,
) {
  if (entry.isPaused) {
    return HealthEntryStatusTreatment(
      kind: HealthEntryStatusKind.paused,
      icon: Icons.pause_circle_outlined,
      foregroundColor: colorScheme.onSurfaceVariant,
      iconColor: colorScheme.onSurfaceVariant,
      backgroundColor: colorScheme.surfaceContainerHighest,
    );
  }
  return HealthEntryStatusTreatment(
    kind: HealthEntryStatusKind.lifecycleClosed,
    icon: Icons.stop_circle_outlined,
    foregroundColor: colorScheme.onSurfaceVariant,
    iconColor: colorScheme.onSurfaceVariant,
    backgroundColor: colorScheme.surfaceContainerHighest,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/providers/analytics_providers.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Skip one open occurrence from the Care date screen (shared by identity + module).
///
/// Returns null when the user dismisses the weigh-in skip sheet without confirming.
Future<CareOutcome<CareCommandResult>?> runOccurrenceSkip(
  WidgetRef ref, {
  required OccurrenceDetail detail,
  required BuildContext context,
}) async {
  final service = ref.read(careCompletionServiceProvider);
  final occ = detail.occurrence;
  if (detail.item.careFamily == kWeightMonitoringFamily) {
    final skip = await showSkipWeighInSheet(context);
    if (skip == null) {
      return null;
    }
    final outcome = await service.skip(
      entryId: detail.item.id,
      occurrenceId: occ.id,
      reasonCode: skip.reasonCode,
      notes: skip.notes,
    );
    await ref.read(analyticsServiceProvider).capture('weigh_in_skipped', {
      'reason_code': skip.reasonCode ?? '',
    });
    return outcome;
  }
  return service.skip(entryId: detail.item.id, occurrenceId: occ.id);
}

String occurrenceSkipSuccessMessage(
  AppLocalizations l,
  OccurrenceDetail detail,
) {
  return l.careSkipped(detail.item.name);
}

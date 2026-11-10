import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/pet_care_section/pet_care_action_row_builder.dart';
import '../../widgets/pet_list/home_event_actions.dart';

/// One closed care row: active-row subtitle with cadence, grey status pill (R-026–R-028).
class ClosedCareRow extends StatelessWidget {
  const ClosedCareRow({
    super.key,
    required this.entry,
    required this.establishedEntryIds,
  });

  final HealthEntry entry;
  final Set<String> establishedEntryIds;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return PetCareActionRowBuilder(
      entry: entry,
      l10n: l,
      colorScheme: Theme.of(context).colorScheme,
      isEstablished: establishedEntryIds.contains(entry.id),
      rowSemanticsIdentifier: 'closed_care_row_${entry.id}',
      onTap: () => HomeEventActions.viewEntry(context, entry),
    ).build();
  }
}

String closedCareStatusLabel(AppLocalizations l, String? careClosedReason) {
  return formatHealthEntryClosedStatusLabel(l, careClosedReason);
}

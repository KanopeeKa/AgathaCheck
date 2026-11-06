import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/care_taxonomy/care_taxonomy.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../widgets/all_care/all_care_closed_copy.dart';
import '../../widgets/pet_list/home_event_actions.dart';

/// One closed care row: family subtitle only, status line without dates (R-021).
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
    final isEstablished = establishedEntryIds.contains(entry.id);

    final statusLabel = closedCareStatusLabel(
      l,
      entry.status == 'closed' ? entry.careClosedReason : null,
    );

    final family = entry.careFamily ?? inferCareFamily(entry);
    final familyLabel = careFamilyLabel(l, family);
    final subtitleParts = <String>[familyLabel];
    if (isEstablished) {
      subtitleParts.add(l.careProgressionEstablishedMarker);
    }
    final subtitle = subtitleParts.join(' · ');
    final semanticLabel = '${entry.name}, $statusLabel';

    return CareActionRow(
      key: Key('closed_care_row_${entry.id}'),
      title: entry.name,
      subtitle: subtitle,
      statusLabel: statusLabel,
      statusTreatment: completedStatusTreatment(),
      semanticLabel: semanticLabel,
      leading: CareFamilyIcon.forEntry(entry),
      rowSemanticsIdentifier: 'closed_care_row_${entry.id}',
      onTap: () => HomeEventActions.viewEntry(context, entry),
    );
  }
}

String closedCareStatusLabel(AppLocalizations l, String? careClosedReason) {
  return closedCareRowStatusLabel(l, careClosedReason);
}

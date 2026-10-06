import 'package:flutter/material.dart';

import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/experience/presentation/care_item/care_item_occurrence_status_pill.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Occurrence-level status pill for this date (D-OCC-005).
class OccurrenceStatusSection extends StatelessWidget {
  const OccurrenceStatusSection({super.key, required this.detail});

  final OccurrenceDetail detail;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final occ = detail.occurrence;
    final pill = occ.isClosedNotRecorded
        ? closedNotRecordedPillStyle(l)
        : openOccurrencePillStyle(l, occ.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.occurrenceStatusSectionTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        CareItemOccurrenceStatusPill(
          key: const Key('occurrence_status'),
          pill: pill,
        ),
      ],
    );
  }
}

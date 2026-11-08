import 'package:flutter/material.dart';

import 'package:pet_profile_app/core/theme/app_color_tokens.dart';
import 'package:pet_profile_app/core/utils/care_instant_format.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Full-width “Recorded … by …” footer on closed Done / Skipped care dates.
class OccurrenceRecordedAttributionLine extends StatelessWidget {
  const OccurrenceRecordedAttributionLine({
    super.key,
    required this.occurrence,
  });

  final CareOccurrence occurrence;

  @override
  Widget build(BuildContext context) {
    if (!occurrence.showsRecordedAttribution) return const SizedBox.shrink();

    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final markedAt = occurrence.markedAt!;
    final user = occurrence.markedByName?.trim().isNotEmpty == true
        ? occurrence.markedByName!.trim()
        : l.unknownUser;
    final date = formatCareRecordedCalendarDate(markedAt);
    final time = formatCareWallClockTime24(markedAt);
    final line = l.occurrenceRecordedAttribution(date, time, user);

    final isDone = occurrence.isDone;
    final icon = Icon(
      isDone ? Icons.check_circle : Icons.skip_next,
      size: 20,
      color: isDone
          ? AppColorTokens.success
          : theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      container: true,
      label: line,
      identifier: 'occurrence_recorded_attribution',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: 8),
              Expanded(child: Text(line, style: theme.textTheme.bodyMedium)),
            ],
          ),
          if (occurrence.notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                occurrence.notes,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

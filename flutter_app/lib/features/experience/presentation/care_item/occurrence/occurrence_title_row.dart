import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Scheduled date/time and Reschedule control (D-OCC-004, D-OCC-006).
class OccurrenceTitleRow extends StatelessWidget {
  const OccurrenceTitleRow({
    super.key,
    required this.occurrence,
    required this.showReschedule,
    required this.onReschedule,
    this.busy = false,
  });

  final CareOccurrence occurrence;
  final bool showReschedule;
  final VoidCallback onReschedule;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final when = [
      DateFormat.yMMMd().format(occurrence.date),
      ?occurrence.time,
    ].join(' · ');
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              when,
              key: const Key('occurrence_scheduled_when'),
              style: theme.textTheme.titleLarge,
            ),
          ),
          if (showReschedule)
            Semantics(
              identifier: 'occurrence_reschedule',
              button: true,
              label: l.occurrenceReschedule,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: TextButton(
                  key: const Key('occurrence_reschedule'),
                  onPressed: busy ? null : onReschedule,
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: ExcludeSemantics(child: Text(l.occurrenceReschedule)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

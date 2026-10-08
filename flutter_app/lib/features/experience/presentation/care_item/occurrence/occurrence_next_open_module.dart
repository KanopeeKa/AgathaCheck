import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Neutral navigation to the next open occurrence in list order.
class OccurrenceNextOpenModule extends StatelessWidget {
  const OccurrenceNextOpenModule({
    super.key,
    required this.detail,
    required this.petId,
    required this.entryId,
    required this.onOpenCareDetails,
  });

  final OccurrenceDetail detail;
  final String petId;
  final String entryId;
  final VoidCallback onOpenCareDetails;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final schedule = detail.schedule;
    if (schedule == null) return const SizedBox.shrink();

    final next = nextOpenOccurrenceAfter(
      openOccurrences: schedule.openOccurrences,
      currentId: detail.occurrence.id,
      currentDate: detail.occurrence.date,
      currentTime: detail.occurrence.time,
    );
    if (next == null) return const SizedBox.shrink();

    final openCount = schedule.openOccurrences.length;
    final locale = Localizations.localeOf(context).toString();
    final when = _formatOpenInstant(context, l, next, locale);

    return Semantics(
      identifier: 'occurrence_next_open',
      container: true,
      label: '${l.occurrenceNextOpenDate}, $when',
      child: CareItemModule(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.occurrenceNextOpenDate,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              when,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => openOccurrenceScreen(
                  context,
                  petId: petId,
                  entryId: entryId,
                  occurrenceId: next.id,
                ),
                child: Text(l.occurrenceViewNext),
              ),
            ),
            if (openCount > 1) ...[
              const SizedBox(height: 4),
              Text(
                l.occurrenceOtherOpenDatesHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: onOpenCareDetails,
                  child: Text(l.occurrenceOpenCareDetails),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatOpenInstant(
    BuildContext context,
    AppLocalizations l,
    OpenOccurrence occ,
    String locale,
  ) {
    final dateStr = DateFormat.yMMMd(locale).format(occ.date);
    final time = occ.time;
    if (time == null || time.isEmpty) return dateStr;
    final parts = time.split(':');
    if (parts.length < 2) return l.occurrenceDateAtTime(dateStr, time);
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final formattedTime = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
    return l.occurrenceDateAtTime(dateStr, formattedTime);
  }
}

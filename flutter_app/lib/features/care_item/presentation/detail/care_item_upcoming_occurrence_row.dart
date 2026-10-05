import 'package:flutter/material.dart';

import '../../../../core/router/shell_return_navigation.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/health_tracking.dart';
import '../../domain/care_item_schedule.dart';
import '../../domain/care_occurrence.dart';
import '../../domain/occurrence_display.dart';
import '../../domain/stack_rule.dart';
import 'care_item_attention_occurrence_row.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';

/// Upcoming-group row: opens occurrence screen only (FR-9).
class CareItemUpcomingOccurrenceRow extends StatelessWidget {
  const CareItemUpcomingOccurrenceRow({
    super.key,
    required this.entry,
    required this.schedule,
    required this.occurrence,
    required this.muted,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final OpenOccurrence occurrence;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final laterToday = isLaterTodayUpcoming(occurrence, schedule.asOf);
    final pill = upcomingOccurrencePillStyle(l, laterToday: laterToday);
    final when = occurrenceWhenDisplay(occurrence);
    final theme = Theme.of(context);

    return Semantics(
      identifier: 'care_item_upcoming_row_${occurrence.id}',
      label: '$when, ${pill.label}. ${l.careRowOpensDate}',
      button: true,
      child: InkWell(
        key: Key('care_item_upcoming_${occurrence.id}'),
        onTap: muted
            ? null
            : () => openOccurrenceScreen(
                context,
                petId: entry.petId,
                entryId: entry.id,
                occurrenceId: occurrence.id,
                source: 'care_item',
              ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  when,
                  style: muted
                      ? theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : theme.textTheme.bodyMedium,
                ),
              ),
              CareItemStatusPill(
                label: pill.label,
                tone: careItemStatusToneForPill(pill.tone),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/router/shell_return_navigation.dart';
import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/core/widgets/care_skip_button.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/features/pet_care/pet_care.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

CareItemStatusTone careItemStatusToneForPill(OccurrencePillTone tone) =>
    switch (tone) {
      OccurrencePillTone.overdue => CareItemStatusTone.overdue,
      OccurrencePillTone.due => CareItemStatusTone.due,
      OccurrencePillTone.notRecorded => CareItemStatusTone.notRecorded,
      OccurrencePillTone.closedNotRecorded =>
        CareItemStatusTone.notRecordedClosed,
      OccurrencePillTone.neutral => CareItemStatusTone.neutral,
    };

String occurrenceWhenDisplay(OpenOccurrence occurrence) {
  return [
    DateFormat.yMMMd().format(occurrence.date),
    ?occurrence.time,
  ].join(' · ');
}

String occurrenceWhenForSemantics(
  AppLocalizations l,
  OpenOccurrence occurrence,
) {
  final parts = <String>[DateFormat.yMMMd().format(occurrence.date)];
  if (occurrence.time != null) {
    parts.add(occurrence.time!);
  }
  return parts.join(', ');
}

/// Started occurrence row: Mark done + Skip (care-item-bulk-scope-spec FR-7).
class CareItemAttentionOccurrenceRow extends ConsumerWidget {
  const CareItemAttentionOccurrenceRow({
    super.key,
    required this.entry,
    required this.schedule,
    required this.occurrence,
    required this.muted,
    required this.onChanged,
    required this.onSkip,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final OpenOccurrence occurrence;
  final bool muted;
  final Future<void> Function() onChanged;
  final Future<void> Function() onSkip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final status = liveStatus(occurrence, schedule.asOf);
    final pill = openOccurrencePillStyle(l, status);
    final when = occurrenceWhenDisplay(occurrence);
    final whenSemantic = occurrenceWhenForSemantics(l, occurrence);

    return Semantics(
      identifier: 'care_item_occurrence_row_${occurrence.id}',
      label: '$when, ${pill.label}. ${l.careRowOpensDate}',
      button: true,
      child: InkWell(
        key: Key('care_item_occurrence_${occurrence.id}'),
        onTap: () => openOccurrenceScreen(
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
              Expanded(child: ExcludeSemantics(child: Text(when))),
              ExcludeSemantics(
                child: CareItemStatusPill(
                  label: pill.label,
                  tone: careItemStatusToneForPill(pill.tone),
                  leadingIcon: status == CareOccurrenceStatus.notRecorded
                      ? Icons.playlist_add_check_circle_outlined
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              CareMarkDoneButton(
                key: Key('care_item_occurrence_done_${occurrence.id}'),
                semanticLabel: l.careMarkDateTimeDone(whenSemantic),
                semanticsIdentifier:
                    'care_item_occurrence_done_${occurrence.id}',
                onPressed: muted
                    ? null
                    : () => ref
                          .read(careCompletionFlowProvider)
                          .done(
                            context,
                            schedule: schedule,
                            occurrence: occurrence,
                            onChanged: onChanged,
                            source: CareCommandSource.careItem,
                          ),
              ),
              CareSkipButton(
                key: Key('care_item_occurrence_skip_${occurrence.id}'),
                semanticLabel: l.careSkipDateTime(whenSemantic),
                semanticsIdentifier:
                    'care_item_occurrence_skip_${occurrence.id}',
                onPressed: muted ? null : () => onSkip(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

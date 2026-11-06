import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/core/widgets/care_skip_button.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/features/health_tracking/health_tracking.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

String _occurrenceWhenForSemantics(
  AppLocalizations l,
  OpenOccurrence occurrence,
) {
  final parts = <String>[DateFormat.yMMMd().format(occurrence.date)];
  if (occurrence.time != null) {
    parts.add(occurrence.time!);
  }
  return parts.join(', ');
}

/// Mark done + Skip (+ optional Change date) shared by Needs attention modules.
class CareItemOccurrenceTrailingControls extends ConsumerWidget {
  const CareItemOccurrenceTrailingControls({
    super.key,
    required this.entry,
    required this.schedule,
    required this.occurrence,
    required this.muted,
    required this.onChanged,
    required this.onSkip,
    this.healthOccurrence,
    this.showChangeDate = false,
  });

  final HealthEntry entry;
  final CareItemSchedule schedule;
  final OpenOccurrence occurrence;
  final bool muted;
  final Future<void> Function() onChanged;
  final Future<void> Function() onSkip;
  final HealthOccurrence? healthOccurrence;
  final bool showChangeDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final whenSemantic = _occurrenceWhenForSemantics(l, occurrence);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        CareMarkDoneButton(
          key: Key('care_item_occurrence_mark_done_${occurrence.id}'),
          semanticLabel: l.careMarkDateTimeDone(whenSemantic),
          semanticsIdentifier: 'care_item_occurrence_done_${occurrence.id}',
          onPressed: muted
              ? null
              : () => ref.read(careCompletionFlowProvider).done(
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
          semanticsIdentifier: 'care_item_occurrence_skip_${occurrence.id}',
          onPressed: muted ? null : () => onSkip(),
        ),
        if (showChangeDate && healthOccurrence != null)
          OutlinedButton(
            key: Key('care_item_occurrence_reschedule_${occurrence.id}'),
            onPressed: muted
                ? null
                : () => PetEventOccurrenceActions.changeDate(
                      context,
                      ref,
                      entry,
                      healthOccurrence!,
                    ),
            child: Text(l.rescheduleActionLabel),
          ),
      ],
    );
  }
}

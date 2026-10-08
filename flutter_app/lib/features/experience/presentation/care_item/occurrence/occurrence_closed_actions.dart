import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import 'occurrence_undo_label.dart';

/// Done, skipped, and closed-not-recorded bodies for the This date module.
class OccurrenceClosedActions extends ConsumerWidget {
  const OccurrenceClosedActions({
    super.key,
    required this.detail,
    required this.date,
    required this.busy,
    required this.seriesFinished,
    required this.onDateChange,
    required this.onUndo,
    required this.onRecord,
    required this.onConfirmSkip,
  });

  final OccurrenceDetail detail;
  final DateTime date;
  final bool busy;
  final bool seriesFinished;
  final Future<void> Function(DateTime picked) onDateChange;
  final Future<void> Function() onUndo;
  final Future<void> Function(DateTime picked) onRecord;
  final Future<void> Function() onConfirmSkip;

  CareOccurrence get _occ => detail.occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_occ.isDone) return _completed(context, ref);
    if (_occ.isClosedNotRecorded) return _closedNotRecorded(context);
    return _closedSkipped(context);
  }

  Widget _dateField(BuildContext context, {required VoidCallback onTap}) {
    final l = AppLocalizations.of(context)!;
    return ListTile(
      key: const Key('occurrence_field_completed_on'),
      contentPadding: EdgeInsets.zero,
      title: Text(l.careCompletedOnLabel),
      subtitle: Text(DateFormat.yMMMd().format(date)),
      trailing: const Icon(Icons.edit_calendar_outlined),
      onTap: busy ? null : onTap,
    );
  }

  Widget _completed(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final weight = detail.linkedWeight;
    final displayUnit = ref.watch(weightUnitPreferenceProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (weight != null) ...[
          ListTile(
            key: const Key('occurrence_linked_weight'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.weight),
            subtitle: Text(
              [
                formatWeight(weight.value, displayUnit),
                if (weight.date != null)
                  l.weightRecordedOn(DateFormat.yMMMd().format(weight.date!)),
              ].join(' · '),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: const Key('occurrence_see_all_weights'),
              onPressed: () => context.push('/pet/${detail.item.petId}/weight'),
              child: Text(l.weightSeeAll),
            ),
          ),
        ],
        _dateField(
          context,
          onTap: () async {
            final picked = await showCalendarDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: detail.item.asOf.date,
            );
            if (picked == null || picked == _occ.completedOn) return;
            await onDateChange(picked);
          },
        ),
        if (detail.canUndoHere)
          OutlinedButton(
            key: const Key('occurrence_undo'),
            onPressed: busy ? null : () => onUndo(),
            child: Text(occurrenceUndoLabel(l, detail.lastAction)),
          )
        else if (seriesFinished)
          Text(
            l.occurrenceCareFinishedNoReopen,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _closedNotRecorded(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: closedNotRecordedSemantics(l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.careClosedNotRecordedBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('occurrence_record'),
            onPressed: busy
                ? null
                : () async {
                    final picked = await showRecordAsGivenSheet(
                      context,
                      occurrence: _occ,
                      today: detail.item.asOf.date,
                    );
                    if (picked == null) return;
                    await onRecord(picked);
                  },
            child: Text(l.careRecordAsDone),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('occurrence_confirm_skip'),
            onPressed: busy ? null : () => onConfirmSkip(),
            child: Text(l.careConfirmSkipAction),
          ),
        ],
      ),
    );
  }

  Widget _closedSkipped(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final skip = detail.skipReason;
    final isWeighIn = detail.item.careFamily == kWeightMonitoringFamily;
    final reasonLabel = isWeighIn
        ? weighInSkipReasonLabel(l, skip?.code)
        : null;
    final text = reasonLabel != null
        ? l.careSkippedWithReason(reasonLabel)
        : l.careSkipped(detail.item.name);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          text,
          key: const Key('occurrence_skipped_status'),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (isWeighIn && skip?.note != null && skip!.note!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            skip.note!,
            key: const Key('occurrence_skipped_note'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (detail.canUndoHere) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('occurrence_undo'),
            onPressed: busy ? null : () => onUndo(),
            child: Text(occurrenceUndoLabel(l, detail.lastAction)),
          ),
        ] else if (seriesFinished) ...[
          const SizedBox(height: 8),
          Text(
            l.occurrenceCareFinishedNoReopen,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

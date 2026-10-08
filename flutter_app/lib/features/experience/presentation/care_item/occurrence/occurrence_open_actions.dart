import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/utils/calendar_date_picker.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Open-state fields and primary actions for one occurrence date.
class OccurrenceOpenActions extends ConsumerWidget {
  const OccurrenceOpenActions({
    super.key,
    required this.detail,
    required this.date,
    required this.weightController,
    required this.focus,
    required this.busy,
    required this.showReschedule,
    required this.onDatePicked,
    required this.onDone,
    required this.onSkip,
    required this.onReschedule,
  });

  final OccurrenceDetail detail;
  final DateTime date;
  final TextEditingController weightController;
  final String? focus;
  final bool busy;
  final bool showReschedule;
  final Future<void> Function(DateTime picked) onDatePicked;
  final VoidCallback onDone;
  final Future<void> Function() onSkip;
  final VoidCallback onReschedule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final needsWeight = completionRequirementsFor(
      detail.item.careFamily,
    ).contains(CompletionRequirement.weight);
    final inputs = CompletionInputs(
      weightValue: double.tryParse(
        weightController.text.replaceAll(',', '.'),
      ),
      weightUnit: weightUnitToWire(ref.watch(weightUnitPreferenceProvider)),
    );
    final missing = missingRequirements(detail.item.careFamily, inputs);
    final weightUnit = ref.watch(weightUnitPreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needsWeight) ...[
          TextField(
            key: const Key('occurrence_field_weight'),
            controller: weightController,
            autofocus: focus == 'weight',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: l.careWeightFieldLabelUnit(unitLabel(weightUnit)),
              helperText: missing.isEmpty ? null : l.careWeightRequiredHint,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ListTile(
          key: const Key('occurrence_field_completed_on'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.occurrenceCompletionDateLabel),
          subtitle: Text(_completionDateLabel(context, l, detail, date)),
          trailing: const Icon(Icons.edit_calendar_outlined),
          onTap: busy
              ? null
              : () async {
                  final picked = await showCalendarDatePickerForOccurrence(
                    context,
                    detail: detail,
                    initialDate: date,
                  );
                  if (picked != null) await onDatePicked(picked);
                },
        ),
        const SizedBox(height: 12),
        FilledButton(
          key: const Key('occurrence_done'),
          onPressed: busy || missing.isNotEmpty ? null : onDone,
          child: Text(l.markAsDone),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (showReschedule)
              Expanded(
                child: Semantics(
                  identifier: 'occurrence_reschedule',
                  button: true,
                  label: l.occurrenceReschedule,
                  child: OutlinedButton(
                    key: const Key('occurrence_reschedule'),
                    onPressed: busy ? null : onReschedule,
                    child: ExcludeSemantics(child: Text(l.occurrenceReschedule)),
                  ),
                ),
              ),
            if (showReschedule) const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: const Key('occurrence_skip'),
                onPressed: busy ? null : () => onSkip(),
                child: Text(l.careSkip),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _completionDateLabel(
  BuildContext context,
  AppLocalizations l,
  OccurrenceDetail detail,
  DateTime date,
) {
  final asOf = detail.item.asOf.date;
  final day = DateTime(date.year, date.month, date.day);
  final asOfDay = DateTime(asOf.year, asOf.month, asOf.day);
  final locale = Localizations.localeOf(context).toString();
  final formatted = DateFormat.yMMMd(locale).format(date);
  if (day == asOfDay) return '${l.today}, $formatted';
  final yesterday = asOfDay.subtract(const Duration(days: 1));
  if (day == yesterday) return 'Yesterday, $formatted';
  return formatted;
}

Future<DateTime?> showCalendarDatePickerForOccurrence(
  BuildContext context, {
  required OccurrenceDetail detail,
  required DateTime initialDate,
}) {
  final today = detail.item.asOf.date;
  return showCalendarDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: today,
  );
}

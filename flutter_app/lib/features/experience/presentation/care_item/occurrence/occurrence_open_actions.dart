import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:pet_profile_app/core/widgets/care_mark_done_button.dart';
import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Open-state completion fields for one occurrence date (Block 3).
class OccurrenceOpenActions extends ConsumerWidget {
  const OccurrenceOpenActions({
    super.key,
    required this.detail,
    required this.weightController,
    required this.focus,
    required this.busy,
    required this.completionDate,
    required this.onPickCompletionDate,
    required this.onDone,
  });

  final OccurrenceDetail detail;
  final TextEditingController weightController;
  final String? focus;
  final bool busy;
  final DateTime completionDate;
  final VoidCallback onPickCompletionDate;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final occ = detail.occurrence;
    final needsWeight = completionRequirementsFor(
      detail.item.careFamily,
    ).contains(CompletionRequirement.weight);
    final inputs = CompletionInputs(
      weightValue: double.tryParse(weightController.text.replaceAll(',', '.')),
      weightUnit: weightUnitToWire(ref.watch(weightUnitPreferenceProvider)),
    );
    final missing = missingRequirements(detail.item.careFamily, inputs);
    final weightUnit = ref.watch(weightUnitPreferenceProvider);
    final locale = Localizations.localeOf(context).toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (occ.time != null && occ.time!.isNotEmpty) ...[
          ListTile(
            key: const Key('occurrence_scheduled_time_read_only'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.occurrenceScheduledTimeLabel),
            subtitle: Text(_formatScheduledTime(context, occ.time!)),
            enabled: false,
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          identifier: 'occurrence_field_completion_date',
          button: true,
          label: l.occurrenceCompletionDateLabel,
          child: ListTile(
            key: const Key('occurrence_field_completion_date'),
            contentPadding: EdgeInsets.zero,
            title: Text(l.occurrenceCompletionDateLabel),
            subtitle: Text(DateFormat.yMMMd(locale).format(completionDate)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: busy ? null : onPickCompletionDate,
          ),
        ),
        const SizedBox(height: 12),
        if (needsWeight) ...[
          Semantics(
            identifier: 'occurrence_field_weight',
            textField: true,
            label: l.careWeightFieldLabelUnit(unitLabel(weightUnit)),
            child: TextField(
              key: const Key('occurrence_field_weight'),
              controller: weightController,
              autofocus: focus == 'weight',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: l.careWeightFieldLabelUnit(unitLabel(weightUnit)),
                helperText: missing.isEmpty ? null : l.careWeightRequiredHint,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerRight,
          child: CareMarkDoneButton(
            key: const Key('occurrence_done'),
            semanticsIdentifier: 'occurrence_done',
            onPressed: busy || missing.isNotEmpty ? null : onDone,
          ),
        ),
      ],
    );
  }

  String _formatScheduledTime(BuildContext context, String time) {
    final parts = time.split(':');
    if (parts.length < 2) return time;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay(hour: hour, minute: minute));
  }
}

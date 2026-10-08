import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pet_profile_app/core/weight/weight_unit.dart';
import 'package:pet_profile_app/core/weight/weight_unit_preference.dart';
import 'package:pet_profile_app/features/care_item/care_item.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

/// Open-state completion fields for one occurrence date (weight + Mark as done).
class OccurrenceOpenActions extends ConsumerWidget {
  const OccurrenceOpenActions({
    super.key,
    required this.detail,
    required this.weightController,
    required this.focus,
    required this.busy,
    required this.onDone,
  });

  final OccurrenceDetail detail;
  final TextEditingController weightController;
  final String? focus;
  final bool busy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final needsWeight = completionRequirementsFor(
      detail.item.careFamily,
    ).contains(CompletionRequirement.weight);
    final inputs = CompletionInputs(
      weightValue: double.tryParse(weightController.text.replaceAll(',', '.')),
      weightUnit: weightUnitToWire(ref.watch(weightUnitPreferenceProvider)),
    );
    final missing = missingRequirements(detail.item.careFamily, inputs);
    final weightUnit = ref.watch(weightUnitPreferenceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        FilledButton(
          key: const Key('occurrence_done'),
          onPressed: busy || missing.isNotEmpty ? null : onDone,
          child: Text(l.markAsDone),
        ),
      ],
    );
  }
}

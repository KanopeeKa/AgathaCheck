import 'package:flutter/material.dart';

import '../../../../care_taxonomy/care_taxonomy.dart';
import 'health_entry_care_classification_labels.dart';
import '../../../../../l10n/app_localizations.dart';

/// Where and priority fields (Advanced settings, D-CIE-027).
class CareSettingImportanceFields extends StatelessWidget {
  const CareSettingImportanceFields({
    super.key,
    required this.careSetting,
    required this.careImportance,
    required this.onCareSettingChanged,
    required this.onCareImportanceChanged,
  });

  final CareSetting careSetting;
  final CareImportance careImportance;
  final ValueChanged<CareSetting> onCareSettingChanged;
  final ValueChanged<CareImportance> onCareImportanceChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: l10n.careSettingFieldLabel,
          child: DropdownButtonFormField<CareSetting>(
            key: const Key('care_setting_picker'),
            initialValue: careSetting,
            decoration: InputDecoration(
              labelText: l10n.careSettingFieldLabel,
              helperText: l10n.careSettingFieldHelper,
              border: const OutlineInputBorder(),
            ),
            items: CareSetting.values
                .map(
                  (setting) => DropdownMenuItem(
                    value: setting,
                    child: Text(healthEntryCareSettingLabel(l10n, setting)),
                  ),
                )
                .toList(),
            onChanged: (next) {
              if (next != null) onCareSettingChanged(next);
            },
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          label: l10n.careImportanceFieldLabel,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.careImportanceFieldLabel,
              helperText: l10n.careImportanceFieldHelper,
              border: const OutlineInputBorder(),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CareImportance.values.map((importance) {
                return ChoiceChip(
                  key: Key('care_importance_${importance.wireValue}'),
                  label: Text(healthEntryCareImportanceLabel(l10n, importance)),
                  selected: careImportance == importance,
                  onSelected: (_) => onCareImportanceChanged(importance),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

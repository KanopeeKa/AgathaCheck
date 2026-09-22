import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../health_tracking/presentation/widgets/care_family_picker_field.dart';
import '../../../health_tracking/presentation/widgets/care_family_suggestion_banner.dart';
import '../../../pet_profile/domain/entities/care_family.dart';
import '../../domain/care_importance.dart';
import '../../domain/care_setting.dart';
import 'care_classification_labels.dart';

/// Unified care classification controls: family, setting, and priority.
class CareClassificationSection extends StatelessWidget {
  const CareClassificationSection({
    super.key,
    required this.isEdit,
    required this.careFamily,
    required this.careSetting,
    required this.careImportance,
    required this.careFamilyRequiredError,
    required this.showCareFamilySuggestion,
    required this.showCareFamilyPicker,
    required this.suggestedCareFamily,
    required this.onCareFamilyChanged,
    required this.onCareSettingChanged,
    required this.onCareImportanceChanged,
    required this.onAcceptSuggestion,
    required this.onChooseDifferentSuggestion,
    required this.onDismissSuggestion,
  });

  final bool isEdit;
  final CareFamily? careFamily;
  final CareSetting careSetting;
  final CareImportance careImportance;
  final String? careFamilyRequiredError;
  final bool showCareFamilySuggestion;
  final bool showCareFamilyPicker;
  final CareFamily suggestedCareFamily;
  final ValueChanged<CareFamily> onCareFamilyChanged;
  final ValueChanged<CareSetting> onCareSettingChanged;
  final ValueChanged<CareImportance> onCareImportanceChanged;
  final VoidCallback onAcceptSuggestion;
  final VoidCallback onChooseDifferentSuggestion;
  final VoidCallback onDismissSuggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!isEdit && !showCareFamilyPicker) {
      return const SizedBox.shrink();
    }
    if (isEdit && !showCareFamilySuggestion && !showCareFamilyPicker) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showCareFamilySuggestion)
          CareFamilySuggestionBanner(
            suggestedFamily: suggestedCareFamily,
            onAccept: onAcceptSuggestion,
            onChooseDifferent: onChooseDifferentSuggestion,
            onDismiss: onDismissSuggestion,
          ),
        if (showCareFamilySuggestion && showCareFamilyPicker)
          const SizedBox(height: 16),
        if (showCareFamilyPicker) ...[
          CareFamilyPickerField(
            value: careFamily,
            required: !isEdit,
            errorText: careFamilyRequiredError,
            onChanged: onCareFamilyChanged,
          ),
          const SizedBox(height: 16),
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
                      child: Text(careSettingLabel(l10n, setting)),
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
                    label: Text(careImportanceLabel(l10n, importance)),
                    selected: careImportance == importance,
                    onSelected: (_) => onCareImportanceChanged(importance),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

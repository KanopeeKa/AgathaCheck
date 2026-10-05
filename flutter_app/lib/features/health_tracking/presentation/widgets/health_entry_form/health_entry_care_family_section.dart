import 'package:flutter/material.dart';

import '../../../../pet_profile/pet_profile.dart';
import '../care_family_picker_field.dart';
import '../care_family_suggestion_banner.dart';

/// Category / care family controls for the health entry form (main section).
class HealthEntryCareFamilySection extends StatelessWidget {
  const HealthEntryCareFamilySection({
    super.key,
    required this.isEdit,
    required this.careFamily,
    required this.careFamilyRequiredError,
    required this.showCareFamilySuggestion,
    required this.showCareFamilyPicker,
    required this.suggestedCareFamily,
    required this.onCareFamilyChanged,
    required this.onAcceptSuggestion,
    required this.onChooseDifferentSuggestion,
    required this.onDismissSuggestion,
  });

  final bool isEdit;
  final CareFamily? careFamily;
  final String? careFamilyRequiredError;
  final bool showCareFamilySuggestion;
  final bool showCareFamilyPicker;
  final CareFamily suggestedCareFamily;
  final ValueChanged<CareFamily> onCareFamilyChanged;
  final VoidCallback onAcceptSuggestion;
  final VoidCallback onChooseDifferentSuggestion;
  final VoidCallback onDismissSuggestion;

  @override
  Widget build(BuildContext context) {
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
        if (showCareFamilyPicker)
          CareFamilyPickerField(
            value: careFamily,
            required: !isEdit,
            errorText: careFamilyRequiredError,
            onChanged: onCareFamilyChanged,
          ),
      ],
    );
  }
}

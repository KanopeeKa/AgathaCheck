import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../controllers/health_entry_form_controller.dart';
import '../care_family_picker_field.dart';
import '../care_family_suggestion_banner.dart';

/// Care family picker and uncategorised-edit suggestion for the health entry form.
class HealthEntryFormCareFamilySection extends StatelessWidget {
  const HealthEntryFormCareFamilySection({
    super.key,
    required this.form,
    required this.controller,
  });

  final HealthEntryFormState form;
  final HealthEntryFormController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (!form.isEdit && !form.showCareFamilyPicker) {
      return const SizedBox.shrink();
    }
    if (form.isEdit &&
        !form.showCareFamilySuggestion &&
        !form.showCareFamilyPicker) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (form.showCareFamilySuggestion)
          CareFamilySuggestionBanner(
            suggestedFamily: form.suggestedCareFamilyForType(),
            onAccept: controller.acceptCareFamilySuggestion,
            onChooseDifferent: controller.revealCareFamilyPicker,
            onDismiss: controller.dismissCareFamilySuggestion,
          ),
        if (form.showCareFamilySuggestion && form.showCareFamilyPicker)
          const SizedBox(height: 16),
        if (form.showCareFamilyPicker)
          CareFamilyPickerField(
            value: form.careFamily,
            required: !form.isEdit,
            errorText: form.careFamilyRequiredError(l10n),
            onChanged: controller.setCareFamily,
          ),
      ],
    );
  }
}

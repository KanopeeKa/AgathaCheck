import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../l10n/app_localizations.dart';

/// Name and dosage fields bound to controller state via callbacks.
class HealthEntryNameDosageFields extends StatelessWidget {
  const HealthEntryNameDosageFields({
    super.key,
    required this.name,
    required this.dosage,
    required this.onNameChanged,
    required this.onDosageChanged,
  });

  final String name;
  final String dosage;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDosageChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormLabeledField(
          label: l.entryName,
          child: TextFormField(
            key: const Key('health_name_field'),
            initialValue: name,
            decoration: InputDecoration(hintText: l.entryNameHint),
            validator: (val) =>
                val == null || val.trim().isEmpty ? l.entryNameRequired : null,
            onChanged: onNameChanged,
          ),
        ),
        const SizedBox(height: 16),
        AppFormLabeledField(
          label: l.dosage,
          child: TextFormField(
            key: const Key('health_dosage_field'),
            initialValue: dosage,
            decoration: InputDecoration(hintText: l.dosageHint),
            onChanged: onDosageChanged,
          ),
        ),
      ],
    );
  }
}

/// Notes field bound to controller state.
class HealthEntryNotesField extends StatelessWidget {
  const HealthEntryNotesField({
    super.key,
    required this.notes,
    required this.onChanged,
  });

  final String notes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppFormLabeledField(
      label: l.notes,
      child: TextFormField(
        key: const Key('health_notes_field'),
        initialValue: notes,
        decoration: InputDecoration(hintText: l.notesHint),
        maxLines: 3,
        onChanged: onChanged,
      ),
    );
  }
}

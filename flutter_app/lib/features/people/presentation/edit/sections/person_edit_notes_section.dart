import 'package:flutter/material.dart';

import '../../../../../core/widgets/form/app_form_labeled_field.dart';
import '../../../../../core/widgets/form/app_form_section.dart';
import '../../../../../l10n/app_localizations.dart';
import '../person_form_controller.dart';

class PersonEditNotesSection extends StatelessWidget {
  const PersonEditNotesSection({super.key, required this.controller});

  final PersonFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AppFormSection(
      title: l.peopleEditSectionNotes,
      children: [
        AppFormLabeledField(
          label: l.peoplePrivateNoteLabel,
          subtitle: l.peoplePrivateNoteHelper,
          child: TextFormField(
            initialValue: controller.privateNote,
            minLines: 2,
            maxLines: 5,
            onChanged: controller.setPrivateNote,
          ),
        ),
        if (controller.showHouseholdNote) ...[
          const SizedBox(height: 16),
          AppFormLabeledField(
            label: l.peopleDetailHouseholdNoteLabel,
            subtitle: l.peopleDetailHouseholdNoteHelper,
            child: TextFormField(
              initialValue: controller.householdNote,
              minLines: 2,
              maxLines: 5,
              onChanged: controller.setHouseholdNote,
            ),
          ),
        ],
      ],
    );
  }
}

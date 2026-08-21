import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import '../controllers/foster_questionnaire_form_controller.dart';
import '../controllers/form_state.dart';

class FosterQuestionnaireAcknowledgementSection extends StatelessWidget {
  const FosterQuestionnaireAcknowledgementSection({
    super.key,
    required this.template,
    required this.state,
    required this.controller,
  });

  final FosterQuestionnaireTemplate template;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterQuestionnaireAcknowledgementIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              template.definition.candidateAcknowledgement,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Semantics(
          identifier: 'foster_questionnaire_ack_checkbox',
          checked: state.candidateAcknowledged,
          label: l.fosterQuestionnaireAcknowledgementCheckbox,
          child: CheckboxListTile(
            value: state.candidateAcknowledged,
            onChanged: (value) =>
                controller.setCandidateAcknowledged(value ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l.fosterQuestionnaireAcknowledgementCheckbox),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: l.fosterQuestionnaireOptionalNoteLabel,
          ),
          maxLines: 3,
          onChanged: controller.setGeneralNote,
        ),
      ],
    );
  }
}

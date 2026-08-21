import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import '../controllers/foster_questionnaire_form_controller.dart';
import '../controllers/form_state.dart';
import '../utils/foster_questionnaire_labels.dart';

class FosterQuestionnaireScreeningSection extends StatelessWidget {
  const FosterQuestionnaireScreeningSection({
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
          l.fosterQuestionnaireScreeningIntro,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        for (final question in template.definition.screeningQuestions) ...[
          _ScreeningQuestion(
            question: question,
            state: state,
            controller: controller,
          ),
          const SizedBox(height: 24),
        ],
      ],
    );
  }
}

class _ScreeningQuestion extends StatelessWidget {
  const _ScreeningQuestion({
    required this.question,
    required this.state,
    required this.controller,
  });

  final FosterScreeningQuestion question;
  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final help = fosterQuestionnaireScreeningHelp(l, question.id);
    final selected = state.answerFor(question.id).singleOptionId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fosterQuestionnaireScreeningPrompt(l, question.id),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (help.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(help, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 8),
        for (final option in question.options)
          Semantics(
            identifier: fosterQuestionnaireScreeningSemanticsId(option.id),
            label: fosterQuestionnaireScreeningOptionLabel(l, option.id),
            child: RadioListTile<String>(
              value: option.id,
              groupValue: selected,
              onChanged: (value) {
                if (value != null) {
                  controller.selectScreeningOption(question.id, value);
                }
              },
              title: Text(
                fosterQuestionnaireScreeningOptionLabel(l, option.id),
              ),
            ),
          ),
        if (selected != null &&
            selected.endsWith('_B') &&
            question.adminNoteRequiredIf == selected) ...[
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              labelText: l.fosterQuestionnaireOptionalNoteLabel,
            ),
            onChanged: (value) =>
                controller.setScreeningNote(question.id, value),
          ),
        ],
      ],
    );
  }
}

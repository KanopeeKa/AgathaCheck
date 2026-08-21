import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/foster_questionnaire_review.dart';
import '../providers/foster_questionnaire_review_providers.dart';

class FosterQuestionnaireTriggeringAnswers extends StatelessWidget {
  const FosterQuestionnaireTriggeringAnswers({
    super.key,
    required this.answers,
    required this.q02BMandatoryFollowup,
    this.generalNote = '',
  });

  final List<FosterQuestionnaireAnswer> answers;
  final bool q02BMandatoryFollowup;
  final String generalNote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterQuestionnaireTriggeringAnswersTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (q02BMandatoryFollowup) ...[
          const SizedBox(height: 8),
          _FlagChip(
            label: l.fosterQuestionnaireQ02BMandatoryFollowup,
            color: colorScheme.errorContainer,
            textColor: colorScheme.onErrorContainer,
          ),
        ],
        if (generalNote.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l.fosterQuestionnaireGeneralNoteLabel,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(generalNote),
        ],
        const SizedBox(height: 12),
        if (answers.isEmpty)
          Text(
            l.fosterQuestionnaireNoTriggeringAnswers,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...answers.map(
            (answer) => _TriggeringAnswerCard(
              key: Key('foster_questionnaire_trigger_${answer.questionId}'),
              answer: answer,
            ),
          ),
      ],
    );
  }
}

class _TriggeringAnswerCard extends StatelessWidget {
  const _TriggeringAnswerCard({super.key, required this.answer});

  final FosterQuestionnaireAnswer answer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final outcome = answer.screeningOutcome ?? '';
    final outcomeColor = switch (outcome) {
      'NO_GO' => colorScheme.error,
      'GO_WITH_RESERVATION' => colorScheme.tertiary,
      _ => colorScheme.onSurfaceVariant,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizedFosterQuestionnaireQuestionLabel(l, answer.questionId),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            if (answer.optionId != null && answer.optionId!.isNotEmpty)
              Text('${l.fosterQuestionnaireAnswerOption}: ${answer.optionId}'),
            if (answer.answerValue != null)
              Text('${l.fosterQuestionnaireAnswerValue}: ${answer.answerValue}'),
            if (outcome.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                localizedFosterQuestionnaireOutcomeLabel(l, outcome),
                style: theme.textTheme.labelLarge?.copyWith(color: outcomeColor),
              ),
            ],
            if (answer.candidateNote.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                l.fosterQuestionnaireCandidateNoteLabel,
                style: theme.textTheme.titleSmall,
              ),
              Text(answer.candidateNote),
            ],
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: textColor),
      ),
    );
  }
}

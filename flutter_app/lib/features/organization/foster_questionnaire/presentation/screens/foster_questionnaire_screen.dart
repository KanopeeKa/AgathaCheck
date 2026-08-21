import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/org_shell_scaffold.dart';
import '../controllers/foster_questionnaire_form_controller.dart';
import '../controllers/form_state.dart';
import '../providers/foster_questionnaire_providers.dart';
import '../widgets/acknowledgement_section.dart';
import '../widgets/profile_section.dart';
import '../widgets/screening_section.dart';
import '../widgets/section_tabs.dart';

class FosterQuestionnaireScreen extends ConsumerWidget {
  const FosterQuestionnaireScreen({super.key, required this.orgId});

  final String orgId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final formKey = (orgId: orgId);
    final state = ref.watch(fosterQuestionnaireFormProvider(formKey));
    final notifier = ref.read(fosterQuestionnaireFormProvider(formKey).notifier);
    final controller = notifier.controller;

    return Semantics(
      identifier: 'foster_questionnaire_screen',
      container: true,
      child: OrgShellScaffold(
        title: l.fosterQuestionnaireTitle,
        orgId: orgId,
        child: state.template == null && !state.submitted
            ? _LoadingOrError(state: state)
            : state.submitted
            ? _SuccessPanel(state: state)
            : _QuestionnaireBody(
                state: state,
                controller: controller,
                onSectionSelected: controller.goToSection,
                onBack: () {
                  final previous = switch (state.section) {
                    FosterQuestionnaireSection.screening =>
                      FosterQuestionnaireSection.profile,
                    FosterQuestionnaireSection.acknowledgement =>
                      FosterQuestionnaireSection.screening,
                    FosterQuestionnaireSection.profile => null,
                  };
                  if (previous != null) controller.goToSection(previous);
                },
                onContinue: () {
                  controller.advanceSection(l);
                },
                onSubmit: () => controller.submit(l),
              ),
      ),
    );
  }
}

class _LoadingOrError extends StatelessWidget {
  const _LoadingOrError({required this.state});

  final FosterQuestionnaireFormState state;

  @override
  Widget build(BuildContext context) {
    if (state.validationMessage.isNotEmpty) {
      return Center(child: Text(state.validationMessage));
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class _QuestionnaireBody extends StatelessWidget {
  const _QuestionnaireBody({
    required this.state,
    required this.controller,
    required this.onSectionSelected,
    required this.onBack,
    required this.onContinue,
    required this.onSubmit,
  });

  final FosterQuestionnaireFormState state;
  final FosterQuestionnaireFormController controller;
  final ValueChanged<FosterQuestionnaireSection> onSectionSelected;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final template = state.template!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.fosterQuestionnaireCandidateMessage),
        const SizedBox(height: 8),
        Text(
          l.fosterQuestionnaireDisclaimer,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        FosterQuestionnaireSectionTabs(
          section: state.section,
          onSectionSelected: onSectionSelected,
        ),
        if (state.validationMessage.isNotEmpty) ...[
          Text(
            state.validationMessage,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        switch (state.section) {
          FosterQuestionnaireSection.profile => FosterQuestionnaireProfileSection(
            template: template,
            state: state,
            controller: controller,
          ),
          FosterQuestionnaireSection.screening =>
            FosterQuestionnaireScreeningSection(
              template: template,
              state: state,
              controller: controller,
            ),
          FosterQuestionnaireSection.acknowledgement =>
            FosterQuestionnaireAcknowledgementSection(
              template: template,
              state: state,
              controller: controller,
            ),
        },
        const SizedBox(height: 24),
        _NavigationButtons(
          section: state.section,
          submitting: state.submitting,
          onBack: onBack,
          onContinue: onContinue,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _NavigationButtons extends StatelessWidget {
  const _NavigationButtons({
    required this.section,
    required this.submitting,
    required this.onBack,
    required this.onContinue,
    required this.onSubmit,
  });

  final FosterQuestionnaireSection section;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Row(
      children: [
        if (section != FosterQuestionnaireSection.profile)
          OutlinedButton(
            onPressed: submitting ? null : onBack,
            child: Text(l.fosterQuestionnaireBack),
          ),
        const Spacer(),
        if (section == FosterQuestionnaireSection.acknowledgement)
          Semantics(
            identifier: 'foster_questionnaire_submit',
            button: true,
            label: l.fosterQuestionnaireSubmit,
            child: FilledButton(
              key: const Key('foster_questionnaire_submit'),
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.fosterQuestionnaireSubmit),
            ),
          )
        else
          Semantics(
            identifier: 'foster_questionnaire_next',
            button: true,
            label: l.fosterQuestionnaireNext,
            child: FilledButton(
              key: const Key('foster_questionnaire_next'),
              onPressed: submitting ? null : onContinue,
              child: Text(l.fosterQuestionnaireNext),
            ),
          ),
      ],
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({required this.state});

  final FosterQuestionnaireFormState state;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final result = state.submissionResult?.result ?? '';
    final message = result == 'AUTO_GO'
        ? l.fosterQuestionnaireSubmitAutoGoMessage
        : l.fosterQuestionnaireSubmitReviewMessage;

    return Semantics(
      identifier: 'foster_questionnaire_success_panel',
      container: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.fosterQuestionnaireSubmitSuccessTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../presentation/widgets/org_shell_app_bar_title.dart';
import '../../../presentation/widgets/org_shell_scaffold.dart';
import '../providers/foster_questionnaire_review_providers.dart';
import '../widgets/foster_questionnaire_decision_form.dart';
import '../widgets/foster_questionnaire_triggering_answers.dart';
import '../../domain/entities/foster_questionnaire_review.dart';

class FosterQuestionnaireReviewScreen extends ConsumerStatefulWidget {
  const FosterQuestionnaireReviewScreen({
    super.key,
    required this.orgId,
    required this.fosterParentId,
  });

  final String orgId;
  final String fosterParentId;

  @override
  ConsumerState<FosterQuestionnaireReviewScreen> createState() =>
      _FosterQuestionnaireReviewScreenState();
}

class _FosterQuestionnaireReviewScreenState
    extends ConsumerState<FosterQuestionnaireReviewScreen> {
  var _submitting = false;

  FosterQuestionnaireReviewKey get _key => (
    orgId: widget.orgId,
    fosterParentId: widget.fosterParentId,
  );

  Future<void> _submitDecision({
    required String decision,
    required String structuredReason,
    String staffNotes = '',
  }) async {
    final l = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    try {
      await ref
          .read(fosterQuestionnaireReviewProvider(_key).notifier)
          .recordDecision(
            decision: decision,
            structuredReason: structuredReason,
            staffNotes: staffNotes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.fosterQuestionnaireDecisionSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final reviewAsync = ref.watch(fosterQuestionnaireReviewProvider(_key));

    return OrgShellScaffold(
      title: l.fosterQuestionnaireReviewTitle,
      orgId: widget.orgId,
      navVariant: OrgNavTitleVariant.withOrgLogo,
      leadingKey: const Key('foster_questionnaire_review_back'),
      child: reviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (review) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SubmissionSummary(review: review),
            const SizedBox(height: 24),
            FosterQuestionnaireTriggeringAnswers(
              answers: review.triggeringAnswers,
              q02BMandatoryFollowup: review.submission.q02BMandatoryFollowup,
              generalNote: review.submission.generalNote,
            ),
            const SizedBox(height: 24),
            FosterQuestionnaireDecisionForm(
              busy: _submitting,
              previousDecisions: review.decisions,
              onSubmit: _submitDecision,
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmissionSummary extends StatelessWidget {
  const _SubmissionSummary({required this.review});

  final FosterQuestionnaireReview review;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final submission = review.submission;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.fosterQuestionnaireSubmissionSummaryTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('${l.fosterQuestionnaireResultLabel}: ${submission.result}'),
            if (submission.submittedAt != null)
              Text(
                '${l.fosterQuestionnaireSubmittedAtLabel}: ${submission.submittedAt}',
              ),
            Text(
              '${l.fosterQuestionnaireTemplateVersionLabel}: ${submission.templateVersion}',
            ),
          ],
        ),
      ),
    );
  }
}

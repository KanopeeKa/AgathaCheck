import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/entities/foster_questionnaire_review.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/entities/foster_questionnaire_template.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/repositories/foster_questionnaire_repository.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/providers/foster_questionnaire_review_providers.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/screens/foster_questionnaire_review_screen.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/widgets/foster_questionnaire_decision_form.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../../helpers/fakes.dart';

void main() {
  testWidgets('review screen shows triggering answers and decision form', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => FakeAuthNotifier()),
          fosterQuestionnaireRepositoryProvider.overrideWithValue(
            _FakeFosterQuestionnaireRepository(),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: FosterQuestionnaireReviewScreen(
              orgId: 'org-1',
              fosterParentId: 'fp-1',
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Answers requiring review'), findsOneWidget);
    expect(find.text('Minimum age'), findsOneWidget);
    expect(find.text('Review recommended'), findsOneWidget);
    expect(find.text('Record decision'), findsOneWidget);
    expect(
      find.byKey(const Key('foster_questionnaire_decision_dropdown')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('foster_questionnaire_structured_reason')),
      findsOneWidget,
    );
  });

  testWidgets('decision form requires structured reason before submit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: FosterQuestionnaireDecisionForm(
            onSubmit: ({required decision, required structuredReason, staffNotes = ''}) async {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('foster_questionnaire_submit_decision')));
    await tester.pumpAndSettle();

    expect(find.text('Select a decision'), findsOneWidget);
    expect(find.text('Structured reason is required'), findsOneWidget);
  });
}

class _FakeFosterQuestionnaireRepository
    implements FosterQuestionnaireRepository {
  @override
  Future<FosterQuestionnaireTemplate> loadTemplate(
    String orgId,
    String token,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<FosterQuestionnaireSubmissionResult> submitQuestionnaire(
    String orgId, {
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
    required String token,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<FosterQuestionnaireReview> getSubmissionReview(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    return FosterQuestionnaireReview(
      submission: FosterQuestionnaireSubmission(
        id: 'sub-1',
        organizationId: orgId,
        orgFosterParentId: fosterParentId,
        templateVersion: '1.3',
        result: 'ADMIN_REVIEW',
        q02BMandatoryFollowup: true,
        generalNote: 'Needs follow-up on household agreement.',
        candidateAcknowledged: true,
        submittedAt: '2026-08-21T12:00:00.000Z',
        reviewRequiredAnswers: const ['Q01'],
      ),
      answers: const [
        FosterQuestionnaireAnswer(
          id: 'ans-1',
          questionId: 'Q01',
          optionId: 'Q01_B',
          candidateNote: 'Turning 21 next month.',
          screeningOutcome: 'GO_WITH_RESERVATION',
        ),
      ],
      decisions: const [],
    );
  }

  @override
  Future<FosterQuestionnaireDecision> recordDecision(
    String orgId,
    String submissionId, {
    required String decision,
    required String structuredReason,
    String staffNotes = '',
    required String token,
  }) async {
    return FosterQuestionnaireDecision(
      id: 'dec-1',
      submissionId: submissionId,
      decision: decision,
      structuredReason: structuredReason,
      staffNotes: staffNotes,
      decidedAt: '2026-08-21T13:00:00.000Z',
    );
  }
}

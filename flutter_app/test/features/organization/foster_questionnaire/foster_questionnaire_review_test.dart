import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/entities/foster_questionnaire_review.dart';

void main() {
  group('FosterQuestionnaireReview', () {
    test('triggeringAnswers includes non-GO outcomes and review flags', () {
      const review = FosterQuestionnaireReview(
        submission: FosterQuestionnaireSubmission(
          id: 'sub-1',
          organizationId: 'org-1',
          orgFosterParentId: 'fp-1',
          templateVersion: '1.3',
          result: 'ADMIN_REVIEW',
          q02BMandatoryFollowup: false,
          generalNote: '',
          candidateAcknowledged: true,
          reviewRequiredAnswers: ['Q03'],
        ),
        answers: [
          FosterQuestionnaireAnswer(
            id: 'a1',
            questionId: 'Q01',
            optionId: 'Q01_A',
            candidateNote: '',
            screeningOutcome: 'GO',
          ),
          FosterQuestionnaireAnswer(
            id: 'a2',
            questionId: 'Q02',
            optionId: 'Q02_B',
            candidateNote: '',
            screeningOutcome: 'GO_WITH_RESERVATION',
          ),
          FosterQuestionnaireAnswer(
            id: 'a3',
            questionId: 'Q03',
            optionId: 'Q03_A',
            candidateNote: '',
            screeningOutcome: 'GO',
          ),
        ],
        decisions: const [],
      );

      final triggering = review.triggeringAnswers.map((a) => a.questionId).toList();
      expect(triggering, containsAll(['Q02', 'Q03']));
      expect(triggering, isNot(contains('Q01')));
    });

    test('fromJson parses submission review payload', () {
      final review = FosterQuestionnaireReview.fromJson({
        'submission': {
          'id': 'sub-1',
          'organization_id': 'org-1',
          'org_foster_parent_id': 'fp-1',
          'template_version': '1.3',
          'result': 'ADMIN_REVIEW',
          'q02_b_mandatory_followup': true,
          'general_note': 'Note',
          'candidate_acknowledged': true,
          'review_required_answers': ['Q02'],
        },
        'answers': [
          {
            'id': 'ans-1',
            'question_id': 'Q02',
            'option_id': 'Q02_B',
            'candidate_note': 'Partner unsure',
            'screening_outcome': 'GO_WITH_RESERVATION',
          },
        ],
        'decisions': [
          {
            'id': 'dec-1',
            'submission_id': 'sub-1',
            'decision': 'Clarification requested',
            'structured_reason': 'Need household agreement details',
            'staff_notes': '',
            'decided_at': '2026-08-21T12:00:00.000Z',
          },
        ],
      });

      expect(review.submission.q02BMandatoryFollowup, isTrue);
      expect(review.triggeringAnswers, hasLength(1));
      expect(review.decisions.first.decision, 'Clarification requested');
    });
  });
}

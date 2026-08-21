class FosterQuestionnaireSubmission {
  const FosterQuestionnaireSubmission({
    required this.id,
    required this.organizationId,
    required this.orgFosterParentId,
    required this.templateVersion,
    required this.result,
    required this.q02BMandatoryFollowup,
    required this.generalNote,
    required this.candidateAcknowledged,
    this.submittedAt,
    this.submittedByUserId,
    this.reviewRequiredAnswers = const [],
  });

  final String id;
  final String organizationId;
  final String orgFosterParentId;
  final String templateVersion;
  final String result;
  final bool q02BMandatoryFollowup;
  final String generalNote;
  final bool candidateAcknowledged;
  final String? submittedAt;
  final String? submittedByUserId;
  final List<String> reviewRequiredAnswers;

  bool get needsAdminReview => result == 'ADMIN_REVIEW';

  factory FosterQuestionnaireSubmission.fromJson(Map<String, dynamic> json) {
    final reviewRequired = json['review_required_answers'];
    return FosterQuestionnaireSubmission(
      id: json['id']?.toString() ?? '',
      organizationId: json['organization_id']?.toString() ?? '',
      orgFosterParentId: json['org_foster_parent_id']?.toString() ?? '',
      templateVersion: json['template_version']?.toString() ?? '',
      result: json['result']?.toString() ?? '',
      q02BMandatoryFollowup: json['q02_b_mandatory_followup'] == true,
      generalNote: json['general_note']?.toString() ?? '',
      candidateAcknowledged: json['candidate_acknowledged'] == true,
      submittedAt: json['submitted_at']?.toString(),
      submittedByUserId: json['submitted_by_user_id']?.toString(),
      reviewRequiredAnswers: reviewRequired is List
          ? reviewRequired.map((item) => item.toString()).toList()
          : const [],
    );
  }
}

class FosterQuestionnaireAnswer {
  const FosterQuestionnaireAnswer({
    required this.id,
    required this.questionId,
    this.optionId,
    this.answerValue,
    required this.candidateNote,
    this.screeningOutcome,
  });

  final String id;
  final String questionId;
  final String? optionId;
  final Object? answerValue;
  final String candidateNote;
  final String? screeningOutcome;

  bool get isTriggering =>
      screeningOutcome != null &&
      screeningOutcome!.isNotEmpty &&
      screeningOutcome != 'GO';

  factory FosterQuestionnaireAnswer.fromJson(Map<String, dynamic> json) {
    return FosterQuestionnaireAnswer(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      optionId: json['option_id']?.toString(),
      answerValue: json['answer_value'],
      candidateNote: json['candidate_note']?.toString() ?? '',
      screeningOutcome: json['screening_outcome']?.toString(),
    );
  }
}

class FosterQuestionnaireDecision {
  const FosterQuestionnaireDecision({
    required this.id,
    required this.submissionId,
    required this.decision,
    required this.structuredReason,
    required this.staffNotes,
    this.decidedBy,
    this.decidedAt,
  });

  final String id;
  final String submissionId;
  final String decision;
  final String structuredReason;
  final String staffNotes;
  final String? decidedBy;
  final String? decidedAt;

  factory FosterQuestionnaireDecision.fromJson(Map<String, dynamic> json) {
    return FosterQuestionnaireDecision(
      id: json['id']?.toString() ?? '',
      submissionId: json['submission_id']?.toString() ?? '',
      decision: json['decision']?.toString() ?? '',
      structuredReason: json['structured_reason']?.toString() ?? '',
      staffNotes: json['staff_notes']?.toString() ?? '',
      decidedBy: json['decided_by']?.toString(),
      decidedAt: json['decided_at']?.toString(),
    );
  }
}

class FosterQuestionnaireReview {
  const FosterQuestionnaireReview({
    required this.submission,
    required this.answers,
    required this.decisions,
  });

  final FosterQuestionnaireSubmission submission;
  final List<FosterQuestionnaireAnswer> answers;
  final List<FosterQuestionnaireDecision> decisions;

  List<FosterQuestionnaireAnswer> get triggeringAnswers => answers
      .where(
        (answer) =>
            answer.isTriggering ||
            submission.reviewRequiredAnswers.contains(answer.questionId),
      )
      .toList();

  factory FosterQuestionnaireReview.fromJson(Map<String, dynamic> json) {
    final submissionJson = json['submission'];
    final answersJson = json['answers'];
    final decisionsJson = json['decisions'];
    return FosterQuestionnaireReview(
      submission: submissionJson is Map<String, dynamic>
          ? FosterQuestionnaireSubmission.fromJson(submissionJson)
          : const FosterQuestionnaireSubmission(
              id: '',
              organizationId: '',
              orgFosterParentId: '',
              templateVersion: '',
              result: '',
              q02BMandatoryFollowup: false,
              generalNote: '',
              candidateAcknowledged: false,
            ),
      answers: answersJson is List
          ? answersJson
                .whereType<Map>()
                .map(
                  (item) => FosterQuestionnaireAnswer.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      decisions: decisionsJson is List
          ? decisionsJson
                .whereType<Map>()
                .map(
                  (item) => FosterQuestionnaireDecision.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }
}

/// Canonical decision labels accepted by the backend.
const fosterQuestionnaireDecisionLabels = [
  'Approved',
  'Approved with conditions',
  'Clarification requested',
  'Not approved at this time',
  'Reassessment needed',
];

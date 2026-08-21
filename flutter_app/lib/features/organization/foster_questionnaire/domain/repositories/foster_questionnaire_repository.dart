import '../entities/foster_questionnaire_review.dart';
import '../entities/foster_questionnaire_template.dart';

abstract class FosterQuestionnaireRepository {
  Future<FosterQuestionnaireTemplate> loadTemplate(
    String orgId,
    String token,
  );

  Future<FosterQuestionnaireSubmissionResult> submitQuestionnaire(
    String orgId, {
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
    required String token,
  });

  Future<FosterQuestionnaireReview> getSubmissionReview(
    String orgId,
    String fosterParentId,
    String token,
  );

  Future<FosterQuestionnaireDecision> recordDecision(
    String orgId,
    String submissionId, {
    required String decision,
    required String structuredReason,
    String staffNotes = '',
    required String token,
  });
}

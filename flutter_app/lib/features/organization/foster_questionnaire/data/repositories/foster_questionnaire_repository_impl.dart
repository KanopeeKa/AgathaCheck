import '../../domain/entities/foster_questionnaire_review.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import '../../domain/repositories/foster_questionnaire_repository.dart';
import '../datasources/foster_questionnaire_remote.dart';

class FosterQuestionnaireRepositoryImpl implements FosterQuestionnaireRepository {
  FosterQuestionnaireRepositoryImpl(this._remote);

  final FosterQuestionnaireRemote _remote;

  @override
  Future<FosterQuestionnaireTemplate> loadTemplate(
    String orgId,
    String token,
  ) async {
    final row = await _remote.loadTemplate(orgId, token);
    return FosterQuestionnaireTemplate.fromJson(row);
  }

  @override
  Future<FosterQuestionnaireSubmissionResult> submitQuestionnaire(
    String orgId, {
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
    required String token,
  }) async {
    final row = await _remote.submitQuestionnaire(
      orgId,
      answers: answers,
      generalNote: generalNote,
      candidateAcknowledged: candidateAcknowledged,
      token: token,
    );
    return FosterQuestionnaireSubmissionResult.fromJson(row);
  }

  @override
  Future<FosterQuestionnaireReview> getSubmissionReview(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    final row = await _remote.getSubmissionReview(orgId, fosterParentId, token);
    return FosterQuestionnaireReview.fromJson(row);
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
    final row = await _remote.recordDecision(
      orgId,
      submissionId,
      decision: decision,
      structuredReason: structuredReason,
      staffNotes: staffNotes,
      token: token,
    );
    return FosterQuestionnaireDecision.fromJson(row);
  }
}

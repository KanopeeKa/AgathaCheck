import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../../core/providers/api_base_url_provider.dart';
import '../../../data/datasources/organization_remote/organization_remote_context.dart';
import '../../../presentation/providers/org_provider_deps.dart';
import '../../data/datasources/foster_questionnaire_remote.dart';
import '../../data/repositories/foster_questionnaire_repository_impl.dart';
import '../../domain/entities/foster_questionnaire_review.dart';
import '../../domain/repositories/foster_questionnaire_repository.dart';

final fosterQuestionnaireRemoteProvider = Provider<FosterQuestionnaireRemote>((
  ref,
) {
  return FosterQuestionnaireRemote(
    OrganizationRemoteContext(
      baseUrl: ref.watch(apiBaseUrlProvider),
      client: ref.watch(authHttpClientProvider),
    ),
  );
});

final fosterQuestionnaireRepositoryProvider =
    Provider<FosterQuestionnaireRepository>((ref) {
      return FosterQuestionnaireRepositoryImpl(
        ref.watch(fosterQuestionnaireRemoteProvider),
      );
    });

typedef FosterQuestionnaireReviewKey = ({
  String orgId,
  String fosterParentId,
});

class FosterQuestionnaireReviewNotifier
    extends
        FamilyAsyncNotifier<
          FosterQuestionnaireReview,
          FosterQuestionnaireReviewKey
        > {
  @override
  Future<FosterQuestionnaireReview> build(
    FosterQuestionnaireReviewKey key,
  ) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(fosterQuestionnaireRepositoryProvider)
        .getSubmissionReview(key.orgId, key.fosterParentId, token);
  }

  Future<FosterQuestionnaireDecision> recordDecision({
    required String decision,
    required String structuredReason,
    String staffNotes = '',
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final review = state.requireValue;
    final recorded = await ref
        .read(fosterQuestionnaireRepositoryProvider)
        .recordDecision(
          arg.orgId,
          review.submission.id,
          decision: decision,
          structuredReason: structuredReason,
          staffNotes: staffNotes,
          token: token,
        );
    ref.invalidateSelf();
    return recorded;
  }
}

final fosterQuestionnaireReviewProvider = AsyncNotifierProvider.family<
  FosterQuestionnaireReviewNotifier,
  FosterQuestionnaireReview,
  FosterQuestionnaireReviewKey
>(FosterQuestionnaireReviewNotifier.new);

String localizedFosterQuestionnaireDecisionLabel(
  dynamic l,
  String decision,
) {
  return switch (decision) {
    'Approved' => l.fosterQuestionnaireDecisionApproved,
    'Approved with conditions' =>
      l.fosterQuestionnaireDecisionApprovedWithConditions,
    'Clarification requested' =>
      l.fosterQuestionnaireDecisionClarificationRequested,
    'Not approved at this time' =>
      l.fosterQuestionnaireDecisionNotApprovedAtThisTime,
    'Reassessment needed' => l.fosterQuestionnaireDecisionReassessmentNeeded,
    _ => decision,
  };
}

String localizedFosterQuestionnaireQuestionLabel(dynamic l, String questionId) {
  return switch (questionId) {
    'Q01' => l.fosterQuestionnaireQuestionQ01,
    'Q02' => l.fosterQuestionnaireQuestionQ02,
    'Q03' => l.fosterQuestionnaireQuestionQ03,
    'Q04' => l.fosterQuestionnaireQuestionQ04,
    'Q05' => l.fosterQuestionnaireQuestionQ05,
    'Q06' => l.fosterQuestionnaireQuestionQ06,
    'Q07' => l.fosterQuestionnaireQuestionQ07,
    'Q08' => l.fosterQuestionnaireQuestionQ08,
    _ => questionId,
  };
}

String localizedFosterQuestionnaireOutcomeLabel(dynamic l, String outcome) {
  return switch (outcome) {
    'GO' => l.fosterQuestionnaireOutcomeGo,
    'GO_WITH_RESERVATION' => l.fosterQuestionnaireOutcomeGoWithReservation,
    'NO_GO' => l.fosterQuestionnaireOutcomeNoGo,
    _ => outcome,
  };
}

String fosterQuestionnaireReviewRoutePath(String orgId, String fosterParentId) =>
    '/o/orgs/$orgId/foster-questionnaire/$fosterParentId/review';

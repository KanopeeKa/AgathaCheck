import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../presentation/providers/org_provider_deps.dart';
import '../../domain/entities/foster_questionnaire_template.dart';
import '../controllers/form_state.dart';
import '../controllers/foster_questionnaire_form_controller.dart';
import '../providers/foster_questionnaire_review_providers.dart';
import '../screens/foster_questionnaire_screen.dart';

typedef FosterQuestionnaireFormKey = ({String orgId});

class FosterQuestionnaireFormNotifier
    extends FamilyNotifier<FosterQuestionnaireFormState, FosterQuestionnaireFormKey> {
  late FosterQuestionnaireFormController _controller;

  @override
  FosterQuestionnaireFormState build(FosterQuestionnaireFormKey key) {
    _controller = FosterQuestionnaireFormController(
      orgId: key.orgId,
      loadTemplate: _loadTemplate,
      submitQuestionnaire: _submitQuestionnaire,
    );
    _controller.onStateChanged = (next) => state = next;
    _loadInitialTemplate();
    return const FosterQuestionnaireFormState();
  }

  FosterQuestionnaireFormController get controller => _controller;

  Future<void> _loadInitialTemplate() async {
    try {
      await _controller.initialize();
    } catch (error) {
      state = state.copyWith(validationMessage: '$error');
    }
  }

  Future<FosterQuestionnaireTemplate> _loadTemplate() async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(fosterQuestionnaireRepositoryProvider)
        .loadTemplate(arg.orgId, token);
  }

  Future<FosterQuestionnaireSubmissionResult> _submitQuestionnaire({
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
  }) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    return ref
        .read(fosterQuestionnaireRepositoryProvider)
        .submitQuestionnaire(
          arg.orgId,
          answers: answers,
          generalNote: generalNote,
          candidateAcknowledged: candidateAcknowledged,
          token: token,
        );
  }
}

final fosterQuestionnaireFormProvider = NotifierProvider.family<
  FosterQuestionnaireFormNotifier,
  FosterQuestionnaireFormState,
  FosterQuestionnaireFormKey
>(FosterQuestionnaireFormNotifier.new);

String fosterQuestionnaireRoutePath(String orgId) =>
    '/o/orgs/$orgId/foster-questionnaire';

GoRoute buildFosterQuestionnaireRoute() {
  return GoRoute(
    path: 'foster-questionnaire',
    name: 'fosterQuestionnaire',
    builder: (context, state) {
      final orgId = state.pathParameters['id']!;
      return FosterQuestionnaireScreen(orgId: orgId);
    },
  );
}

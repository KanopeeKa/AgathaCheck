import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/controllers/form_state.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/presentation/controllers/foster_questionnaire_form_controller.dart';
import 'package:pet_profile_app/l10n/app_localizations.dart';

import '../../helpers/fake_foster_questionnaire_repository.dart';

void main() {
  late AppLocalizations l;
  late FakeFosterQuestionnaireRepository repository;
  late FosterQuestionnaireFormController controller;

  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
    repository = FakeFosterQuestionnaireRepository();
    controller = FosterQuestionnaireFormController(
      orgId: 'org-1',
      loadTemplate: () => repository.loadTemplate('org-1', 'token'),
      submitQuestionnaire: ({
        required answers,
        required generalNote,
        required candidateAcknowledged,
      }) => repository.submitQuestionnaire(
        'org-1',
        answers: answers,
        generalNote: generalNote,
        candidateAcknowledged: candidateAcknowledged,
        token: 'token',
      ),
    );
  });

  test('advanceSection validates profile before screening', () async {
    await controller.initialize();

    final advanced = controller.advanceSection(l);

    expect(advanced, isFalse);
    expect(controller.state.validationMessage, l.fosterQuestionnaireSectionIncomplete);
    expect(controller.state.section, FosterQuestionnaireSection.profile);
  });

  test('buildSubmitPayload normalizes availability dates', () async {
    await controller.initialize();
    controller.setAvailabilityStart('2026-09-01');
    controller.setAvailabilityEnd('2026-12-31');

    final payload = controller.state.buildSubmitPayload();
    final pf06 = payload.firstWhere((row) => row['question_id'] == 'PF06');

    expect(pf06['value'], {
      'availability': [
        {'start': '2026-09-01', 'end': '2026-12-31'},
      ],
      'unavailability': [],
    });
  });

  test('submit sends answers when all sections complete', () async {
    await controller.initialize();
    _fillAutoGoAnswers(controller);
    controller.setCandidateAcknowledged(true);

    final error = await controller.submit(l);

    expect(error, isNull);
    expect(controller.state.submitted, isTrue);
    expect(controller.state.submissionResult?.result, 'AUTO_GO');
    expect(repository.lastSubmittedAnswers, isNotNull);
    expect(repository.lastCandidateAcknowledged, isTrue);
  });
}

void _fillAutoGoAnswers(FosterQuestionnaireFormController controller) {
  controller.toggleProfileOption('PF01', 'CAT');
  controller.toggleProfileOption('PF02', 'ADULT');
  controller.toggleProfileOption('PF03', 'NEW');
  controller.toggleProfileOption('PF04', 'ANIMAL_HEALTH_EASY');
  controller.setCapacity('CAT', '1');
  controller.setAvailabilityStart('2026-09-01');
  controller.setAvailabilityEnd('2026-12-31');

  for (final questionId in ['Q01', 'Q02', 'Q03', 'Q04', 'Q05', 'Q06', 'Q07', 'Q08']) {
    controller.selectScreeningOption(questionId, '${questionId}_A');
  }
}

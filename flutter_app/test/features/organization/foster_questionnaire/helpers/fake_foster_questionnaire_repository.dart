import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/entities/foster_questionnaire_review.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/entities/foster_questionnaire_template.dart';
import 'package:pet_profile_app/features/organization/foster_questionnaire/domain/repositories/foster_questionnaire_repository.dart';

/// Test double for foster questionnaire repository with v1.3 default template.
class FakeFosterQuestionnaireRepository
    implements FosterQuestionnaireRepository {
  FakeFosterQuestionnaireRepository({
    this.template = defaultFosterQuestionnaireTemplate,
    this.submitResult = const FosterQuestionnaireSubmissionResult(
      submissionId: 'sub-test',
      result: 'AUTO_GO',
      q02BMandatoryFollowup: false,
    ),
    this.submitDelay = Duration.zero,
    this.submitError,
  });

  final FosterQuestionnaireTemplate template;
  final FosterQuestionnaireSubmissionResult submitResult;
  final Duration submitDelay;
  final Object? submitError;

  List<Map<String, dynamic>>? lastSubmittedAnswers;
  String lastGeneralNote = '';
  bool lastCandidateAcknowledged = false;

  @override
  Future<FosterQuestionnaireTemplate> loadTemplate(
    String orgId,
    String token,
  ) async {
    return template;
  }

  @override
  Future<FosterQuestionnaireSubmissionResult> submitQuestionnaire(
    String orgId, {
    required List<Map<String, dynamic>> answers,
    required String generalNote,
    required bool candidateAcknowledged,
    required String token,
  }) async {
    if (submitDelay > Duration.zero) {
      await Future<void>.delayed(submitDelay);
    }
    if (submitError != null) {
      throw submitError!;
    }
    lastSubmittedAnswers = answers;
    lastGeneralNote = generalNote;
    lastCandidateAcknowledged = candidateAcknowledged;
    return submitResult;
  }

  @override
  Future<FosterQuestionnaireReview> getSubmissionReview(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
  }
}

const defaultFosterQuestionnaireTemplate = FosterQuestionnaireTemplate(
  version: '1.3',
  definition: FosterQuestionnaireDefinition(
    version: '1.3',
    candidateAcknowledgement:
        'I confirm that my answers are accurate to the best of my knowledge.',
    profileFields: [
      FosterProfileField(
        id: 'PF01',
        code: 'SPECIES_WILLING_TO_FOSTER',
        responseType: 'multiSelect',
        required: true,
        options: ['CAT', 'DOG', 'RABBIT', 'HORSE_PONY', 'OTHER'],
      ),
      FosterProfileField(
        id: 'PF02',
        code: 'PET_AGE_RANGE',
        responseType: 'multiSelect',
        required: true,
        options: ['YOUNG', 'ADULT', 'SENIOR', 'ANY_AGE'],
      ),
      FosterProfileField(
        id: 'PF03',
        code: 'EXPERIENCE_LEVEL',
        responseType: 'singleChoice',
        required: true,
        options: [
          {'id': 'EXPERT', 'outcome': 'GO', 'matchingLevel': 'COMPLEX'},
          {'id': 'INTERMEDIARY', 'outcome': 'GO', 'matchingLevel': 'MEDIUM'},
          {'id': 'NEW', 'outcome': 'GO', 'matchingLevel': 'EASY'},
        ],
      ),
      FosterProfileField(
        id: 'PF04',
        code: 'HEALTH_NEEDS_ACCEPTED_IN_ANIMAL',
        responseType: 'singleChoice',
        required: true,
        options: [
          {'id': 'ANIMAL_HEALTH_EASY', 'outcome': 'GO', 'matchingLevel': 'EASY'},
          {
            'id': 'ANIMAL_HEALTH_MEDIUM',
            'outcome': 'GO',
            'matchingLevel': 'MEDIUM',
          },
          {
            'id': 'ANIMAL_HEALTH_COMPLEX',
            'outcome': 'GO',
            'matchingLevel': 'COMPLEX',
          },
          {
            'id': 'ANIMAL_HEALTH_UNSURE',
            'outcome': 'GO',
            'matchingLevel': 'EASY',
          },
        ],
      ),
      FosterProfileField(
        id: 'PF05',
        code: 'CAPACITY_PER_SPECIES',
        responseType: 'numberBySpecies',
        required: true,
      ),
      FosterProfileField(
        id: 'PF06',
        code: 'AVAILABILITY',
        responseType: 'availabilityAndUnavailability',
        required: true,
      ),
    ],
    screeningQuestions: [
      FosterScreeningQuestion(
        id: 'Q01',
        code: 'MINIMUM_AGE',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q01_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q01_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q01_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q02',
        code: 'HOUSEHOLD_AGREEMENT',
        required: true,
        adminNoteRequiredIf: 'Q02_B',
        options: [
          FosterScreeningOption(id: 'Q02_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q02_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q02_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q03',
        code: 'HOUSEHOLD_SAFETY',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q03_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q03_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q03_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q04',
        code: 'TIME_AND_SUPERVISION',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q04_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q04_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q04_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q05',
        code: 'TRANSPORT',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q05_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q05_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q05_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q06',
        code: 'CARE_INSTRUCTIONS',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q06_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q06_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q06_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q07',
        code: 'EMERGENCY_ESCALATION',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q07_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q07_B', outcome: 'GO'),
          FosterScreeningOption(id: 'Q07_C', outcome: 'NO_GO'),
        ],
      ),
      FosterScreeningQuestion(
        id: 'Q08',
        code: 'COMMITMENT_AND_RULES',
        required: true,
        options: [
          FosterScreeningOption(id: 'Q08_A', outcome: 'GO'),
          FosterScreeningOption(id: 'Q08_B', outcome: 'GO_WITH_RESERVATION'),
          FosterScreeningOption(id: 'Q08_C', outcome: 'NO_GO'),
        ],
      ),
    ],
  ),
  settings: FosterQuestionnaireSettings(minimumAge: 21, lightTouchReview: false),
);

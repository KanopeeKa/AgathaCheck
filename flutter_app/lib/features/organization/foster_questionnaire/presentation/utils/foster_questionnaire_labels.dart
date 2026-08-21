import '../../../../../l10n/app_localizations.dart';
import '../controllers/form_state.dart';

String fosterQuestionnaireProfileFieldLabel(AppLocalizations l, String fieldId) =>
    switch (fieldId) {
      'PF01' => l.fosterQuestionnairePf01Label,
      'PF02' => l.fosterQuestionnairePf02Label,
      'PF03' => l.fosterQuestionnairePf03Label,
      'PF04' => l.fosterQuestionnairePf04Label,
      'PF05' => l.fosterQuestionnairePf05Label,
      'PF06' => l.fosterQuestionnairePf06Label,
      _ => fieldId,
    };

String fosterQuestionnaireProfileFieldHelp(AppLocalizations l, String fieldId) =>
    switch (fieldId) {
      'PF03' => l.fosterQuestionnairePf03Help,
      'PF04' => l.fosterQuestionnairePf04Help,
      'PF05' => l.fosterQuestionnairePf05Help,
      'PF06' => l.fosterQuestionnairePf06Help,
      _ => '',
    };

String fosterQuestionnaireProfileOptionLabel(
  AppLocalizations l,
  String optionId,
) =>
    switch (optionId) {
      'CAT' => l.fosterQuestionnaireSpeciesCat,
      'DOG' => l.fosterQuestionnaireSpeciesDog,
      'RABBIT' => l.fosterQuestionnaireSpeciesRabbit,
      'HORSE_PONY' => l.fosterQuestionnaireSpeciesHorsePony,
      'OTHER' => l.fosterQuestionnaireSpeciesOther,
      'YOUNG' => l.fosterQuestionnaireAgeYoung,
      'ADULT' => l.fosterQuestionnaireAgeAdult,
      'SENIOR' => l.fosterQuestionnaireAgeSenior,
      'ANY_AGE' => l.fosterQuestionnaireAgeAny,
      'EXPERT' => l.fosterQuestionnaireExperienceExpert,
      'INTERMEDIARY' => l.fosterQuestionnaireExperienceIntermediate,
      'NEW' => l.fosterQuestionnaireExperienceNew,
      'ANIMAL_HEALTH_EASY' => l.fosterQuestionnaireHealthEasy,
      'ANIMAL_HEALTH_MEDIUM' => l.fosterQuestionnaireHealthMedium,
      'ANIMAL_HEALTH_COMPLEX' => l.fosterQuestionnaireHealthComplex,
      'ANIMAL_HEALTH_UNSURE' => l.fosterQuestionnaireHealthUnsure,
      _ => optionId,
    };

String fosterQuestionnaireScreeningPrompt(AppLocalizations l, String questionId) =>
    switch (questionId) {
      'Q01' => l.fosterQuestionnaireQ01Prompt,
      'Q02' => l.fosterQuestionnaireQ02Prompt,
      'Q03' => l.fosterQuestionnaireQ03Prompt,
      'Q04' => l.fosterQuestionnaireQ04Prompt,
      'Q05' => l.fosterQuestionnaireQ05Prompt,
      'Q06' => l.fosterQuestionnaireQ06Prompt,
      'Q07' => l.fosterQuestionnaireQ07Prompt,
      'Q08' => l.fosterQuestionnaireQ08Prompt,
      _ => questionId,
    };

String fosterQuestionnaireScreeningHelp(AppLocalizations l, String questionId) =>
    switch (questionId) {
      'Q01' => l.fosterQuestionnaireQ01Help,
      'Q02' => l.fosterQuestionnaireQ02Help,
      'Q03' => l.fosterQuestionnaireQ03Help,
      'Q06' => l.fosterQuestionnaireQ06Help,
      'Q07' => l.fosterQuestionnaireQ07Help,
      'Q08' => l.fosterQuestionnaireQ08Help,
      _ => '',
    };

String fosterQuestionnaireScreeningOptionLabel(
  AppLocalizations l,
  String optionId,
) =>
    switch (optionId) {
      'Q01_A' => l.fosterQuestionnaireQ01A,
      'Q01_B' => l.fosterQuestionnaireQ01B,
      'Q01_C' => l.fosterQuestionnaireQ01C,
      'Q02_A' => l.fosterQuestionnaireQ02A,
      'Q02_B' => l.fosterQuestionnaireQ02B,
      'Q02_C' => l.fosterQuestionnaireQ02C,
      'Q03_A' => l.fosterQuestionnaireQ03A,
      'Q03_B' => l.fosterQuestionnaireQ03B,
      'Q03_C' => l.fosterQuestionnaireQ03C,
      'Q04_A' => l.fosterQuestionnaireQ04A,
      'Q04_B' => l.fosterQuestionnaireQ04B,
      'Q04_C' => l.fosterQuestionnaireQ04C,
      'Q05_A' => l.fosterQuestionnaireQ05A,
      'Q05_B' => l.fosterQuestionnaireQ05B,
      'Q05_C' => l.fosterQuestionnaireQ05C,
      'Q06_A' => l.fosterQuestionnaireQ06A,
      'Q06_B' => l.fosterQuestionnaireQ06B,
      'Q06_C' => l.fosterQuestionnaireQ06C,
      'Q07_A' => l.fosterQuestionnaireQ07A,
      'Q07_B' => l.fosterQuestionnaireQ07B,
      'Q07_C' => l.fosterQuestionnaireQ07C,
      'Q08_A' => l.fosterQuestionnaireQ08A,
      'Q08_B' => l.fosterQuestionnaireQ08B,
      'Q08_C' => l.fosterQuestionnaireQ08C,
      _ => optionId,
    };

String fosterQuestionnaireCapacityLabel(AppLocalizations l, String speciesId) =>
    l.fosterQuestionnaireCapacityLabel(
      fosterQuestionnaireProfileOptionLabel(l, speciesId),
    );

String fosterQuestionnaireProfileSemanticsId(String fieldId, String optionId) =>
    'foster_questionnaire_${fieldId}_$optionId';

String fosterQuestionnaireCapacitySemanticsId(String speciesId) =>
    'foster_questionnaire_pf05_$speciesId';

String fosterQuestionnaireScreeningSemanticsId(String optionId) =>
    'foster_questionnaire_$optionId';

String fosterQuestionnaireSectionTitle(
  AppLocalizations l,
  FosterQuestionnaireSection section,
) =>
    switch (section) {
      FosterQuestionnaireSection.profile => l.fosterQuestionnaireSectionProfile,
      FosterQuestionnaireSection.screening => l.fosterQuestionnaireSectionScreening,
      FosterQuestionnaireSection.acknowledgement =>
        l.fosterQuestionnaireSectionAcknowledgement,
    };

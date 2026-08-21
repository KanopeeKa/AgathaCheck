/** Canonical foster candidate questionnaire definition (form v1.3). */
export const FOSTER_QUESTIONNAIRE_VERSION = '1.3';

const screeningOption = (id, outcome) => ({ id, outcome });

export const DEFAULT_FOSTER_QUESTIONNAIRE_V13 = Object.freeze({
  version: FOSTER_QUESTIONNAIRE_VERSION,
  locale: 'en-GB',
  candidateAcknowledgement:
    'I confirm that my answers are accurate to the best of my knowledge. I understand that the shelter will provide guidance and support, that I must follow its instructions and ask for help when needed, and that the shelter will decide which animals are suitable for me to foster.',
  profileFields: Object.freeze([
    {
      id: 'PF01',
      code: 'SPECIES_WILLING_TO_FOSTER',
      responseType: 'multiSelect',
      required: true,
      options: ['CAT', 'DOG', 'RABBIT', 'HORSE_PONY', 'OTHER'],
    },
    {
      id: 'PF02',
      code: 'PET_AGE_RANGE',
      responseType: 'multiSelect',
      required: true,
      options: ['YOUNG', 'ADULT', 'SENIOR', 'ANY_AGE'],
    },
    {
      id: 'PF03',
      code: 'EXPERIENCE_LEVEL',
      responseType: 'singleChoice',
      required: true,
      options: [
        { id: 'EXPERT', outcome: 'GO', matchingLevel: 'COMPLEX' },
        { id: 'INTERMEDIARY', outcome: 'GO', matchingLevel: 'MEDIUM' },
        { id: 'NEW', outcome: 'GO', matchingLevel: 'EASY' },
      ],
    },
    {
      id: 'PF04',
      code: 'HEALTH_NEEDS_ACCEPTED_IN_ANIMAL',
      responseType: 'singleChoice',
      required: true,
      options: [
        { id: 'ANIMAL_HEALTH_EASY', outcome: 'GO', matchingLevel: 'EASY' },
        { id: 'ANIMAL_HEALTH_MEDIUM', outcome: 'GO', matchingLevel: 'MEDIUM' },
        { id: 'ANIMAL_HEALTH_COMPLEX', outcome: 'GO', matchingLevel: 'COMPLEX' },
        { id: 'ANIMAL_HEALTH_UNSURE', outcome: 'GO', matchingLevel: 'EASY' },
      ],
    },
    {
      id: 'PF05',
      code: 'CAPACITY_PER_SPECIES',
      responseType: 'numberBySpecies',
      required: true,
    },
    {
      id: 'PF06',
      code: 'AVAILABILITY',
      responseType: 'availabilityAndUnavailability',
      required: true,
    },
  ]),
  screeningQuestions: Object.freeze([
    {
      id: 'Q01',
      code: 'MINIMUM_AGE',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q01_A', 'GO'),
        screeningOption('Q01_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q01_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q02',
      code: 'HOUSEHOLD_AGREEMENT',
      required: true,
      adminNoteRequiredIf: 'Q02_B',
      options: [
        screeningOption('Q02_A', 'GO'),
        screeningOption('Q02_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q02_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q03',
      code: 'HOUSEHOLD_SAFETY',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q03_A', 'GO'),
        screeningOption('Q03_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q03_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q04',
      code: 'TIME_AND_SUPERVISION',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q04_A', 'GO'),
        screeningOption('Q04_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q04_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q05',
      code: 'TRANSPORT',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q05_A', 'GO'),
        screeningOption('Q05_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q05_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q06',
      code: 'CARE_INSTRUCTIONS',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q06_A', 'GO'),
        screeningOption('Q06_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q06_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q07',
      code: 'EMERGENCY_ESCALATION',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q07_A', 'GO'),
        screeningOption('Q07_B', 'GO'),
        screeningOption('Q07_C', 'NO_GO'),
      ],
    },
    {
      id: 'Q08',
      code: 'COMMITMENT_AND_RULES',
      required: true,
      adminNoteRequiredIf: null,
      options: [
        screeningOption('Q08_A', 'GO'),
        screeningOption('Q08_B', 'GO_WITH_RESERVATION'),
        screeningOption('Q08_C', 'NO_GO'),
      ],
    },
  ]),
});

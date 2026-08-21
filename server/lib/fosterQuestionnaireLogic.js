import { DEFAULT_FOSTER_QUESTIONNAIRE_V13 } from './fosterQuestionnaireDefaultV13.js';

export const QUESTIONNAIRE_RESULT_AUTO_GO = 'AUTO_GO';
export const QUESTIONNAIRE_RESULT_ADMIN_REVIEW = 'ADMIN_REVIEW_REQUIRED';

function definitionMaps(definition) {
  const screeningById = new Map(
    (definition.screeningQuestions || []).map((q) => [q.id, q]),
  );
  const profileById = new Map(
    (definition.profileFields || []).map((f) => [f.id, f]),
  );
  return { screeningById, profileById };
}

export function computeSubmissionResult(screeningOutcomes, settings = {}) {
  const outcomes = screeningOutcomes.filter(Boolean);
  const hasReservation = outcomes.some((o) => o === 'GO_WITH_RESERVATION');
  const hasNoGo = outcomes.some((o) => o === 'NO_GO');
  const allGo = outcomes.length > 0 && outcomes.every((o) => o === 'GO');

  if (hasReservation || hasNoGo) {
    return QUESTIONNAIRE_RESULT_ADMIN_REVIEW;
  }
  if (allGo && settings.light_touch_review === true) {
    return QUESTIONNAIRE_RESULT_ADMIN_REVIEW;
  }
  if (allGo) {
    return QUESTIONNAIRE_RESULT_AUTO_GO;
  }
  return QUESTIONNAIRE_RESULT_ADMIN_REVIEW;
}

export function computeQ02BMandatoryFollowup(answersByQuestionId, definition) {
  const q02 = definition.screeningQuestions.find((q) => q.id === 'Q02');
  if (!q02 || q02.adminNoteRequiredIf !== 'Q02_B') return false;
  const answer = answersByQuestionId.get('Q02');
  return answer?.option_id === 'Q02_B';
}

function validateCalendarDate(value, fieldName) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    const err = new Error(`${fieldName} must be a calendar date (YYYY-MM-DD)`);
    err.statusCode = 400;
    throw err;
  }
}

function validateAnswerValue(field, rawAnswer) {
  const value = rawAnswer?.value ?? rawAnswer?.answer_value ?? null;
  const optionId = (rawAnswer?.option_id || rawAnswer?.optionId || '').trim() || null;
  const note = (rawAnswer?.note || rawAnswer?.candidate_note || '').trim();

  if (field.responseType === 'multiSelect') {
    if (!Array.isArray(value) || value.length === 0) {
      const err = new Error(`${field.id} requires at least one selection`);
      err.statusCode = 400;
      throw err;
    }
    for (const item of value) {
      if (!field.options.includes(item)) {
        const err = new Error(`Invalid option for ${field.id}`);
        err.statusCode = 400;
        throw err;
      }
    }
    return { option_id: null, answer_value: value, candidate_note: note, screening_outcome: null };
  }

  if (field.responseType === 'singleChoice') {
    if (!optionId) {
      const err = new Error(`${field.id} requires a selection`);
      err.statusCode = 400;
      throw err;
    }
    const option = field.options.find((o) => o.id === optionId);
    if (!option) {
      const err = new Error(`Invalid option for ${field.id}`);
      err.statusCode = 400;
      throw err;
    }
    return {
      option_id: optionId,
      answer_value: { matchingLevel: option.matchingLevel || null },
      candidate_note: note,
      screening_outcome: option.outcome || null,
    };
  }

  if (field.responseType === 'numberBySpecies') {
    if (!value || typeof value !== 'object' || Array.isArray(value)) {
      const err = new Error(`${field.id} requires capacity by species`);
      err.statusCode = 400;
      throw err;
    }
    for (const [, count] of Object.entries(value)) {
      if (!Number.isInteger(count) || count < 0) {
        const err = new Error(`${field.id} capacity must be a non-negative whole number`);
        err.statusCode = 400;
        throw err;
      }
    }
    return { option_id: null, answer_value: value, candidate_note: note, screening_outcome: null };
  }

  if (field.responseType === 'availabilityAndUnavailability') {
    const availability = value?.availability;
    const unavailability = value?.unavailability;
    if (!Array.isArray(availability) || availability.length === 0) {
      const err = new Error(`${field.id} requires general availability`);
      err.statusCode = 400;
      throw err;
    }
    if (!Array.isArray(unavailability)) {
      const err = new Error(`${field.id} unavailability must be an array`);
      err.statusCode = 400;
      throw err;
    }
    for (const period of [...availability, ...unavailability]) {
      if (period?.start) validateCalendarDate(period.start, `${field.id} start date`);
      if (period?.end) validateCalendarDate(period.end, `${field.id} end date`);
    }
    return { option_id: null, answer_value: value, candidate_note: note, screening_outcome: null };
  }

  const err = new Error(`Unsupported field type for ${field.id}`);
  err.statusCode = 400;
  throw err;
}

function validateScreeningAnswer(question, rawAnswer) {
  const optionId = (rawAnswer?.option_id || rawAnswer?.optionId || '').trim();
  const note = (rawAnswer?.note || rawAnswer?.candidate_note || '').trim();
  if (!optionId) {
    const err = new Error(`${question.id} requires an answer`);
    err.statusCode = 400;
    throw err;
  }
  const option = question.options.find((o) => o.id === optionId);
  if (!option) {
    const err = new Error(`Invalid option for ${question.id}`);
    err.statusCode = 400;
    throw err;
  }
  return {
    option_id: optionId,
    answer_value: null,
    candidate_note: note,
    screening_outcome: option.outcome,
  };
}

export function normaliseSubmittedAnswers(rawAnswers, definition = DEFAULT_FOSTER_QUESTIONNAIRE_V13) {
  if (!Array.isArray(rawAnswers) || rawAnswers.length === 0) {
    const err = new Error('Answers are required');
    err.statusCode = 400;
    throw err;
  }

  const { screeningById, profileById } = definitionMaps(definition);
  const answersByQuestionId = new Map();
  const normalised = [];

  for (const raw of rawAnswers) {
    const questionId = (raw?.question_id || raw?.questionId || '').trim();
    if (!questionId) {
      const err = new Error('Each answer requires question_id');
      err.statusCode = 400;
      throw err;
    }
    if (answersByQuestionId.has(questionId)) {
      const err = new Error(`Duplicate answer for ${questionId}`);
      err.statusCode = 400;
      throw err;
    }

    let parsed;
    if (screeningById.has(questionId)) {
      parsed = validateScreeningAnswer(screeningById.get(questionId), raw);
    } else if (profileById.has(questionId)) {
      parsed = validateAnswerValue(profileById.get(questionId), raw);
    } else {
      const err = new Error(`Unknown question ${questionId}`);
      err.statusCode = 400;
      throw err;
    }

    const row = { question_id: questionId, ...parsed };
    answersByQuestionId.set(questionId, row);
    normalised.push(row);
  }

  for (const question of definition.screeningQuestions) {
    if (question.required && !answersByQuestionId.has(question.id)) {
      const err = new Error(`Missing required question ${question.id}`);
      err.statusCode = 400;
      throw err;
    }
  }
  for (const field of definition.profileFields) {
    if (field.required && !answersByQuestionId.has(field.id)) {
      const err = new Error(`Missing required field ${field.id}`);
      err.statusCode = 400;
      throw err;
    }
  }

  return { normalised, answersByQuestionId };
}

export function deriveMatchingProfile(answersByQuestionId) {
  const pick = (id) => answersByQuestionId.get(id)?.answer_value ?? null;
  const pickOption = (id) => answersByQuestionId.get(id)?.option_id ?? null;
  return {
    pf01: pick('PF01'),
    pf02: pick('PF02'),
    pf03: { option_id: pickOption('PF03'), ...(pick('PF03') || {}) },
    pf04: { option_id: pickOption('PF04'), ...(pick('PF04') || {}) },
    pf05: pick('PF05'),
    pf06: pick('PF06'),
  };
}

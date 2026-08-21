/**
 * Foster candidate questionnaire engine (form v1.3, J1 Phase 5).
 */
import { v4 as uuidv4 } from 'uuid';

import { logAuditEventSafe } from './audit.js';
import {
  DEFAULT_FOSTER_QUESTIONNAIRE_V13,
  FOSTER_QUESTIONNAIRE_VERSION,
} from './fosterQuestionnaireDefaultV13.js';
import {
  computeQ02BMandatoryFollowup,
  computeSubmissionResult,
  deriveMatchingProfile,
  normaliseSubmittedAnswers,
  QUESTIONNAIRE_RESULT_ADMIN_REVIEW,
  QUESTIONNAIRE_RESULT_AUTO_GO,
} from './fosterQuestionnaireLogic.js';

export {
  computeQ02BMandatoryFollowup,
  computeSubmissionResult,
  deriveMatchingProfile,
  normaliseSubmittedAnswers,
  QUESTIONNAIRE_RESULT_ADMIN_REVIEW,
  QUESTIONNAIRE_RESULT_AUTO_GO,
};

export const AUDIT_FORM_STARTED = 'FOSTER_CANDIDATE_FORM_STARTED';
export const AUDIT_FORM_SUBMITTED = 'FOSTER_CANDIDATE_FORM_SUBMITTED';
export const AUDIT_PROFILE_UPDATED = 'FOSTER_CANDIDATE_PROFILE_UPDATED';
export const AUDIT_REVIEW_REQUESTED = 'FOSTER_CANDIDATE_REVIEW_REQUESTED';
export const AUDIT_DECISION_RECORDED = 'FOSTER_CANDIDATE_DECISION_RECORDED';

export const QUESTIONNAIRE_RESOURCE = 'foster_questionnaire_submission';

const RECOMMENDED_DECISIONS = new Set([
  'Approved',
  'Approved with conditions',
  'Clarification requested',
  'Not approved at this time',
  'Reassessment needed',
]);

export function getDefaultQuestionnaireDefinition() {
  return DEFAULT_FOSTER_QUESTIONNAIRE_V13;
}

export function submissionToMap(row, extras = {}) {
  return {
    id: row.id,
    organization_id: row.organization_id,
    org_foster_parent_id: row.org_foster_parent_id,
    template_version: row.template_version,
    result: row.result,
    q02_b_mandatory_followup: row.q02_b_mandatory_followup === true,
    general_note: row.general_note || '',
    candidate_acknowledged: row.candidate_acknowledged === true,
    submitted_at: row.submitted_at,
    submitted_by_user_id: row.submitted_by_user_id || null,
    ...extras,
  };
}

export function answerToMap(row) {
  return {
    id: row.id,
    question_id: row.question_id,
    option_id: row.option_id || null,
    answer_value: row.answer_value ?? null,
    candidate_note: row.candidate_note || '',
    screening_outcome: row.screening_outcome || null,
  };
}

export function matchingProfileToMap(row) {
  return {
    pf01: row.pf01 ?? null,
    pf02: row.pf02 ?? null,
    pf03: row.pf03 ?? null,
    pf04: row.pf04 ?? null,
    pf05: row.pf05 ?? null,
    pf06: row.pf06 ?? null,
    derived_at: row.derived_at,
  };
}

export function decisionToMap(row) {
  return {
    id: row.id,
    submission_id: row.submission_id,
    decision: row.decision,
    structured_reason: row.structured_reason || '',
    staff_notes: row.staff_notes || '',
    decided_by: row.decided_by || null,
    decided_at: row.decided_at,
  };
}

function auditQuestionnaire(pool, event) {
  logAuditEventSafe(pool, {
    resourceType: QUESTIONNAIRE_RESOURCE,
    ...event,
  });
}

export async function loadOrgQuestionnaireSettings(pool, orgId) {
  const result = await pool.query(
    `SELECT minimum_age, light_touch_review
     FROM foster_questionnaire_org_settings
     WHERE organization_id = $1`,
    [orgId],
  );
  if (result.rows.length === 0) {
    return { minimum_age: 21, light_touch_review: false };
  }
  const row = result.rows[0];
  return {
    minimum_age: row.minimum_age ?? 21,
    light_touch_review: row.light_touch_review === true,
  };
}

export async function ensureOrgQuestionnaireSettings(pool, orgId) {
  await pool.query(
    `INSERT INTO foster_questionnaire_org_settings (organization_id)
     VALUES ($1)
     ON CONFLICT (organization_id) DO NOTHING`,
    [orgId],
  );
  return loadOrgQuestionnaireSettings(pool, orgId);
}

export async function ensureOrgQuestionnaireTemplate(pool, orgId) {
  const existing = await pool.query(
    `SELECT id, version, definition, created_at, updated_at
     FROM foster_questionnaire_templates
     WHERE organization_id = $1 AND version = $2`,
    [orgId, FOSTER_QUESTIONNAIRE_VERSION],
  );
  if (existing.rows.length > 0) {
    return existing.rows[0];
  }

  const definition = getDefaultQuestionnaireDefinition();
  const id = uuidv4();
  const insert = await pool.query(
    `INSERT INTO foster_questionnaire_templates (
       id, organization_id, version, definition
     ) VALUES ($1, $2, $3, $4::jsonb)
     RETURNING id, version, definition, created_at, updated_at`,
    [id, orgId, FOSTER_QUESTIONNAIRE_VERSION, JSON.stringify(definition)],
  );
  return insert.rows[0];
}

export async function hasQuestionnaireSubmission(pool, orgId, fosterParentId) {
  if (!fosterParentId) return false;
  const result = await pool.query(
    `SELECT 1 FROM foster_questionnaire_submissions
     WHERE organization_id = $1 AND org_foster_parent_id = $2
     LIMIT 1`,
    [orgId, fosterParentId],
  );
  return result.rows.length > 0;
}

export async function loadCandidateTemplate(pool, orgId, fosterParentId, actorUserId, req) {
  await ensureOrgQuestionnaireSettings(pool, orgId);
  const template = await ensureOrgQuestionnaireTemplate(pool, orgId);
  const settings = await loadOrgQuestionnaireSettings(pool, orgId);

  const existing = await pool.query(
    `SELECT id FROM foster_questionnaire_submissions
     WHERE organization_id = $1 AND org_foster_parent_id = $2
     LIMIT 1`,
    [orgId, fosterParentId],
  );
  if (existing.rows.length === 0) {
    auditQuestionnaire(pool, {
      actorUserId,
      action: AUDIT_FORM_STARTED,
      resourceId: fosterParentId,
      orgId,
      metadata: { org_foster_parent_id: fosterParentId, template_version: template.version },
      req,
    });
  }

  return {
    version: template.version,
    definition: typeof template.definition === 'object'
      ? template.definition
      : JSON.parse(template.definition),
    settings,
  };
}

export async function submitQuestionnaire(pool, {
  orgId,
  fosterParentId,
  submittedByUserId,
  rawAnswers,
  generalNote = '',
  candidateAcknowledged = false,
  req = null,
}) {
  if (candidateAcknowledged !== true) {
    return { error: 'candidate_acknowledged is required', status: 400 };
  }

  const existing = await pool.query(
    `SELECT id FROM foster_questionnaire_submissions
     WHERE organization_id = $1 AND org_foster_parent_id = $2`,
    [orgId, fosterParentId],
  );
  if (existing.rows.length > 0) {
    return { error: 'Questionnaire already submitted', status: 409 };
  }

  const template = await ensureOrgQuestionnaireTemplate(pool, orgId);
  const settings = await ensureOrgQuestionnaireSettings(pool, orgId);
  const definition = typeof template.definition === 'object'
    ? template.definition
    : JSON.parse(template.definition);

  let normalised;
  let answersByQuestionId;
  try {
    ({ normalised, answersByQuestionId } = normaliseSubmittedAnswers(rawAnswers, definition));
  } catch (err) {
    return { error: err.message, status: err.statusCode || 400 };
  }

  const screeningOutcomes = definition.screeningQuestions.map(
    (q) => answersByQuestionId.get(q.id)?.screening_outcome,
  );
  const result = computeSubmissionResult(screeningOutcomes, settings);
  const q02Flag = computeQ02BMandatoryFollowup(answersByQuestionId, definition);
  const matching = deriveMatchingProfile(answersByQuestionId);
  const submissionId = uuidv4();

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const submissionResult = await client.query(
      `INSERT INTO foster_questionnaire_submissions (
         id, organization_id, org_foster_parent_id, template_version, result,
         q02_b_mandatory_followup, general_note, candidate_acknowledged, submitted_by_user_id
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING *`,
      [
        submissionId,
        orgId,
        fosterParentId,
        template.version,
        result,
        q02Flag,
        (generalNote || '').trim(),
        true,
        submittedByUserId,
      ],
    );

    for (const answer of normalised) {
      await client.query(
        `INSERT INTO foster_questionnaire_answers (
           id, submission_id, question_id, option_id, answer_value, candidate_note, screening_outcome
         ) VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7)`,
        [
          uuidv4(),
          submissionId,
          answer.question_id,
          answer.option_id,
          answer.answer_value ? JSON.stringify(answer.answer_value) : null,
          answer.candidate_note || '',
          answer.screening_outcome,
        ],
      );
    }

    await client.query(
      `INSERT INTO foster_matching_profiles (
         id, submission_id, pf01, pf02, pf03, pf04, pf05, pf06
       ) VALUES ($1, $2, $3::jsonb, $4::jsonb, $5::jsonb, $6::jsonb, $7::jsonb, $8::jsonb)`,
      [
        uuidv4(),
        submissionId,
        JSON.stringify(matching.pf01),
        JSON.stringify(matching.pf02),
        JSON.stringify(matching.pf03),
        JSON.stringify(matching.pf04),
        JSON.stringify(matching.pf05),
        JSON.stringify(matching.pf06),
      ],
    );

    await client.query('COMMIT');

    auditQuestionnaire(pool, {
      actorUserId: submittedByUserId,
      action: AUDIT_FORM_SUBMITTED,
      resourceId: submissionId,
      orgId,
      metadata: {
        org_foster_parent_id: fosterParentId,
        template_version: template.version,
        result,
        q02_b_mandatory_followup: q02Flag,
      },
      req,
    });
    auditQuestionnaire(pool, {
      actorUserId: submittedByUserId,
      action: AUDIT_PROFILE_UPDATED,
      resourceId: submissionId,
      orgId,
      metadata: { org_foster_parent_id: fosterParentId },
      req,
    });
    if (result === QUESTIONNAIRE_RESULT_ADMIN_REVIEW) {
      auditQuestionnaire(pool, {
        actorUserId: submittedByUserId,
        action: AUDIT_REVIEW_REQUESTED,
        resourceId: submissionId,
        orgId,
        metadata: {
          org_foster_parent_id: fosterParentId,
          q02_b_mandatory_followup: q02Flag,
        },
        req,
      });
    }

    return { status: 200, submission: submissionResult.rows[0], matching };
  } catch (err) {
    try { await client.query('ROLLBACK'); } catch (_) { /* ignore */ }
    throw err;
  } finally {
    client.release();
  }
}

export async function loadSubmissionForReview(pool, orgId, fosterParentId) {
  const submissionResult = await pool.query(
    `SELECT * FROM foster_questionnaire_submissions
     WHERE organization_id = $1 AND org_foster_parent_id = $2`,
    [orgId, fosterParentId],
  );
  if (submissionResult.rows.length === 0) return null;

  const submission = submissionResult.rows[0];
  const [answersResult, profileResult, decisionsResult] = await Promise.all([
    pool.query(
      `SELECT * FROM foster_questionnaire_answers
       WHERE submission_id = $1
       ORDER BY question_id`,
      [submission.id],
    ),
    pool.query(
      'SELECT * FROM foster_matching_profiles WHERE submission_id = $1',
      [submission.id],
    ),
    pool.query(
      `SELECT * FROM foster_questionnaire_decisions
       WHERE submission_id = $1
       ORDER BY decided_at DESC`,
      [submission.id],
    ),
  ]);

  return {
    submission,
    answers: answersResult.rows,
    matching_profile: profileResult.rows[0] || null,
    decisions: decisionsResult.rows,
  };
}

export async function recordAdminDecision(pool, {
  orgId,
  submissionId,
  decision,
  structuredReason,
  staffNotes,
  decidedByUserId,
  req = null,
}) {
  const trimmedDecision = (decision || '').trim();
  const trimmedReason = (structuredReason != null ? String(structuredReason) : '').trim();
  const trimmedNotes = (staffNotes || '').trim();

  if (!trimmedDecision) {
    return { error: 'decision is required', status: 400 };
  }
  if (!RECOMMENDED_DECISIONS.has(trimmedDecision)) {
    return { error: 'Invalid decision label', status: 400 };
  }
  if (!trimmedReason) {
    return { error: 'structured_reason is required', status: 400 };
  }

  const submissionResult = await pool.query(
    `SELECT * FROM foster_questionnaire_submissions
     WHERE id = $1 AND organization_id = $2`,
    [submissionId, orgId],
  );
  if (submissionResult.rows.length === 0) {
    return { error: 'Submission not found', status: 404 };
  }
  const submission = submissionResult.rows[0];

  const id = uuidv4();
  const insert = await pool.query(
    `INSERT INTO foster_questionnaire_decisions (
       id, submission_id, decision, structured_reason, staff_notes, decided_by
     ) VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [id, submissionId, trimmedDecision, trimmedReason, trimmedNotes, decidedByUserId],
  );

  auditQuestionnaire(pool, {
    actorUserId: decidedByUserId,
    action: AUDIT_DECISION_RECORDED,
    resourceId: submissionId,
    orgId,
    metadata: {
      decision: trimmedDecision,
      org_foster_parent_id: submission.org_foster_parent_id,
    },
    req,
  });

  return { status: 200, decision: insert.rows[0] };
}

export async function resolveFosterParentForUser(pool, orgId, userId) {
  const result = await pool.query(
    `SELECT id, user_id, approval_state
     FROM org_foster_parents
     WHERE organization_id = $1 AND user_id = $2 AND opt_out_at IS NULL
     ORDER BY created_at DESC
     LIMIT 1`,
    [orgId, userId],
  );
  return result.rows[0] || null;
}

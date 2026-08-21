import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  buildFosterOnboardingSteps,
} from '../../routes/organizations/fosterOnboarding.js';
import {
  computeQ02BMandatoryFollowup,
  computeSubmissionResult,
  normaliseSubmittedAnswers,
  QUESTIONNAIRE_RESULT_ADMIN_REVIEW,
  QUESTIONNAIRE_RESULT_AUTO_GO,
  submitQuestionnaire,
} from '../../lib/fosterQuestionnaire.js';
import { DEFAULT_FOSTER_QUESTIONNAIRE_V13 } from '../../lib/fosterQuestionnaireDefaultV13.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const adminToken = jwt.sign({ id: userId, email: 'admin@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const fosterToken = jwt.sign({ id: 'foster-user', email: 'foster@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const fosterParentId = 'fp-1';

function externalContext(overrides = {}) {
  return {
    kind: 'external', personId: fosterParentId, fosterParentId, userId: null,
    role: null, isPending: false, approvalState: 'under_review', rulesAgreementAt: null,
    fosterProfileId: 'prof-1', confirmedCompetencies: [], questionnaireSubmitted: false,
    ...overrides,
  };
}

function allGoAnswers(overrides = {}) {
  const screening = DEFAULT_FOSTER_QUESTIONNAIRE_V13.screeningQuestions.map((q) => ({
    question_id: q.id,
    option_id: `${q.id}_A`,
  }));
  const profile = [
    { question_id: 'PF01', value: ['CAT'] },
    { question_id: 'PF02', value: ['ADULT'] },
    { question_id: 'PF03', option_id: 'NEW' },
    { question_id: 'PF04', option_id: 'ANIMAL_HEALTH_EASY' },
    { question_id: 'PF05', value: { CAT: 1 } },
    {
      question_id: 'PF06',
      value: {
        availability: [{ start: '2026-01-01', end: '2026-12-31' }],
        unavailability: [],
      },
    },
  ];
  return [...screening, ...profile].map((a) => {
    const override = overrides[a.question_id];
    return override ? { ...a, ...override } : a;
  });
}

describe('fosterQuestionnaire logic', () => {
  it('returns AUTO_GO when all screening answers are GO', () => {
    const outcomes = DEFAULT_FOSTER_QUESTIONNAIRE_V13.screeningQuestions.map(() => 'GO');
    expect(computeSubmissionResult(outcomes)).toBe(QUESTIONNAIRE_RESULT_AUTO_GO);
  });

  it('returns ADMIN_REVIEW_REQUIRED when any answer is GO_WITH_RESERVATION', () => {
    const outcomes = DEFAULT_FOSTER_QUESTIONNAIRE_V13.screeningQuestions.map(() => 'GO');
    outcomes[1] = 'GO_WITH_RESERVATION';
    expect(computeSubmissionResult(outcomes)).toBe(QUESTIONNAIRE_RESULT_ADMIN_REVIEW);
  });

  it('returns ADMIN_REVIEW_REQUIRED when any answer is NO_GO', () => {
    const outcomes = DEFAULT_FOSTER_QUESTIONNAIRE_V13.screeningQuestions.map(() => 'GO');
    outcomes[0] = 'NO_GO';
    expect(computeSubmissionResult(outcomes)).toBe(QUESTIONNAIRE_RESULT_ADMIN_REVIEW);
  });

  it('returns ADMIN_REVIEW_REQUIRED for all GO when light_touch_review is enabled', () => {
    const outcomes = DEFAULT_FOSTER_QUESTIONNAIRE_V13.screeningQuestions.map(() => 'GO');
    expect(computeSubmissionResult(outcomes, { light_touch_review: true }))
      .toBe(QUESTIONNAIRE_RESULT_ADMIN_REVIEW);
  });

  it('flags Q02_B mandatory admin follow-up', () => {
    const { answersByQuestionId } = normaliseSubmittedAnswers(
      allGoAnswers({ Q02: { question_id: 'Q02', option_id: 'Q02_B' } }),
    );
    expect(computeQ02BMandatoryFollowup(answersByQuestionId, DEFAULT_FOSTER_QUESTIONNAIRE_V13))
      .toBe(true);
  });

  it('does not flag Q02_B follow-up for Q02_A', () => {
    const { answersByQuestionId } = normaliseSubmittedAnswers(allGoAnswers());
    expect(computeQ02BMandatoryFollowup(answersByQuestionId, DEFAULT_FOSTER_QUESTIONNAIRE_V13))
      .toBe(false);
  });
});

describe('submitQuestionnaire', () => {
  function buildSubmitPool({ lightTouchReview = false, existingSubmission = false } = {}) {
    const inserts = [];
    const client = {
      query: jest.fn(async (sql, params) => {
        if (sql === 'BEGIN' || sql === 'COMMIT' || sql === 'ROLLBACK') return { rows: [] };
        if (sql.includes('INSERT INTO foster_questionnaire_submissions')) {
          inserts.push({ sql, params });
          return {
            rows: [{
              id: 'sub-1',
              organization_id: orgId,
              org_foster_parent_id: fosterParentId,
              template_version: '1.3',
              result: params[4],
              q02_b_mandatory_followup: params[5],
              general_note: params[6],
              candidate_acknowledged: true,
              submitted_at: '2026-08-21T12:00:00.000Z',
              submitted_by_user_id: params[8],
            }],
          };
        }
        if (sql.includes('INSERT INTO foster_questionnaire_answers')
          || sql.includes('INSERT INTO foster_matching_profiles')) {
          return { rows: [] };
        }
        return { rows: [] };
      }),
      release: jest.fn(),
    };

    return {
      inserts,
      connect: jest.fn(async () => client),
      query: jest.fn(async (sql) => {
        if (sql.includes('FROM foster_questionnaire_submissions')) {
          return { rows: existingSubmission ? [{ id: 'existing' }] : [] };
        }
        if (sql.includes('FROM foster_questionnaire_templates')) {
          return {
            rows: [{
              version: '1.3',
              definition: DEFAULT_FOSTER_QUESTIONNAIRE_V13,
            }],
          };
        }
        if (sql.includes('INSERT INTO foster_questionnaire_templates')) {
          return {
            rows: [{
              version: '1.3',
              definition: DEFAULT_FOSTER_QUESTIONNAIRE_V13,
            }],
          };
        }
        if (sql.includes('foster_questionnaire_org_settings')) {
          return {
            rows: [{
              minimum_age: 21,
              light_touch_review: lightTouchReview,
            }],
          };
        }
        if (sql.includes('INSERT INTO audit_events')) return { rows: [{ id: 'audit-1' }] };
        return { rows: [] };
      }),
    };
  }

  it('persists AUTO_GO submission for all-go answers', async () => {
    const pool = buildSubmitPool();
    const result = await submitQuestionnaire(pool, {
      orgId,
      fosterParentId,
      submittedByUserId: fosterToken ? 'foster-user' : userId,
      rawAnswers: allGoAnswers(),
      candidateAcknowledged: true,
    });
    expect(result.status).toBe(200);
    expect(result.submission.result).toBe(QUESTIONNAIRE_RESULT_AUTO_GO);
    expect(result.submission.q02_b_mandatory_followup).toBe(false);
  });

  it('persists ADMIN_REVIEW_REQUIRED for Q02_B with mandatory follow-up flag', async () => {
    const pool = buildSubmitPool();
    const result = await submitQuestionnaire(pool, {
      orgId,
      fosterParentId,
      submittedByUserId: 'foster-user',
      rawAnswers: allGoAnswers({ Q02: { question_id: 'Q02', option_id: 'Q02_B' } }),
      candidateAcknowledged: true,
    });
    expect(result.submission.result).toBe(QUESTIONNAIRE_RESULT_ADMIN_REVIEW);
    expect(result.submission.q02_b_mandatory_followup).toBe(true);
  });

  it('requires admin review for all-go when light_touch_review is enabled', async () => {
    const pool = buildSubmitPool({ lightTouchReview: true });
    const result = await submitQuestionnaire(pool, {
      orgId,
      fosterParentId,
      submittedByUserId: 'foster-user',
      rawAnswers: allGoAnswers(),
      candidateAcknowledged: true,
    });
    expect(result.submission.result).toBe(QUESTIONNAIRE_RESULT_ADMIN_REVIEW);
  });
});

describe('foster questionnaire routes', () => {
  function buildPool({ viewerRole = 'admin', fosterRole = 'foster', fosterLinked = true } = {}) {
    const submissions = new Map();
    return {
      query: jest.fn(async (sql, params) => {
        if (sql.includes('SELECT role') && sql.includes('organization_users')) {
          const uid = params[1];
          if (uid === 'foster-user') return { rows: [{ role: fosterRole }] };
          return { rows: [{ role: viewerRole }] };
        }
        if (sql.includes('FROM organization_permissions')) return { rows: [] };
        if (sql.includes('FROM organization_role_permission_defaults')) return { rows: [] };
        if (sql.includes('FROM org_foster_parents') && sql.includes('user_id = $2')) {
          if (!fosterLinked && params[1] === 'foster-user') return { rows: [] };
          return {
            rows: [{
              id: fosterParentId,
              user_id: params[1],
              approval_state: 'under_review',
            }],
          };
        }
        if (sql.includes('FROM foster_questionnaire_submissions')
          && sql.includes('org_foster_parent_id = $2')) {
          const row = submissions.get(params[1]);
          return { rows: row ? [row] : [] };
        }
        if (sql.includes('FROM foster_questionnaire_templates')) {
          return {
            rows: [{
              id: 'tpl-1',
              version: '1.3',
              definition: DEFAULT_FOSTER_QUESTIONNAIRE_V13,
            }],
          };
        }
        if (sql.includes('INSERT INTO foster_questionnaire_templates')) {
          return {
            rows: [{
              version: '1.3',
              definition: DEFAULT_FOSTER_QUESTIONNAIRE_V13,
            }],
          };
        }
        if (sql.includes('foster_questionnaire_org_settings')) {
          return { rows: [{ minimum_age: 21, light_touch_review: false }] };
        }
        if (sql.includes('INSERT INTO audit_events')) return { rows: [{ id: 'audit-1' }] };
        if (sql.includes('FROM foster_questionnaire_answers')) return { rows: [] };
        if (sql.includes('FROM foster_matching_profiles')) return { rows: [] };
        if (sql.includes('FROM foster_questionnaire_decisions')) return { rows: [] };
        return { rows: [] };
      }),
      connect: jest.fn(async () => ({
        query: jest.fn(async (sql, p) => {
          if (sql.includes('INSERT INTO foster_questionnaire_submissions')) {
            submissions.set(fosterParentId, {
              id: 'sub-1',
              organization_id: orgId,
              org_foster_parent_id: fosterParentId,
              template_version: '1.3',
              result: p[4],
              q02_b_mandatory_followup: p[5],
              general_note: '',
              candidate_acknowledged: true,
              submitted_at: '2026-08-21T12:00:00.000Z',
              submitted_by_user_id: p[8],
            });
            return { rows: [submissions.get(fosterParentId)] };
          }
          return { rows: [] };
        }),
        release: jest.fn(),
      })),
      _submissions: submissions,
    };
  }

  it('returns template for foster candidate', async () => {
    const app = createApp(buildPool());
    const res = await request(app)
      .get(`/api/organizations/${orgId}/foster-questionnaire/template`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.version).toBe('1.3');
    expect(res.body.settings.minimum_age).toBe(21);
  });

  it('returns 403 for non-foster member on template', async () => {
    const app = createApp(buildPool({ fosterRole: 'associate', fosterLinked: false }));
    const res = await request(app)
      .get(`/api/organizations/${orgId}/foster-questionnaire/template`)
      .set('Authorization', `Bearer ${fosterToken}`);
    expect(res.statusCode).toBe(403);
  });

  it('allows admin to fetch submission for review', async () => {
    const pool = buildPool();
    pool._submissions.set(fosterParentId, {
      id: 'sub-1',
      organization_id: orgId,
      org_foster_parent_id: fosterParentId,
      template_version: '1.3',
      result: QUESTIONNAIRE_RESULT_ADMIN_REVIEW,
      q02_b_mandatory_followup: true,
      general_note: '',
      candidate_acknowledged: true,
      submitted_at: '2026-08-21T12:00:00.000Z',
      submitted_by_user_id: 'foster-user',
    });
    const app = createApp(pool);
    const res = await request(app)
      .get(`/api/organizations/${orgId}/foster-questionnaire/submissions/${fosterParentId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.submission.q02_b_mandatory_followup).toBe(true);
  });
});

describe('fosterOnboarding onboarding_form auto-complete', () => {
  it('marks onboarding_form complete when questionnaire submitted', () => {
    const steps = buildFosterOnboardingSteps(
      externalContext({ questionnaireSubmitted: true }),
    );
    expect(steps.find((s) => s.key === 'onboarding_form')?.state).toBe('complete');
    expect(steps.find((s) => s.key === 'onboarding_form')?.deferred).toBe(false);
  });
});

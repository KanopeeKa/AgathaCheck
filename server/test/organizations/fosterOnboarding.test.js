import request from 'supertest';
import jwt from 'jsonwebtoken';
import { createApp } from '../../bin/server.js';
import {
  buildFosterOnboardingSteps,
  confirmFosterOnboardingStep,
  FOSTER_ONBOARDING_STEP_KEYS,
  isValidFosterOnboardingStepKey,
  personHasFosterRelationship,
} from '../../routes/organizations/fosterOnboarding.js';

const JWT_SECRET = process.env.JWT_SECRET || process.env.SESSION_SECRET || 'default_secret';
const userId = 'test-user-id';
const token = jwt.sign({ id: userId, email: 'test@example.com' }, JWT_SECRET, { expiresIn: '1h' });
const orgId = 'org-1';
const externalId = 'fp-1';

function externalContext(overrides = {}) {
  return {
    kind: 'external', personId: externalId, fosterParentId: externalId, userId: null,
    role: null, isPending: false, approvalState: 'under_review', rulesAgreementAt: null,
    fosterProfileId: 'prof-1', confirmedCompetencies: [], ...overrides,
  };
}

describe('fosterOnboarding helpers', () => {
  it('validates step keys', () => {
    expect(isValidFosterOnboardingStepKey('connected')).toBe(true);
    expect(FOSTER_ONBOARDING_STEP_KEYS).toHaveLength(9);
  });

  it('detects foster relationships', () => {
    expect(personHasFosterRelationship(externalContext())).toBe(true);
  });

  it('marks deferred steps', () => {
    const steps = buildFosterOnboardingSteps(externalContext());
    expect(steps.find((s) => s.key === 'onboarding_form')?.deferred).toBe(true);
    expect(steps.find((s) => s.key === 'invitation_accepted')?.state).toBe('current');
  });

  it('auto-completes onboarding_form when questionnaire submitted', () => {
    const steps = buildFosterOnboardingSteps(externalContext({ questionnaireSubmitted: true }));
    expect(steps.find((s) => s.key === 'onboarding_form')?.state).toBe('complete');
  });

  it('auto-completes home_visit when validated yes exists', () => {
    const steps = buildFosterOnboardingSteps(externalContext({ homeVisitValidatedYes: true }));
    expect(steps.find((s) => s.key === 'home_visit')?.state).toBe('complete');
  });
});

describe('POST foster onboarding step confirm', () => {
  const auditInserts = [];
  function buildPool({ viewerRole = 'admin' } = {}) {
    return {
      query: jest.fn(async (sql) => {
        if (sql.includes('SELECT role')) return { rows: [{ role: viewerRole }] };
        if (sql.includes('SELECT permission_key')) return { rows: [] };
        if (sql.includes('FROM org_foster_parents')) {
          return { rows: [{ foster_parent_id: externalId, approval_state: 'under_review', foster_profile_id: 'prof-1', confirmed_competencies: '[]' }] };
        }
        if (sql.includes('FROM audit_events')) return { rows: [] };
        if (sql.includes('INSERT INTO audit_events')) { auditInserts.push(sql); return { rows: [{ id: 'a1' }] }; }
        return { rows: [] };
      }),
    };
  }

  it('writes audit event', async () => {
    auditInserts.length = 0;
    const result = await confirmFosterOnboardingStep(buildPool(), orgId, 'external', externalId, 'home_visit', userId, null);
    expect(result.step_key).toBe('home_visit');
    expect(auditInserts.length).toBe(1);
  });

  it('returns 403 without permission', async () => {
    const app = createApp(buildPool({ viewerRole: 'associate' }));
    const res = await request(app)
      .post(`/api/organizations/${orgId}/people/external/${externalId}/foster-onboarding/steps/home_visit/confirm`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(403);
  });

  it('returns 200 for valid confirm', async () => {
    const app = createApp(buildPool());
    const res = await request(app)
      .post(`/api/organizations/${orgId}/people/external/${externalId}/foster-onboarding/steps/onboarding_form/confirm`)
      .set('Authorization', `Bearer ${token}`);
    expect(res.statusCode).toBe(200);
    expect(res.body.steps).toHaveLength(9);
  });
});

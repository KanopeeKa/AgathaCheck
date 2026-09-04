import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { assertNonProduction, isProductionEnv } from '../../scripts/db/guard-non-prod.js';
import { DEMO_IDS, DEMO_PASSWORD } from '../scripts/seed.js';
import {
  MAIN_DEMO_USER_KEY,
  buildDemoCredentialsMarkdownTable,
  buildDemoCredentialsTableRows,
} from '../db/seeds/demo-credentials-doc.js';
import { DEMO_USERS } from '../db/seeds/demo-constants.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const PERSONAS_DOC = path.resolve(__dirname, '../../docs/e2e/uat-demo-personas.md');
const UAT_DATA_DOC = path.resolve(__dirname, '../../docs/e2e/uat-demo-data.md');

describe('guard-non-prod', () => {
  const saved = {};

  beforeEach(() => {
    saved.APP_ENV = process.env.APP_ENV;
    saved.NODE_ENV = process.env.NODE_ENV;
  });

  afterEach(() => {
    if (saved.APP_ENV === undefined) delete process.env.APP_ENV;
    else process.env.APP_ENV = saved.APP_ENV;
    if (saved.NODE_ENV === undefined) delete process.env.NODE_ENV;
    else process.env.NODE_ENV = saved.NODE_ENV;
  });

  it('blocks seed operations in production', () => {
    process.env.APP_ENV = 'production';
    expect(isProductionEnv()).toBe(true);
    expect(() => assertNonProduction('database seed')).toThrow(/production/);
  });

  it('allows seed operations in development', () => {
    process.env.APP_ENV = 'development';
    expect(() => assertNonProduction('database seed')).not.toThrow();
  });
});

describe('seed demo constants', () => {
  it('exposes stable demo IDs and password for UAT docs', () => {
    expect(DEMO_IDS.alice).toMatch(
      /^a1000001-0001-4001-8001-000000000001$/
    );
    expect(DEMO_IDS.carol).toMatch(
      /^a1000001-0001-4001-8001-000000000003$/
    );
    expect(DEMO_IDS.rescueHeartsOrg).toMatch(
      /^a2000001-0001-4001-8001-000000000002$/
    );
    expect(DEMO_IDS.partnerPawsOrg).toBe(DEMO_IDS.rescueHeartsOrg);
    expect(DEMO_PASSWORD).toBe('PassTest');
  });

  it('uses Frederique as the main demo login', () => {
    expect(DEMO_USERS[MAIN_DEMO_USER_KEY].email).toBe(
      'frederique.prevost@gmail.com',
    );
    expect(DEMO_USERS[MAIN_DEMO_USER_KEY].first_name).toBe('Frederique');
  });
});

describe('demo credentials documentation', () => {
  const personasDoc = fs.readFileSync(PERSONAS_DOC, 'utf8');
  const uatDataDoc = fs.readFileSync(UAT_DATA_DOC, 'utf8');

  it('keeps uat-demo-personas.md credential table in sync', () => {
    expect(personasDoc).toContain(buildDemoCredentialsMarkdownTable());
  });

  it('documents every demo user email and password in uat-demo-data.md', () => {
    for (const row of buildDemoCredentialsTableRows()) {
      expect(uatDataDoc).toContain(row.email);
      expect(uatDataDoc).toContain(row.password);
    }
  });
});

import { describe, it, expect, beforeEach, afterEach } from '@jest/globals';
import { assertNonProduction, isProductionEnv } from '../../scripts/db/guard-non-prod.js';
import { DEMO_IDS, DEMO_PASSWORD } from '../scripts/seed.js';

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
    expect(DEMO_PASSWORD).toBe('UatDemoPass1!');
  });
});

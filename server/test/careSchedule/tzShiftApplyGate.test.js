import { describe, expect, it } from '@jest/globals';

import {
  assertTzShiftApplyAllowed,
  tzShiftApplyNoWorkRefusalReason,
  tzShiftApplyRefusalReason,
} from '../../lib/care/repair/tzShiftApplyGate.js';

describe('tzShiftApplyGate', () => {
  const prevForce = process.env.TZ_SHIFT_REPAIR_FORCE_APPLY;
  const prevAppEnv = process.env.APP_ENV;

  afterEach(() => {
    if (prevForce === undefined) delete process.env.TZ_SHIFT_REPAIR_FORCE_APPLY;
    else process.env.TZ_SHIFT_REPAIR_FORCE_APPLY = prevForce;
    if (prevAppEnv === undefined) delete process.env.APP_ENV;
    else process.env.APP_ENV = prevAppEnv;
  });

  it('refuses --apply on UAT', () => {
    expect(tzShiftApplyRefusalReason('uat')).toMatch(/DC-1/);
    process.env.APP_ENV = 'uat';
    expect(() => assertTzShiftApplyAllowed([{ deleted: ['a'], reopened: [], flagged: [] }]))
      .toThrow(/UAT/);
  });

  it('allows dry-run-only environments when work exists', () => {
    expect(tzShiftApplyRefusalReason('production')).toBeNull();
  });

  it('refuses --apply when dry-run reports no work (reset / empty DB)', () => {
    expect(tzShiftApplyNoWorkRefusalReason([])).toMatch(/dry-run reports no/);
    expect(tzShiftApplyNoWorkRefusalReason([{ deleted: [], reopened: [], flagged: [] }]))
      .toMatch(/Oct 2026/);
    expect(() => assertTzShiftApplyAllowed([])).toThrow(/no TZ-shift repair work/);
  });

  it('allows apply on production when dry-run has deletions', () => {
    process.env.APP_ENV = 'production';
    expect(() =>
      assertTzShiftApplyAllowed([{ deleted: ['id-1'], reopened: [], flagged: [] }]),
    ).not.toThrow();
  });

  it('honours TZ_SHIFT_REPAIR_FORCE_APPLY for break-glass', () => {
    process.env.TZ_SHIFT_REPAIR_FORCE_APPLY = '1';
    expect(tzShiftApplyRefusalReason('uat')).toBeNull();
    expect(tzShiftApplyNoWorkRefusalReason([])).toBeNull();
  });
});

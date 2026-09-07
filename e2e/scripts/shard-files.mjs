#!/usr/bin/env node
/**
 * File-balanced Playwright shards for Pre-UAT E2E (active Pet Care specs only).
 *
 * Frozen Shelter/Fostering specs are listed in frozen-e2e-specs.mjs and validated
 * via validate-shard-manifest.mjs allowlist — not run in CI shards.
 *
 * Usage:
 *   node e2e/scripts/shard-files.mjs           # print manifest summary
 *   node e2e/scripts/shard-files.mjs 3         # print space-separated paths for shard 3
 */
import { fileURLToPath } from 'node:url';

export const SHARD_TOTAL = 9;

/** @type {string[][]} */
export const SHARDS = [
  ['playwright/tests/health.tracking.spec.ts'],
  [
    'playwright/tests/pet.profiles.spec.ts',
    'playwright/tests/pet.detail-navigation.spec.ts',
    'playwright/tests/pet.timeline.spec.ts',
  ],
  [
    'playwright/tests/guardian.navigation.spec.ts',
    'playwright/tests/guardian.dashboard.spec.ts',
  ],
  ['playwright/tests/experience.navigation.spec.ts'],
  [
    'playwright/tests/auth.login.spec.ts',
    'playwright/tests/auth.signup.spec.ts',
    'playwright/tests/auth.profile.spec.ts',
  ],
  ['playwright/tests/weight.tracking.spec.ts'],
  [
    'playwright/tests/sharing.spec.ts',
    'playwright/tests/account.area.spec.ts',
  ],
  [
    'playwright/tests/notifications.spec.ts',
    'playwright/tests/help.faq.spec.ts',
  ],
  [
    'playwright/tests/gdpr.data-rights.spec.ts',
    'playwright/tests/guardian.onboarding.spec.ts',
    'playwright/tests/veterinarian.spec.ts',
  ],
];

if (SHARDS.length !== SHARD_TOTAL) {
  throw new Error(`shard-files.mjs: expected ${SHARD_TOTAL} shards, got ${SHARDS.length}`);
}

if (process.argv[1] && fileURLToPath(import.meta.url) === fileURLToPath(`file://${process.argv[1]}`)) {
  const shardArg = process.argv[2];
  if (shardArg === undefined || shardArg === '--summary') {
    for (let i = 0; i < SHARDS.length; i++) {
      const files = SHARDS[i];
      console.log(`Shard ${i + 1}/${SHARD_TOTAL}: ${files.join(', ')}`);
    }
  } else {
    const index = Number(shardArg);
    if (!Number.isInteger(index) || index < 1 || index > SHARD_TOTAL) {
      console.error(`usage: shard-files.mjs <1-${SHARD_TOTAL}>`);
      process.exit(1);
    }
    console.log(SHARDS[index - 1].join(' '));
  }
}

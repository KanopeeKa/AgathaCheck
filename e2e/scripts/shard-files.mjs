#!/usr/bin/env node
/**
 * File-balanced Playwright shards for CI (~12 parallel jobs).
 *
 * Playwright --shard splits by test count; slow specs (adoption, health) dominate
 * wall-clock. This manifest isolates the heaviest files and packs the rest by
 * approximate weight (spec line count). Rebalance when adding large spec files.
 *
 * Shard 10 isolates org.onboarding (historically flaky after Nav v2 / theme work).
 * Shard 12 groups org v2 + experience/foster orphans added ci-test-depth-abc9.
 *
 * Usage:
 *   node e2e/scripts/shard-files.mjs           # print manifest summary
 *   node e2e/scripts/shard-files.mjs 3         # print space-separated paths for shard 3
 */
import { fileURLToPath } from 'node:url';

export const SHARD_TOTAL = 12;

/** @type {string[][]} */
export const SHARDS = [
  ['playwright/tests/adoption.spec.ts'],
  ['playwright/tests/health.tracking.spec.ts'],
  [
    'playwright/tests/organisation.management.spec.ts',
    'playwright/tests/gdpr.data-rights.spec.ts',
    'playwright/tests/auth.login.spec.ts',
    'playwright/tests/organisation.discovery.spec.ts',
    'playwright/tests/organisation.permissions.spec.ts',
    'playwright/tests/organisation.customisations.spec.ts',
  ],
  [
    'playwright/tests/weight.tracking.spec.ts',
    'playwright/tests/auth.profile.spec.ts',
  ],
  ['playwright/tests/notifications.spec.ts'],
  [
    'playwright/tests/pet.profiles.spec.ts',
    'playwright/tests/organisation.pet-filters.spec.ts',
  ],
  ['playwright/tests/veterinarian.spec.ts'],
  ['playwright/tests/organisation.pet.management.spec.ts'],
  [
    'playwright/tests/org.timeline.spec.ts',
    'playwright/tests/auth.signup.spec.ts',
  ],
  ['playwright/tests/org.onboarding.spec.ts'],
  [
    'playwright/tests/sharing.spec.ts',
    'playwright/tests/help.faq.spec.ts',
    'playwright/tests/experience.foster-portal.spec.ts',
    'playwright/tests/guardian.onboarding.spec.ts',
  ],
  [
    'playwright/tests/organisation.profile.spec.ts',
    'playwright/tests/organisation.edit.spec.ts',
    'playwright/tests/organisation.sessions.spec.ts',
    'playwright/tests/organisation.redacted-pet.spec.ts',
    'playwright/tests/organisation.admin-contacts.spec.ts',
    'playwright/tests/fostering.platform.spec.ts',
    'playwright/tests/foster.onboarding.spec.ts',
    'playwright/tests/guardian.dashboard.spec.ts',
    'playwright/tests/experience.navigation.spec.ts',
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

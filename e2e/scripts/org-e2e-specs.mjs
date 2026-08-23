#!/usr/bin/env node
/**
 * Organisation journey Playwright specs — full suite for ci-full-audit / pre-uat-e2e / local pre-push.
 * PR CI org coverage: @smoke-ci tests in organisation.discovery/profile/dashboard.spec.ts
 * via ci-e2e-canary (see docs/pipelines/ci-cd-gates.md).
 * Curated from pre-UAT shards 3, 12, and foster onboarding (shard 13).
 *
 * Usage:
 *   node e2e/scripts/org-e2e-specs.mjs           # print space-separated paths
 *   node e2e/scripts/org-e2e-specs.mjs --json    # print JSON array
 */
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const e2eRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

/** Specs that exercise org profile IA, admin contacts, fosters menu, invites, leave. */
export const ORG_JOURNEY_SPECS = [
  'playwright/tests/organisation.management.spec.ts',
  'playwright/tests/organisation.dashboard.spec.ts',
  'playwright/tests/organisation.discovery.spec.ts',
  'playwright/tests/organisation.permissions.spec.ts',
  'playwright/tests/organisation.customisations.spec.ts',
  'playwright/tests/organisation.profile.spec.ts',
  'playwright/tests/organisation.edit.spec.ts',
  'playwright/tests/organisation.sessions.spec.ts',
  'playwright/tests/organisation.redacted-pet.spec.ts',
  'playwright/tests/organisation.admin-contacts.spec.ts',
  'playwright/tests/organisation.connections.spec.ts',
  'playwright/tests/organisation.member.privacy.spec.ts',
  'playwright/tests/foster.onboarding.spec.ts',
];

/** Repo-relative paths that should trigger org Flutter shard on PR. */
export const ORG_E2E_TRIGGER_PATHS = [
  /^flutter_app\/lib\/features\/organization\//,
  /^flutter_app\/test\/features\/organization\//,
  /^flutter_app\/lib\/core\/router\/organization_routes\.dart$/,
  /^flutter_app\/lib\/l10n\/app_en\.arb$/,
  /^flutter_app\/lib\/l10n\/app_fr\.arb$/,
];

/** Repo-relative paths that count as org E2E touch (skip locator-only gate). */
export const ORG_E2E_TOUCH_PATHS = [
  /^e2e\/playwright\/tests\/organisation[^/]*\.spec\.ts$/,
  /^e2e\/playwright\/tests\/foster\.onboarding\.spec\.ts$/,
  /^e2e\/playwright\/pages\/organization[^/]*\.page\.ts$/,
  /^e2e\/playwright\/pages\/manage-fosters\.page\.ts$/,
];

export function isOrgE2eTriggerPath(repoPath) {
  return ORG_E2E_TRIGGER_PATHS.some((re) => re.test(repoPath));
}

export function isOrgE2eTouchPath(repoPath) {
  return ORG_E2E_TOUCH_PATHS.some((re) => re.test(repoPath));
}

export function resolveOrgJourneySpecPaths() {
  return ORG_JOURNEY_SPECS.map((rel) => path.join(e2eRoot, rel));
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (process.argv.includes('--json')) {
    console.log(JSON.stringify(ORG_JOURNEY_SPECS));
  } else {
    console.log(ORG_JOURNEY_SPECS.join(' '));
  }
}

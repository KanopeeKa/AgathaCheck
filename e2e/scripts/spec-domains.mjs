/**
 * Which active Playwright specs exercise which product area — the one map shared by
 * select-affected-specs.mjs (PR E2E), babysit_uat_shard_risk.mjs (merge risk) and humans.
 *
 * Keys are area ids; each area lists the repo path prefixes that belong to it and the spec
 * basenames (e2e/playwright/tests/) that cover it. A path matching no area and no BROAD
 * prefix selects nothing (docs, frozen code, backend internals without a UI journey).
 */

/** Changes here can affect any journey — no targeted selection is meaningful. */
export const BROAD_PREFIXES = [
  'flutter_app/lib/core/',
  'flutter_app/lib/l10n/',
  'flutter_app/lib/main.dart',
  'flutter_app/lib/app.dart',
  'flutter_app/pubspec.yaml',
  'flutter_app/pubspec.lock',
  'flutter_app/web/',
  'e2e/playwright/support/',
  'e2e/playwright/fixtures/',
  'e2e/playwright.config.ts',
  'e2e/package.json',
  'e2e/package-lock.json',
  'server/bin/',
  'server/middleware/',
  'server/config/',
  'db/migrations/',
  'db/schema/',
];

/** @type {Record<string, { paths: string[], specs: string[] }>} */
export const AREAS = {
  health: {
    paths: [
      'flutter_app/lib/features/health_tracking/',
      'flutter_app/lib/features/care_taxonomy/',
      'server/routes/healthEntries',
      'server/routes/healthIssues',
      'server/routes/healthFiles',
      'server/lib/care/',
    ],
    specs: ['health.tracking.spec.ts', 'care.item.absence.spec.ts', 'guardian.dashboard.spec.ts'],
  },
  petCare: {
    paths: ['flutter_app/lib/features/pet_care/', 'server/routes/careContext/'],
    specs: [
      'away.planning.spec.ts',
      'away.plan.detail.v2.spec.ts',
      'away.care.planning.spec.ts',
      'care.item.absence.spec.ts',
      'guardian.dashboard.spec.ts',
    ],
  },
  careIntelligence: {
    paths: ['flutter_app/lib/features/care_intelligence/', 'server/routes/careIntelligence/'],
    specs: ['care-suggestion.spec.ts'],
  },
  petProfile: {
    paths: ['flutter_app/lib/features/pet_profile/', 'flutter_app/lib/features/pet_tags/', 'server/routes/pets', 'server/routes/petTags'],
    specs: ['pet.profiles.spec.ts', 'pet.detail-navigation.spec.ts', 'pet.timeline.spec.ts', 'care-suggestion.spec.ts'],
  },
  experience: {
    paths: ['flutter_app/lib/features/experience/'],
    specs: [
      'guardian.navigation.spec.ts',
      'guardian.dashboard.spec.ts',
      'experience.navigation.spec.ts',
      'guardian.onboarding.spec.ts',
      'account.area.spec.ts',
    ],
  },
  auth: {
    paths: ['flutter_app/lib/features/auth/', 'server/routes/auth'],
    specs: [
      'auth.login.spec.ts',
      'auth.signup.spec.ts',
      'auth.profile.spec.ts',
      'account.area.spec.ts',
      'gdpr.data-rights.spec.ts',
    ],
  },
  sharing: {
    paths: ['flutter_app/lib/features/sharing/', 'server/routes/sharing'],
    specs: ['sharing.spec.ts'],
  },
  notifications: {
    paths: ['flutter_app/lib/features/notifications/', 'server/routes/notifications'],
    specs: ['notifications.spec.ts'],
  },
  weight: {
    paths: ['flutter_app/lib/features/weight_tracking/', 'server/routes/weightEntries'],
    specs: ['weight.tracking.spec.ts'],
  },
  people: {
    paths: [
      'flutter_app/lib/features/people/',
      'flutter_app/lib/features/vet/',
      'server/routes/people/',
      'server/routes/households/',
      'server/routes/vets',
      'server/lib/people/',
    ],
    specs: ['people-hub.spec.ts', 'veterinarian.spec.ts'],
  },
  help: {
    paths: ['flutter_app/lib/features/help/', 'flutter_app/lib/features/about/'],
    specs: ['help.faq.spec.ts'],
  },
};

export function isBroadPath(repoPath) {
  return BROAD_PREFIXES.some((prefix) => repoPath === prefix || repoPath.startsWith(prefix));
}

/** Area ids whose path prefixes match `repoPath`. */
export function areasForPath(repoPath) {
  return Object.entries(AREAS)
    .filter(([, area]) => area.paths.some((prefix) => repoPath.startsWith(prefix)))
    .map(([id]) => id);
}

/** Every spec basename named in AREAS (for manifest validation). */
export function mappedSpecs() {
  return new Set(Object.values(AREAS).flatMap((area) => area.specs));
}

/**
 * Canonical CI governance gate registry.
 * Consumed by assert-ci-gate tests, prepush parity, and docs/agent-efficiency/governance-gates.md.
 *
 * @typedef {'flutter' | 'governance' | 'docs-strict' | 'full-only' | 'exempt'} PrepushScope
 */

/** @type {Array<{
 *   id: string,
 *   command: string,
 *   cheap?: boolean,
 *   prepush: PrepushScope,
 *   exemptReason?: string,
 *   blocking?: boolean,
 *   ci?: { workflow: string, jobId: string, runIncludes: string[], runExcludes?: string[] },
 *   fixture?: string,
 * }>} */
export const GOVERNANCE_GATE_REGISTRY = [
  {
    id: 'docs-validation',
    command: 'bash scripts/validate_docs.sh --strict',
    cheap: true,
    prepush: 'docs-strict',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['validate_docs.sh --strict'],
    },
    fixture: 'node --test scripts/validate_docs.fixture.test.mjs',
  },
  {
    id: 'dart-format',
    command:
      'dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test',
    cheap: true,
    prepush: 'flutter',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-flutter-analyze.yml',
      jobId: 'analyze',
      runIncludes: ['dart format'],
    },
  },
  {
    id: 'bdd-priority-tags',
    command: 'node scripts/check_bdd_priority_tags.js',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['check_bdd_priority_tags.js'],
    },
  },
  {
    id: 'frozen-boundaries',
    command: 'bash scripts/check_frozen_domain_boundaries.sh',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['check_frozen_domain_boundaries.sh'],
    },
    fixture: 'bash scripts/test/check_frozen_domain_boundaries.test.sh',
  },
  {
    id: 'feature-imports',
    command: 'node scripts/check_feature_imports.js',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['node scripts/check_feature_imports.js'],
    },
    fixture: 'node --test scripts/check_feature_imports.test.js',
  },
  {
    id: 'file-size',
    command: 'node scripts/check_file_size.js',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['node scripts/check_file_size.js'],
    },
    fixture: 'node --test scripts/check_file_size.test.js',
  },
  {
    id: 'web-bundle-budget',
    command: 'node scripts/ci/check-web-bundle-budget.mjs',
    cheap: false,
    prepush: 'exempt',
    exemptReason: 'needs release web build artifact',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-build-web.yml',
      jobId: 'build-web',
      runIncludes: ['check-web-bundle-budget.mjs'],
    },
  },
  {
    id: 'eslint',
    command: 'node scripts/validate_eslint.js',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'lint',
      runIncludes: ['node scripts/validate_eslint.js'],
      runExcludes: ['validate_eslint.test.js'],
    },
    fixture: 'node --test scripts/validate_eslint.test.js',
  },
  {
    id: 'bdd-coverage',
    command: 'node e2e/scripts/check_bdd_coverage.js',
    cheap: true,
    prepush: 'governance',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['node e2e/scripts/check_bdd_coverage.js'],
      runExcludes: ['check_bdd_coverage.test.js', '--report-only'],
    },
    fixture: 'node --test e2e/scripts/check_bdd_coverage.test.js',
  },
  {
    id: 'flutter-domain-coverage',
    command: 'bash flutter_app/scripts/merge_flutter_coverage.sh',
    cheap: false,
    prepush: 'full-only',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-flutter-coverage.yml',
      jobId: 'coverage',
      runIncludes: ['merge_flutter_coverage.sh'],
    },
    fixture:
      'cd flutter_app && node --test scripts/test/domain_coverage.fixture.mjs && node --test ../scripts/check_coverage_threshold_consistency.test.js',
  },
  {
    id: 'backend-coverage-ratchet',
    command: 'node server/scripts/check_coverage_ratchet.js',
    cheap: false,
    prepush: 'full-only',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'backend',
      runIncludes: ['check_coverage_ratchet.js'],
    },
    fixture: 'cd server && node --test scripts/test/check_coverage_ratchet.fixture.mjs',
  },
  {
    id: 'architecture-tests',
    command: 'npx jest test/architecture --forceExit',
    cheap: false,
    prepush: 'full-only',
    blocking: true,
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'backend',
      runIncludes: ['test/architecture'],
    },
    fixture: 'node --test scripts/test/architecture-checkers.fixture.test.mjs',
  },
];

/** @deprecated name kept for importers — blocking CI gates with fixture contracts. */
export const BLOCKING_GOVERNANCE_STEPS = GOVERNANCE_GATE_REGISTRY.filter(
  (g) => g.blocking && g.fixture,
);

/** Cheap gates listed in CI workflows used for prepush parity accounting. */
export const CHEAP_CI_WORKFLOWS = [
  '.github/workflows/_reusable-test.yml',
  '.github/workflows/_reusable-flutter-analyze.yml',
];

/** Jobs that must succeed for the umbrella ci-gate when scope is FULL. */
export const CI_GATE_REQUIRED_CALLERS = [
  'startup-smoke',
  'test-suite',
  'flutter-analyze',
  'flutter-prep',
  'flutter-test',
  'flutter-coverage',
  'flutter-integration',
  'flutter-build-web',
  'ci-e2e-canary',
  'ci-e2e-affected',
];

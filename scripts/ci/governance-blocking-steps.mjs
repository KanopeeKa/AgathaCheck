/**
 * Canonical blocking governance gates for Batch J phase 4.
 * Consumed by assert-ci-gate.test.js and docs/agent-efficiency/governance-gates.md.
 */
export const BLOCKING_GOVERNANCE_STEPS = [
  {
    id: 'docs-validation',
    command: 'bash scripts/validate_docs.sh --strict',
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['validate_docs.sh --strict'],
    },
    fixture: 'node --test scripts/validate_docs.fixture.test.mjs',
  },
  {
    id: 'frozen-boundaries',
    command: 'bash scripts/check_frozen_domain_boundaries.sh',
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
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'governance',
      runIncludes: ['node scripts/check_file_size.js'],
    },
    fixture: 'node --test scripts/check_file_size.test.js',
  },
  {
    id: 'eslint',
    command: 'node scripts/validate_eslint.js',
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
    ci: {
      workflow: '.github/workflows/_reusable-test.yml',
      jobId: 'backend',
      runIncludes: ['test/architecture'],
    },
    fixture: 'node --test scripts/test/architecture-checkers.fixture.test.mjs',
  },
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

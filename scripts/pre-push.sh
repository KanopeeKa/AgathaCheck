#!/usr/bin/env bash
# Full pre-push verification — run before integration→main PR or single-agent merge.
# Single source of truth; docs/rules point here instead of duplicating commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
source "$ROOT/scripts/flutter-sdk.sh"
agatha_flutter_use
agatha_flutter_verify

echo "==> Governance gates"
node scripts/check_file_size.js
node scripts/check_hardcoded_shell_return_to.js
bash scripts/check_frozen_domain_boundaries.sh
node scripts/check_feature_imports.js
node --test scripts/check_feature_imports.test.js
node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.snapshot.json
node scripts/validate_execute_plan_snapshot.js --drift-test
node --test scripts/execute_plan_runtime.test.js
node --test scripts/uat_queue_runtime.test.js
node --test scripts/babysit_merge_preflight.test.js
node --test scripts/uat_coordinator_payload.test.js
node --test scripts/ci/evaluate-uat-promote-hold.test.js
node --test scripts/ci/resolve-promote-commit-sha.test.js
node --test scripts/ci/assert-ci-gate.test.js
node --test scripts/ci/ci-scope.test.js
node --test e2e/scripts/select-affected-specs.test.mjs
node --test scripts/babysit_uat_shard_risk.test.mjs
node --test scripts/quality/generate-scorecard-metrics.test.mjs
node scripts/quality/generate-scorecard-metrics.mjs --write-scorecard
node scripts/quality/generate-scorecard-metrics.mjs --check
node scripts/ci/flutter-shards.mjs check
node --test scripts/ci/flutter-shards.test.mjs scripts/ci/flutter-shard-runner.test.mjs
node scripts/check_skill_frontmatter.js
node --test scripts/github_issue_workflow.test.js
node --test scripts/db/normalize-schema-dump.test.js
node scripts/db/check-migration-manifest.js
node scripts/check_occurrence_writes.js
node e2e/scripts/check_bdd_coverage.js
node scripts/check_bdd_priority_tags.js
bash scripts/ci/check-uat-ssh-action-pin.sh
bash scripts/ci/shellcheck-uat-deploy-scripts.sh
bash scripts/ci/assert-prod-deploy-db-commands.sh

echo "==> Server (audit + Jest)"
(
  cd server
  npm audit --audit-level=high
  npm test -- --forceExit
)

echo "==> Flutter (codegen + analyze + active CI shards)"
(
  cd flutter_app
  dart run build_runner build --delete-conflicting-outputs
  flutter analyze --no-fatal-warnings --no-fatal-infos
  mapfile -t shards < <(node ../scripts/ci/flutter-shards.mjs list)
  for shard in "${shards[@]}"; do
    bash scripts/run_tests_ci_shard.sh "$shard"
  done
)

echo "==> Format check"
dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test

echo "✓ Full pre-push passed"

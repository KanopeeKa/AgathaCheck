#!/usr/bin/env bash
# Full pre-push verification — run before integration→main PR or single-agent merge.
# Single source of truth; docs/rules point here instead of duplicating commands.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Governance gates"
node scripts/check_file_size.js
node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.snapshot.json
node scripts/validate_execute_plan_snapshot.js --drift-test
node --test scripts/execute_plan_runtime.test.js
node --test scripts/uat_queue_runtime.test.js
node --test scripts/uat_coordinator_payload.test.js
node --test scripts/ci/evaluate-uat-promote-hold.test.js
node --test scripts/ci/evaluate-uat-promote-cadence.test.js
node scripts/check_skill_frontmatter.js
node --test scripts/github_issue_workflow.test.js
node --test scripts/db/normalize-schema-dump.test.js
node scripts/db/check-migration-manifest.js
node e2e/scripts/check_bdd_coverage.js
node scripts/check_bdd_priority_tags.js
bash scripts/ci/check-uat-ssh-action-pin.sh
bash scripts/ci/shellcheck-uat-deploy-scripts.sh
bash scripts/ci/assert-prod-deploy-db-commands.sh

echo "==> Server (audit + Jest)"
(
  cd server
  npm audit --audit-level=high
  npx jest --env=node --forceExit
)

echo "==> Flutter (codegen + analyze + test)"
(
  cd flutter_app
  dart run build_runner build --delete-conflicting-outputs
  flutter analyze --no-fatal-warnings --no-fatal-infos
  flutter test --concurrency=1 --exclude-tags=integration
)

echo "==> Format check"
dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test

echo "✓ Full pre-push passed"

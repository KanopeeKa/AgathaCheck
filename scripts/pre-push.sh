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
node e2e/scripts/check_bdd_coverage.js
node scripts/check_bdd_priority_tags.js
bash scripts/ci/check-uat-ssh-action-pin.sh
bash scripts/ci/shellcheck-uat-deploy-scripts.sh

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

echo "==> Dart server analyze"
(
  cd server
  dart pub get
  dart analyze lib
)

echo "==> Format check"
dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test server/lib

echo "✓ Full pre-push passed"

#!/usr/bin/env bash
# Shared path-scope rules for pre-push-changed.sh and resolve-ci-scope.sh.
# Source this file; do not execute directly.
set -euo pipefail

# Classification flags (reset via ci_scope_reset).
CI_SCOPE_FORCE_FULL=false
CI_SCOPE_ESCAPE_FULL=false
CI_SCOPE_HAS_FLUTTER=false
CI_SCOPE_HAS_SERVER_ROUTES=false
CI_SCOPE_HAS_SERVER_LIB=false
CI_SCOPE_HAS_SERVER_TEST=false
CI_SCOPE_HAS_SERVER_SCRIPTS=false
CI_SCOPE_HAS_SERVER_CONFIG=false
CI_SCOPE_HAS_E2E=false
CI_SCOPE_HAS_WORKFLOWS=false
CI_SCOPE_HAS_SCRIPTS_CI=false
CI_SCOPE_ONLY_DOCS=true
CI_SCOPE_HAS_PET_PROFILE=false
CI_SCOPE_SERVER_LOCK_CHANGED=false
CI_SCOPE_E2E_LOCK_CHANGED=false

# Flutter CI shards live in flutter_app/test/ci_shards.json (scripts/ci/flutter-shards.mjs).
# When the Flutter stack runs, every shard runs (batched shards make a full run ~ one shard
# of wall-clock; it keeps the domain coverage gate and cross-domain tests on every Flutter PR).

ci_scope_reset() {
  CI_SCOPE_FORCE_FULL=false
  CI_SCOPE_ESCAPE_FULL=false
  CI_SCOPE_HAS_FLUTTER=false
  CI_SCOPE_HAS_SERVER_ROUTES=false
  CI_SCOPE_HAS_SERVER_LIB=false
  CI_SCOPE_HAS_SERVER_TEST=false
  CI_SCOPE_HAS_SERVER_SCRIPTS=false
  CI_SCOPE_HAS_SERVER_CONFIG=false
  CI_SCOPE_HAS_E2E=false
  CI_SCOPE_HAS_WORKFLOWS=false
  CI_SCOPE_HAS_SCRIPTS_CI=false
  CI_SCOPE_ONLY_DOCS=true
  CI_SCOPE_HAS_PET_PROFILE=false
  CI_SCOPE_SERVER_LOCK_CHANGED=false
  CI_SCOPE_E2E_LOCK_CHANGED=false
}

ci_scope_is_doc_path() {
  local f="$1"
  [[ "$f" == docs/* ]] \
    || [[ "$f" == .agents/* ]] \
    || [[ "$f" == .cursor/* ]] \
    || [[ "$f" == replit.md ]] \
    || [[ "$f" == CONTRIBUTING.md ]] \
    || [[ "$f" == DEPLOYMENT* ]] \
    || [[ "$f" == .github/pull_request_template.md ]]
}

ci_scope_classify_path() {
  local f="$1"
  [[ -z "$f" ]] && return 0

  if ! ci_scope_is_doc_path "$f"; then
    CI_SCOPE_ONLY_DOCS=false
  fi

  case "$f" in
    db/migrations/*|db/schema/*)
      CI_SCOPE_FORCE_FULL=true
      ;;
    server/config/security.js|server/config/jwtSecret.js|server/config/*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_SERVER_CONFIG=true
      ;;
    server/routes/*)
      CI_SCOPE_HAS_SERVER_ROUTES=true
      ;;
    server/lib/*)
      CI_SCOPE_HAS_SERVER_LIB=true
      ;;
    server/test/*)
      CI_SCOPE_HAS_SERVER_TEST=true
      ;;
    server/scripts/*)
      CI_SCOPE_HAS_SERVER_SCRIPTS=true
      ;;
    server/*)
      CI_SCOPE_HAS_SERVER_TEST=true
      ;;
    flutter_app/lib/features/organization/*|flutter_app/test/features/organization/* \
      |flutter_app/lib/features/fostering_session/*|flutter_app/test/features/fostering_session/*)
      # Frozen domain roots — governance + boundary script only
      ;;
    flutter_app/lib/core/*|flutter_app/lib/l10n/*|flutter_app/pubspec.*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/features/pet_profile/*|flutter_app/test/features/pet_profile/*)
      CI_SCOPE_HAS_PET_PROFILE=true
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/features/*|flutter_app/test/features/*)
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/*|flutter_app/test/*)
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    e2e/playwright/tests/organisation*.spec.ts|e2e/playwright/tests/foster*.spec.ts|e2e/playwright/tests/adoption.spec.ts|e2e/playwright/tests/experience.foster-portal.spec.ts|e2e/playwright/tests/fostering*.spec.ts|e2e/playwright/tests/org.*.spec.ts)
      # Frozen Playwright specs — governance only
      ;;
    e2e/*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_E2E=true
      ;;
    .github/workflows/*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_WORKFLOWS=true
      ;;
    scripts/ci/*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_SCRIPTS_CI=true
      ;;
    scripts/validate_eslint*)
      # ESLint ratchet inputs (F-20) — must keep run_backend=true so the lint job runs
      CI_SCOPE_HAS_SERVER_SCRIPTS=true
      ;;
    server/package-lock.json)
      CI_SCOPE_SERVER_LOCK_CHANGED=true
      CI_SCOPE_FORCE_FULL=true
      ;;
    e2e/package-lock.json)
      CI_SCOPE_E2E_LOCK_CHANGED=true
      CI_SCOPE_FORCE_FULL=true
      ;;
  esac
}

ci_scope_classify_paths() {
  local paths="$1"
  ci_scope_reset
  while IFS= read -r f; do
    ci_scope_classify_path "$f"
  done <<<"$paths"
}

ci_scope_server_touch() {
  [[ "$CI_SCOPE_HAS_SERVER_ROUTES" == true \
    || "$CI_SCOPE_HAS_SERVER_LIB" == true \
    || "$CI_SCOPE_HAS_SERVER_TEST" == true \
    || "$CI_SCOPE_HAS_SERVER_SCRIPTS" == true \
    || "$CI_SCOPE_HAS_SERVER_CONFIG" == true ]]
}

ci_scope_resolve_name() {
  if [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]]; then
    echo "FULL"
    return
  fi
  if ci_scope_server_touch && [[ "$CI_SCOPE_HAS_FLUTTER" != true ]]; then
    echo "SERVER_ONLY"
    return
  fi
  if [[ "$CI_SCOPE_HAS_FLUTTER" == true ]] && ! ci_scope_server_touch; then
    echo "FLUTTER_ONLY"
    return
  fi
  if [[ "$CI_SCOPE_ONLY_DOCS" == true ]]; then
    echo "DOCS_ONLY"
    return
  fi
  if [[ "$CI_SCOPE_HAS_FLUTTER" != true ]] && ! ci_scope_server_touch && [[ "$CI_SCOPE_HAS_E2E" != true ]]; then
    echo "SCRIPTS_INFRA"
    return
  fi
  if ci_scope_server_touch && [[ "$CI_SCOPE_HAS_FLUTTER" == true ]]; then
    echo "CROSS_STACK"
    return
  fi
  echo "OTHER"
}

# Job flags for CI (true = run, false = skip).
ci_scope_run_flutter_analyze() {
  [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]] && return 0
  [[ "$CI_SCOPE_HAS_FLUTTER" == true ]] && return 0
  [[ "$CI_SCOPE_HAS_SERVER_ROUTES" == true || "$CI_SCOPE_HAS_SERVER_LIB" == true ]] && return 0
  [[ "$CI_SCOPE_HAS_E2E" == true ]] && return 0
  return 1
}

ci_scope_run_flutter_stack() {
  [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]] && return 0
  [[ "$CI_SCOPE_HAS_FLUTTER" == true || "$CI_SCOPE_HAS_E2E" == true ]] && return 0
  return 1
}

ci_scope_run_backend() {
  [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]] && return 0
  ci_scope_server_touch && return 0
  return 1
}

ci_scope_run_e2e_audit() {
  [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]] && return 0
  [[ "$CI_SCOPE_E2E_LOCK_CHANGED" == true ]] && return 0
  return 1
}

ci_scope_run_integration() {
  ci_scope_run_flutter_stack || return 1
  [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]] && return 0
  [[ "$CI_SCOPE_HAS_PET_PROFILE" == true ]] && return 0
  return 1
}

# Frozen Shelter/Fostering domains are excluded from active PR CI shards.

ci_scope_bool() {
  if "$1"; then
    echo "true"
  else
    echo "false"
  fi
}

ci_scope_all_shards_json() {
  local lib_dir
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  node "$lib_dir/flutter-shards.mjs" list --json
}

ci_scope_emit_json() {
  local scope
  scope="$(ci_scope_resolve_name)"
  local run_analyze run_stack run_backend run_e2e_audit run_integration all_shards
  run_analyze="$(ci_scope_bool ci_scope_run_flutter_analyze)"
  run_stack="$(ci_scope_bool ci_scope_run_flutter_stack)"
  run_backend="$(ci_scope_bool ci_scope_run_backend)"
  run_e2e_audit="$(ci_scope_bool ci_scope_run_e2e_audit)"
  run_integration="$(ci_scope_bool ci_scope_run_integration)"
  all_shards="$(ci_scope_all_shards_json)"

  python3 - "$scope" "$CI_SCOPE_FORCE_FULL" "$CI_SCOPE_ESCAPE_FULL" "$run_analyze" "$run_stack" "$run_backend" "$run_e2e_audit" "$run_integration" \
    "$all_shards" <<'PY'
import json, sys

(
    scope,
    force_full,
    escape_full,
    run_analyze,
    run_stack,
    run_backend,
    run_e2e_audit,
    run_integration,
    all_shards,
) = sys.argv[1:10]

def b(v):
    return v == "true"

run_analyze = b(run_analyze)
run_stack = b(run_stack)
run_backend = b(run_backend)
run_e2e_audit = b(run_e2e_audit)
run_integration = b(run_integration)

# Every shard in flutter_app/test/ci_shards.json runs whenever the Flutter stack runs.
run_shards = json.loads(all_shards) if run_stack else []

skip_jobs = []
if not run_analyze:
    skip_jobs.append("flutter-analyze")
if not run_stack:
    skip_jobs.extend(["flutter-test", "flutter-coverage", "flutter-build-web", "ci-e2e-canary"])
if not run_integration:
    skip_jobs.append("flutter-integration")

print(
    json.dumps(
        {
            "scope": scope,
            "force_full": force_full == "true",
            "escape_full": escape_full == "true",
            "run_flutter_analyze": run_analyze,
            "run_flutter_stack": run_stack,
            "run_flutter_coverage": run_stack,
            "run_backend": run_backend,
            "run_e2e_audit": run_e2e_audit,
            "run_flutter_integration": run_integration,
            "run_shards": run_shards,
            "skip_jobs": skip_jobs,
        },
        separators=(",", ":"),
    )
)
PY
}

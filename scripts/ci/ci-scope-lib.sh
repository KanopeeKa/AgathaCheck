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
    flutter_app/lib/core/*|flutter_app/lib/l10n/*|flutter_app/pubspec.*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/features/pet_profile/*|flutter_app/test/features/pet_profile/*)
      CI_SCOPE_HAS_PET_PROFILE=true
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/*|flutter_app/test/*)
      CI_SCOPE_HAS_FLUTTER=true
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

ci_scope_bool() {
  if "$1"; then
    echo "true"
  else
    echo "false"
  fi
}

ci_scope_emit_json() {
  local scope
  scope="$(ci_scope_resolve_name)"
  local run_analyze run_stack run_backend run_e2e_audit run_integration
  run_analyze="$(ci_scope_bool ci_scope_run_flutter_analyze)"
  run_stack="$(ci_scope_bool ci_scope_run_flutter_stack)"
  run_backend="$(ci_scope_bool ci_scope_run_backend)"
  run_e2e_audit="$(ci_scope_bool ci_scope_run_e2e_audit)"
  run_integration="$(ci_scope_bool ci_scope_run_integration)"

  python3 - "$scope" "$CI_SCOPE_FORCE_FULL" "$CI_SCOPE_ESCAPE_FULL" "$run_analyze" "$run_stack" "$run_backend" "$run_e2e_audit" "$run_integration" <<'PY'
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
) = sys.argv[1:9]
run_analyze = run_analyze == "true"
run_stack = run_stack == "true"
run_backend = run_backend == "true"
run_e2e_audit = run_e2e_audit == "true"
run_integration = run_integration == "true"

skip_jobs = []
if not run_analyze:
    skip_jobs.append("flutter-analyze")
if not run_stack:
    skip_jobs.extend(
        [
            "flutter-test-pet-core",
            "flutter-test-pet-screens",
            "flutter-test-pet-widgets",
            "flutter-test-health",
            "flutter-test-org",
            "flutter-test-rest-a",
            "flutter-test-rest-b",
            "flutter-coverage",
            "flutter-build-web",
            "ci-e2e-canary",
        ]
    )
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
            "run_backend": run_backend,
            "run_e2e_audit": run_e2e_audit,
            "run_flutter_integration": run_integration,
            "skip_jobs": skip_jobs,
        },
        separators=(",", ":"),
    )
)
PY
}

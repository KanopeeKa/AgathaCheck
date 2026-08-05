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

# Per-domain Flutter CI shards (see flutter_app/scripts/run_tests_ci_shard.sh).
CI_SCOPE_SHARD_PET_CORE=false
CI_SCOPE_SHARD_PET_SCREENS=false
CI_SCOPE_SHARD_PET_WIDGETS=false
CI_SCOPE_SHARD_HEALTH=false
CI_SCOPE_SHARD_ORG=false
CI_SCOPE_SHARD_REST_A=false
CI_SCOPE_SHARD_REST_B=false
CI_SCOPE_HAS_ORG_E2E_TOUCH=false
CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER=false

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
  CI_SCOPE_SHARD_PET_CORE=false
  CI_SCOPE_SHARD_PET_SCREENS=false
  CI_SCOPE_SHARD_PET_WIDGETS=false
  CI_SCOPE_SHARD_HEALTH=false
  CI_SCOPE_SHARD_ORG=false
  CI_SCOPE_SHARD_REST_A=false
  CI_SCOPE_SHARD_REST_B=false
  CI_SCOPE_HAS_ORG_E2E_TOUCH=false
  CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER=false
}

ci_scope_enable_shard() {
  case "$1" in
    pet-core) CI_SCOPE_SHARD_PET_CORE=true ;;
    pet-screens) CI_SCOPE_SHARD_PET_SCREENS=true ;;
    pet-widgets) CI_SCOPE_SHARD_PET_WIDGETS=true ;;
    health) CI_SCOPE_SHARD_HEALTH=true ;;
    org) CI_SCOPE_SHARD_ORG=true ;;
    rest-a) CI_SCOPE_SHARD_REST_A=true ;;
    rest-b) CI_SCOPE_SHARD_REST_B=true ;;
    *) ;;
  esac
}

ci_scope_enable_all_shards() {
  CI_SCOPE_SHARD_PET_CORE=true
  CI_SCOPE_SHARD_PET_SCREENS=true
  CI_SCOPE_SHARD_PET_WIDGETS=true
  CI_SCOPE_SHARD_HEALTH=true
  CI_SCOPE_SHARD_ORG=true
  CI_SCOPE_SHARD_REST_A=true
  CI_SCOPE_SHARD_REST_B=true
}

ci_scope_any_shard_enabled() {
  [[ "$CI_SCOPE_SHARD_PET_CORE" == true \
    || "$CI_SCOPE_SHARD_PET_SCREENS" == true \
    || "$CI_SCOPE_SHARD_PET_WIDGETS" == true \
    || "$CI_SCOPE_SHARD_HEALTH" == true \
    || "$CI_SCOPE_SHARD_ORG" == true \
    || "$CI_SCOPE_SHARD_REST_A" == true \
    || "$CI_SCOPE_SHARD_REST_B" == true ]]
}

ci_scope_finalize_flutter_shards() {
  if [[ "$CI_SCOPE_FORCE_FULL" == true || "$CI_SCOPE_ESCAPE_FULL" == true ]]; then
    ci_scope_enable_all_shards
    return
  fi
  if [[ "$CI_SCOPE_HAS_FLUTTER" != true ]]; then
    return
  fi
  if ! ci_scope_any_shard_enabled; then
    ci_scope_enable_all_shards
  fi
}

ci_scope_classify_flutter_shard() {
  local f="$1"
  case "$f" in
    flutter_app/lib/features/pet_profile/data/*|flutter_app/lib/features/pet_profile/domain/* \
      |flutter_app/test/features/pet_profile/data/*|flutter_app/test/features/pet_profile/domain/*)
      ci_scope_enable_shard pet-core
      ;;
    flutter_app/lib/features/pet_profile/presentation/screens/* \
      |flutter_app/test/features/pet_profile/presentation/screens/*)
      ci_scope_enable_shard pet-screens
      ;;
    flutter_app/lib/features/pet_profile/presentation/widgets/* \
      |flutter_app/lib/features/pet_profile/presentation/controllers/* \
      |flutter_app/lib/features/pet_profile/presentation/providers/* \
      |flutter_app/lib/features/pet_profile/presentation/utils/* \
      |flutter_app/test/features/pet_profile/presentation/widgets/* \
      |flutter_app/test/features/pet_profile/presentation/controllers/* \
      |flutter_app/test/features/pet_profile/presentation/providers/* \
      |flutter_app/test/features/pet_profile/presentation/utils/*)
      ci_scope_enable_shard pet-widgets
      ;;
    flutter_app/lib/features/pet_profile/*|flutter_app/test/features/pet_profile/*)
      ci_scope_enable_shard pet-core
      ci_scope_enable_shard pet-screens
      ci_scope_enable_shard pet-widgets
      ;;
    flutter_app/lib/features/health_tracking/*|flutter_app/test/features/health_tracking/*)
      ci_scope_enable_shard health
      ;;
    flutter_app/lib/features/organization/*|flutter_app/test/features/organization/*)
      CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER=true
      ci_scope_enable_shard org
      ;;
    flutter_app/lib/core/router/organization_routes.dart)
      ci_scope_enable_shard org
      ;;
    flutter_app/lib/features/auth/*|flutter_app/lib/features/sharing/* \
      |flutter_app/lib/features/notifications/*|flutter_app/lib/features/subscription/* \
      |flutter_app/test/features/auth/*|flutter_app/test/features/sharing/* \
      |flutter_app/test/features/notifications/*|flutter_app/test/features/subscription/*)
      ci_scope_enable_shard rest-a
      ;;
    flutter_app/lib/features/experience/*|flutter_app/lib/features/vet/* \
      |flutter_app/lib/features/weight_tracking/*|flutter_app/lib/features/help/* \
      |flutter_app/lib/features/about/* \
      |flutter_app/test/features/experience/*|flutter_app/test/features/vet/* \
      |flutter_app/test/features/weight_tracking/*|flutter_app/test/features/help/* \
      |flutter_app/test/features/about/* \
      |flutter_app/test/features/api_base_url_wiring_test.dart)
      ci_scope_enable_shard rest-b
      ;;
    flutter_app/lib/*|flutter_app/test/*)
      ci_scope_enable_all_shards
      ;;
  esac
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
    flutter_app/lib/core/router/organization_routes.dart)
      CI_SCOPE_HAS_FLUTTER=true
      CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER=true
      ci_scope_enable_shard org
      ;;
    flutter_app/lib/core/*|flutter_app/lib/l10n/*|flutter_app/pubspec.*)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_FLUTTER=true
      ;;
    flutter_app/lib/features/pet_profile/*|flutter_app/test/features/pet_profile/*)
      CI_SCOPE_HAS_PET_PROFILE=true
      CI_SCOPE_HAS_FLUTTER=true
      ci_scope_classify_flutter_shard "$f"
      ;;
    flutter_app/lib/features/*|flutter_app/test/features/*)
      CI_SCOPE_HAS_FLUTTER=true
      ci_scope_classify_flutter_shard "$f"
      ;;
    flutter_app/lib/*|flutter_app/test/*)
      CI_SCOPE_HAS_FLUTTER=true
      ci_scope_classify_flutter_shard "$f"
      ;;
    e2e/playwright/tests/organisation*.spec.ts|e2e/playwright/tests/foster.onboarding.spec.ts|e2e/playwright/pages/organization*.page.ts|e2e/playwright/pages/manage-fosters.page.ts)
      CI_SCOPE_FORCE_FULL=true
      CI_SCOPE_HAS_E2E=true
      CI_SCOPE_HAS_ORG_E2E_TOUCH=true
      CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER=true
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
  ci_scope_finalize_flutter_shards
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

# Organisation journey Playwright — when org Flutter or org E2E paths change on a PR.
ci_scope_run_org_e2e() {
  ci_scope_run_flutter_stack || return 1
  [[ "$CI_SCOPE_HAS_ORG_JOURNEY_TRIGGER" == true || "$CI_SCOPE_HAS_ORG_E2E_TOUCH" == true ]] && return 0
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
  local run_analyze run_stack run_backend run_e2e_audit run_integration run_org_e2e
  run_analyze="$(ci_scope_bool ci_scope_run_flutter_analyze)"
  run_stack="$(ci_scope_bool ci_scope_run_flutter_stack)"
  run_backend="$(ci_scope_bool ci_scope_run_backend)"
  run_e2e_audit="$(ci_scope_bool ci_scope_run_e2e_audit)"
  run_integration="$(ci_scope_bool ci_scope_run_integration)"
  run_org_e2e="$(ci_scope_bool ci_scope_run_org_e2e)"

  python3 - "$scope" "$CI_SCOPE_FORCE_FULL" "$CI_SCOPE_ESCAPE_FULL" "$run_analyze" "$run_stack" "$run_backend" "$run_e2e_audit" "$run_integration" "$run_org_e2e" \
    "$CI_SCOPE_SHARD_PET_CORE" "$CI_SCOPE_SHARD_PET_SCREENS" "$CI_SCOPE_SHARD_PET_WIDGETS" \
    "$CI_SCOPE_SHARD_HEALTH" "$CI_SCOPE_SHARD_ORG" "$CI_SCOPE_SHARD_REST_A" "$CI_SCOPE_SHARD_REST_B" <<'PY'
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
    run_org_e2e,
    shard_pet_core,
    shard_pet_screens,
    shard_pet_widgets,
    shard_health,
    shard_org,
    shard_rest_a,
    shard_rest_b,
) = sys.argv[1:17]

def b(v):
    return v == "true"

run_analyze = b(run_analyze)
run_stack = b(run_stack)
run_backend = b(run_backend)
run_e2e_audit = b(run_e2e_audit)
run_integration = b(run_integration)
run_org_e2e = b(run_org_e2e)

shard_map = {
    "pet-core": b(shard_pet_core),
    "pet-screens": b(shard_pet_screens),
    "pet-widgets": b(shard_pet_widgets),
    "health": b(shard_health),
    "org": b(shard_org),
    "rest-a": b(shard_rest_a),
    "rest-b": b(shard_rest_b),
}

job_ids = {
    "pet-core": "flutter-test-pet-core",
    "pet-screens": "flutter-test-pet-screens",
    "pet-widgets": "flutter-test-pet-widgets",
    "health": "flutter-test-health",
    "org": "flutter-test-org",
    "rest-a": "flutter-test-rest-a",
    "rest-b": "flutter-test-rest-b",
}

run_shards = [name for name, enabled in shard_map.items() if enabled]

skip_jobs = []
if not run_analyze:
    skip_jobs.append("flutter-analyze")
if not run_stack:
    skip_jobs.extend(
        [
            *job_ids.values(),
            "flutter-coverage",
            "flutter-build-web",
            "ci-e2e-canary",
        ]
    )
else:
    for name, job_id in job_ids.items():
        if not shard_map[name]:
            skip_jobs.append(job_id)
    if len(run_shards) < len(shard_map):
        skip_jobs.append("flutter-coverage")
if not run_integration:
    skip_jobs.append("flutter-integration")
if not run_org_e2e:
    skip_jobs.append("ci-e2e-org")

run_flutter_coverage = run_stack and len(run_shards) == len(shard_map)

print(
    json.dumps(
        {
            "scope": scope,
            "force_full": force_full == "true",
            "escape_full": escape_full == "true",
            "run_flutter_analyze": run_analyze,
            "run_flutter_stack": run_stack,
            "run_flutter_coverage": run_flutter_coverage,
            "run_backend": run_backend,
            "run_e2e_audit": run_e2e_audit,
            "run_flutter_integration": run_integration,
            "run_org_e2e": run_org_e2e,
            "run_shards": run_shards,
            "skip_jobs": skip_jobs,
        },
        separators=(",", ":"),
    )
)
PY
}

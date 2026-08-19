#!/usr/bin/env bash
# CI path-scope resolver tests (shared rules with pre-push-changed.sh).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/ci/ci-scope-lib.sh
source "$ROOT/scripts/ci/ci-scope-lib.sh"

assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: $msg (got=$got want=$want)" >&2
    exit 1
  fi
}

assert_json_field() {
  local json="$1" field="$2" want="$3" msg="$4"
  local got
  got="$(python3 -c 'import json,sys; print(json.load(sys.stdin)[sys.argv[1]])' "$field" <<<"$json")"
  assert_eq "$got" "$want" "$msg"
}

# Server-only seed PR (#253 pattern)
ci_scope_classify_paths $'docs/e2e/uat-demo-personas.md\nserver/scripts/seed.js\nserver/test/seed.test.js'
assert_eq "$(ci_scope_resolve_name)" "SERVER_ONLY" "server scripts without flutter"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_analyze False "server-only skips analyze when no routes/lib"
assert_json_field "$json" run_flutter_stack False "server-only skips flutter stack"

# Server routes without flutter — analyze runs, stack skipped
ci_scope_reset
ci_scope_classify_paths $'server/routes/pets/index.js'
assert_eq "$(ci_scope_resolve_name)" "SERVER_ONLY" "routes-only is server-only"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_analyze True "routes touch requires flutter analyze"
assert_json_field "$json" run_flutter_stack False "routes-only skips flutter stack"

# Flutter-only
ci_scope_classify_paths $'flutter_app/lib/features/auth/presentation/screens/login_screen.dart'
assert_eq "$(ci_scope_resolve_name)" "FLUTTER_ONLY" "flutter-only scope"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "flutter-only runs stack"

# Docs-only
ci_scope_classify_paths $'docs/design/tokens.md'
assert_eq "$(ci_scope_resolve_name)" "DOCS_ONLY" "docs-only scope"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_analyze False "docs-only skips flutter"

# Force-full on core
ci_scope_classify_paths $'flutter_app/lib/core/theme/app_theme.dart'
assert_eq "$(ci_scope_resolve_name)" "FULL" "core forces full"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "core runs full stack"

# Escape hatch
ci_scope_classify_paths $'docs/readme.md'
CI_SCOPE_ESCAPE_FULL=true
assert_eq "$(ci_scope_resolve_name)" "FULL" "ci-full escape forces full"
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "escape runs stack"

# Flutter-only skips backend
ci_scope_classify_paths $'flutter_app/lib/features/auth/presentation/screens/login_screen.dart'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_backend False "flutter-only skips backend"
assert_json_field "$json" run_flutter_integration False "flutter-only without pet_profile skips integration"
python3 -c 'import json,sys; shards=json.load(sys.stdin)["run_shards"]; assert shards==["rest-a"], shards' <<<"$json"

# Organisation-only runs org shard
ci_scope_classify_paths $'flutter_app/lib/features/organization/presentation/screens/organisation_profile_screen.dart'
json="$(ci_scope_emit_json)"
python3 -c 'import json,sys; shards=json.load(sys.stdin)["run_shards"]; assert shards==["org"], shards' <<<"$json"

# Generic e2e scripts do not trigger org-specific Playwright job (full suite is audit/pre-uat only)
ci_scope_classify_paths $'e2e/scripts/check-smoke-tags.mjs'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "generic e2e scripts force full stack"

echo "ci-scope tests passed"

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

ALL_SHARDS="$(node "$ROOT/scripts/ci/flutter-shards.mjs" list --json)"

assert_all_shards() {
  local json="$1" msg="$2"
  python3 -c 'import json,sys; got=json.loads(sys.argv[1])["run_shards"]; want=json.loads(sys.argv[2]); assert got==want, (got, want)' "$json" "$ALL_SHARDS" \
    || { echo "FAIL: $msg" >&2; exit 1; }
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
assert_all_shards "$json" "flutter change runs every manifest shard"

# ESLint ratchet validator inputs keep backend scope so the F-20 lint job runs
ci_scope_classify_paths $'scripts/validate_eslint.js'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_backend True "validate_eslint input keeps backend scope"

# Any Flutter domain change runs every manifest shard + the coverage gate
ci_scope_classify_paths $'flutter_app/lib/features/experience/presentation/widgets/shelter_navigation_sidebar.dart'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "experience change runs stack"
assert_all_shards "$json" "flutter change runs every manifest shard"

# Vet-domain change still runs every shard
ci_scope_classify_paths $'flutter_app/test/features/vet/presentation/widgets/vet_team_card_test.dart'
json="$(ci_scope_emit_json)"
assert_all_shards "$json" "flutter change runs every manifest shard"

# Pet Care domain change still runs every shard
ci_scope_classify_paths $'flutter_app/lib/features/pet_care/context/away_plan_copy.dart'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "pet-care change runs stack"
assert_all_shards "$json" "flutter change runs every manifest shard"

# care-intelligence and pet-tags changes still run every shard
ci_scope_classify_paths $'flutter_app/test/features/care_intelligence/presentation/widgets/care_suggestion_card_test.dart\nflutter_app/test/features/pet_tags/domain/pet_tag_filter_test.dart'
json="$(ci_scope_emit_json)"
assert_all_shards "$json" "flutter change runs every manifest shard"

# Frozen organisation code does not run active Flutter CI
ci_scope_classify_paths $'flutter_app/lib/features/organization/presentation/screens/organisation_profile_screen.dart'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack False "frozen org paths skip flutter stack"

# Generic e2e scripts do not trigger org-specific Playwright job (full suite is audit/pre-uat only)
ci_scope_classify_paths $'e2e/scripts/check-smoke-tags.mjs'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_stack True "generic e2e scripts force full stack"

# Flutter stack always carries the domain coverage gate
ci_scope_classify_paths $'flutter_app/test/core/utils/calendar_date_test.dart'
json="$(ci_scope_emit_json)"
assert_json_field "$json" run_flutter_coverage True "flutter change runs domain coverage gate"
assert_all_shards "$json" "core test change runs every shard"

# Server-only change runs no Flutter shard and skips the matrix job
ci_scope_classify_paths $'server/scripts/seed.js'
json="$(ci_scope_emit_json)"
python3 -c 'import json,sys; d=json.load(sys.stdin); assert d["run_shards"]==[], d; assert "flutter-test" in d["skip_jobs"], d' <<<"$json"

echo "ci-scope tests passed"

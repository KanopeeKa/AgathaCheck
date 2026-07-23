#!/usr/bin/env bash
# uat-full-e2e-cadence.sh — merge counter and decide logic.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CADENCE="$ROOT/scripts/ci/uat-full-e2e-cadence.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STATE="$TMP/state.json"
export UAT_FULL_E2E_STATE_FILE="$STATE"
export UAT_FULL_E2E_MERGE_THRESHOLD=3

assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: $msg (got=$got want=$want)" >&2
    exit 1
  fi
}

run_decide() {
  bash "$CADENCE" decide
}

out="$(run_decide)"
assert_eq "$(grep '^merge_count=' <<<"$out" | cut -d= -f2)" "1" "first bump"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "true" "first deploy always runs full E2E"
assert_eq "$(grep '^reason=' <<<"$out" | cut -d= -f2)" "first_full_e2e" "first reason"

out="$(run_decide)"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "false" "merge 2 skips"
assert_eq "$(grep '^reason=' <<<"$out" | cut -d= -f2)" "cadence_skip_mod_3" "skip reason"

out="$(run_decide)"
assert_eq "$(grep '^merge_count=' <<<"$out" | cut -d= -f2)" "3" "third merge"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "true" "threshold triggers full E2E"
assert_eq "$(grep '^reason=' <<<"$out" | cut -d= -f2)" "merge_count_mod_3" "mod reason"

export UAT_FULL_E2E_FORCE_RUN=true
out="$(run_decide)"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "true" "force run overrides skip"

echo "OK: uat-full-e2e-cadence tests passed"

#!/usr/bin/env bash
# merge-audit-counter.sh — file-backed state and decide logic.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COUNTER="$ROOT/scripts/ci/merge-audit-counter.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

STATE="$TMP/state.json"
export CI_AUDIT_STATE_FILE="$STATE"
export CI_FULL_AUDIT_MERGE_THRESHOLD=3
export CI_FULL_AUDIT_STALE_DAYS=7

assert_eq() {
  local got="$1" want="$2" msg="$3"
  if [[ "$got" != "$want" ]]; then
    echo "FAIL: $msg (got=$got want=$want)" >&2
    exit 1
  fi
}

run_decide() {
  bash "$COUNTER" decide
}

# First run — no state file; should_run for first_audit
out="$(run_decide)"
assert_eq "$(grep '^merge_count=' <<<"$out" | cut -d= -f2)" "1" "first bump"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "true" "first audit runs"
assert_eq "$(grep '^reason=' <<<"$out" | cut -d= -f2)" "first_audit" "first audit reason"

# Second and third — skip until threshold
out="$(run_decide)"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "false" "merge 2 skips"
out="$(run_decide)"
assert_eq "$(grep '^merge_count=' <<<"$out" | cut -d= -f2)" "3" "third merge"
assert_eq "$(grep '^should_run=' <<<"$out" | cut -d= -f2)" "true" "threshold triggers audit"
assert_eq "$(grep '^reason=' <<<"$out" | cut -d= -f2)" "merge_count_mod_3" "mod threshold reason"

echo "OK: merge-audit-counter tests passed"

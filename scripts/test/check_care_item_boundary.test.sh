#!/usr/bin/env bash
# Fixture tests for care_item leaf import boundary checker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT/scripts/check_care_item_boundary.sh"
FIXTURES="$ROOT/scripts/test/fixtures/care-item-boundary"

assert_pass() {
  local name="$1"
  local fixture_root="$2"
  if bash "$CHECKER" --root "$fixture_root"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name expected exit 0" >&2
    exit 1
  fi
}

assert_fail() {
  local name="$1"
  local fixture_root="$2"
  if bash "$CHECKER" --root "$fixture_root"; then
    echo "FAIL: $name expected exit 1" >&2
    exit 1
  else
    echo "PASS: $name (detected violation)"
  fi
}

assert_pass "clean leaf tree" "$FIXTURES/clean"
assert_fail "cross-feature import in application/" "$FIXTURES/violation-cross-feature"

echo "All care_item boundary fixture tests passed."

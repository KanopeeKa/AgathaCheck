#!/usr/bin/env bash
# Fixture tests for manifest-driven frozen domain boundary checker.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHECKER="$ROOT/scripts/check_frozen_domain_boundaries.sh"
FIXTURES="$ROOT/scripts/test/fixtures/frozen-boundary"
MANIFEST="$FIXTURES/manifest.json"

assert_pass() {
  local name="$1"
  local fixture_root="$2"
  if bash "$CHECKER" --root "$fixture_root" --manifest "$MANIFEST"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name expected exit 0" >&2
    exit 1
  fi
}

assert_fail() {
  local name="$1"
  local fixture_root="$2"
  if bash "$CHECKER" --root "$fixture_root" --manifest "$MANIFEST"; then
    echo "FAIL: $name expected exit 1" >&2
    exit 1
  else
    echo "PASS: $name (detected violation)"
  fi
}

assert_pass "clean active tree" "$FIXTURES/clean"
assert_fail "dart frozen import" "$FIXTURES/violation-dart"
assert_fail "server frozen import" "$FIXTURES/violation-server"

echo "All frozen boundary fixture tests passed."

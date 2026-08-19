#!/usr/bin/env bash
# Resolve PR CI job scope from changed paths vs base branch.
# Emits compact JSON to stdout and GITHUB_OUTPUT when set.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=scripts/ci/ci-scope-lib.sh
source "$ROOT/scripts/ci/ci-scope-lib.sh"

BASE_SHA="${CI_SCOPE_BASE_SHA:-}"
HEAD_SHA="${CI_SCOPE_HEAD_SHA:-HEAD}"
FORCE_FULL_INPUT="${CI_SCOPE_FORCE_FULL:-false}"

if [[ -z "$BASE_SHA" ]]; then
  if [[ -n "${GITHUB_EVENT_PULL_REQUEST_BASE_SHA:-}" ]]; then
    BASE_SHA="$GITHUB_EVENT_PULL_REQUEST_BASE_SHA"
  else
    git -C "$ROOT" fetch origin main --quiet 2>/dev/null || true
    BASE_SHA="$(git -C "$ROOT" merge-base "origin/main" "$HEAD_SHA" 2>/dev/null || echo "$HEAD_SHA")"
  fi
fi

mapfile -t changed < <(
  git -C "$ROOT" diff --name-only "$BASE_SHA" "$HEAD_SHA" 2>/dev/null | sort -u
)

paths=""
if ((${#changed[@]} == 0)); then
  paths=""
else
  paths="$(printf '%s\n' "${changed[@]}")"
fi

ci_scope_classify_paths "$paths"

if [[ "$FORCE_FULL_INPUT" == "true" ]]; then
  CI_SCOPE_ESCAPE_FULL=true
fi

if [[ -n "${GITHUB_EVENT_PULL_REQUEST_NUMBER:-}" ]] && command -v gh >/dev/null 2>&1; then
  if gh pr view "${GITHUB_EVENT_PULL_REQUEST_NUMBER}" --json labels --jq '.labels[].name' 2>/dev/null | grep -Fxq 'ci-full'; then
    CI_SCOPE_ESCAPE_FULL=true
  fi
fi

head_msg="$(git -C "$ROOT" log -1 --format=%s "$HEAD_SHA" 2>/dev/null || true)"
if [[ "$head_msg" == *"[ci-full]"* ]]; then
  CI_SCOPE_ESCAPE_FULL=true
fi

json="$(ci_scope_emit_json)"
scope_name="$(python3 -c 'import json,sys; print(json.load(sys.stdin)["scope"])' <<<"$json")"
run_analyze="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_flutter_analyze"] else "false")' <<<"$json")"
run_stack="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_flutter_stack"] else "false")' <<<"$json")"
run_backend="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_backend"] else "false")' <<<"$json")"
run_e2e_audit="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_e2e_audit"] else "false")' <<<"$json")"
run_integration="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_flutter_integration"] else "false")' <<<"$json")"
run_flutter_coverage="$(python3 -c 'import json,sys; print("true" if json.load(sys.stdin)["run_flutter_coverage"] else "false")' <<<"$json")"
run_shards="$(python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin)["run_shards"]))' <<<"$json")"
echo "$json"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "scope_json<<EOF"
    echo "$json"
    echo "EOF"
    echo "scope_name=$scope_name"
    echo "run_flutter_analyze=$run_analyze"
    echo "run_flutter_stack=$run_stack"
    echo "run_backend=$run_backend"
    echo "run_e2e_audit=$run_e2e_audit"
    echo "run_flutter_integration=$run_integration"
    echo "run_flutter_coverage=$run_flutter_coverage"
    echo "run_shards=$run_shards"
  } >>"$GITHUB_OUTPUT"
fi

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
  {
    echo "### CI scope"
    echo
    echo "- **Scope:** \`$scope_name\`"
    echo "- **Base → head:** \`${BASE_SHA:0:7}\` → \`${HEAD_SHA:0:7}\`"
    echo "- **Flutter analyze:** $run_analyze"
    echo "- **Flutter stack (shards/build/canary):** $run_stack"
    echo "- **Flutter shards:** \`$run_shards\`"
    echo "- **Flutter coverage (all shards):** $run_flutter_coverage"
    echo "- **Backend Jest:** $run_backend"
    echo "- **E2E npm audit:** $run_e2e_audit"
    echo "- **Flutter integration:** $run_integration"
    if [[ "$CI_SCOPE_ESCAPE_FULL" == true ]]; then
      echo "- **Escape:** ci-full (label or commit token)"
    fi
  } >>"$GITHUB_STEP_SUMMARY"
fi

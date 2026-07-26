#!/usr/bin/env bash
# Run live UAT smoke gate (warmup-uat + uat-smoke in one Playwright process).
# On Tiger Protect WAF rate-limit, wait and retry once — IP whitelisting is not available.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/e2e"

COOLDOWN_SEC="${UAT_WAF_GATE_COOLDOWN_SEC:-180}"
MAX_WAF_RETRIES="${UAT_WAF_GATE_RETRIES:-1}"

run_gate() {
  rm -f playwright/.uat-waf-storage.json
  xvfb-run --auto-servernum npm run test:live-uat-gate
}

classify_failure_kind() {
  HEALTH_OUTCOME=success \
  WARMUP_OUTCOME=failure \
  COMBINED_LIVE_GATE=true \
  PLAYWRIGHT_REPORT_DIR=playwright-report \
  PLAYWRIGHT_RESULTS_DIR=test-results \
  bash "$ROOT/scripts/ci/classify-uat-smoke-failure.sh" \
    | sed -n 's/^smoke_failure_kind=//p'
}

if run_gate; then
  exit 0
fi

failure_kind="$(classify_failure_kind || true)"
if [[ "$failure_kind" != "waf" || "$MAX_WAF_RETRIES" -lt 1 ]]; then
  exit 1
fi

echo "Tiger Protect WAF rate-limit on live smoke — retrying after ${COOLDOWN_SEC}s cooldown (no IP whitelist available)."
sleep "$COOLDOWN_SEC"
run_gate

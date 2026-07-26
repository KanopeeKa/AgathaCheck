#!/usr/bin/env bash
# Classify UAT smoke job failure for assert-uat-gates.sh (gate_failure_class).
# Health probe (curl) sets failure_kind via uat-post-deploy-smoke.sh; Playwright
# warmup failures did not — causing infra WAF failures to be marked `code` and
# freeze promotion. See docs/e2e/uat-waf-queue-lessons.md §12.
set -euo pipefail

emit_failure_kind() {
  local kind="$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'failure_kind=%s\n' "$kind" >>"$GITHUB_OUTPUT"
  fi
  echo "smoke_failure_kind=${kind}"
}

HEALTH_OUTCOME="${HEALTH_OUTCOME:-unknown}"
WARMUP_OUTCOME="${WARMUP_OUTCOME:-skipped}"
HEALTH_FAILURE_KIND="${HEALTH_FAILURE_KIND:-}"
COMBINED_LIVE_GATE="${COMBINED_LIVE_GATE:-false}"

if [[ "$HEALTH_OUTCOME" == "success" && "$WARMUP_OUTCOME" == "success" ]]; then
  emit_failure_kind ""
  exit 0
fi

if [[ "$HEALTH_OUTCOME" != "success" ]]; then
  emit_failure_kind "${HEALTH_FAILURE_KIND:-unknown}"
  exit 0
fi

# Health OK but browser gate failed.
if [[ "$WARMUP_OUTCOME" != "success" ]]; then
  report="${PLAYWRIGHT_REPORT_DIR:-e2e/playwright-report}/index.html"
  if [[ -f "$report" ]] && grep -qiE 'blocked by hosting WAF|WAF challenge did not clear|o2s-browser-check|Test de sécurité' \
    "$report" 2>/dev/null; then
    emit_failure_kind "waf"
    exit 0
  fi
  if [[ "$COMBINED_LIVE_GATE" == "true" ]]; then
    # Combined warmup+smoke: only mark infra when WAF signals are present;
    # real @smoke-uat regressions stay unclassified → code gate in assert-uat-gates.sh.
    emit_failure_kind ""
    exit 0
  fi
  # Legacy split warmup step (health OK, warmup-only failure) → infra/WAF path.
  emit_failure_kind "waf"
  exit 0
fi

emit_failure_kind "${HEALTH_FAILURE_KIND:-unknown}"

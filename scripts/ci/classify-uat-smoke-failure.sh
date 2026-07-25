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

if [[ "$HEALTH_OUTCOME" == "success" && "$WARMUP_OUTCOME" == "success" ]]; then
  emit_failure_kind ""
  exit 0
fi

if [[ "$HEALTH_OUTCOME" != "success" ]]; then
  emit_failure_kind "${HEALTH_FAILURE_KIND:-unknown}"
  exit 0
fi

# Health OK but browser warmup failed — canonical infra/WAF path (not a code gate).
# passHostingWaf probes auth signup in-browser; Tiger Protect often blocks auth
# after health clears. Do not classify as `code` (would freeze promotion).
if [[ "$WARMUP_OUTCOME" != "success" ]]; then
  if [[ -f "${PLAYWRIGHT_REPORT_DIR:-e2e/playwright-report}/index.html" ]]; then
    if grep -qiE 'blocked by hosting WAF|WAF challenge did not clear|o2s-browser-check|Test de sécurité' \
      "${PLAYWRIGHT_REPORT_DIR}/index.html" 2>/dev/null; then
      emit_failure_kind "waf"
      exit 0
    fi
  fi
  emit_failure_kind "waf"
  exit 0
fi

emit_failure_kind "${HEALTH_FAILURE_KIND:-unknown}"

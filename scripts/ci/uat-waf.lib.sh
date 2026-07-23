#!/usr/bin/env bash
# Shared o2switch / Tiger Protect WAF detection and fail-fast for UAT CI scripts.
# Source from bash: source "$(dirname "$0")/uat-waf.lib.sh"
#
# Env:
#   WAF_FAIL_FAST_STREAK — consecutive WAF challenges before exit (default 3)
set -euo pipefail

WAF_FAIL_FAST_STREAK="${WAF_FAIL_FAST_STREAK:-3}"
_uat_waf_streak=0

is_waf_body() {
  local body="$1"
  grep -qiE 'o2s-browser-check|Security check|Test de sécurité' <<<"$body"
}

uat_waf_clear_streak() {
  _uat_waf_streak=0
}

# Record a WAF challenge. Prints status; exit 2 when streak reaches limit.
uat_waf_note_challenge() {
  local context="${1:-probe}"
  _uat_waf_streak=$((_uat_waf_streak + 1))
  echo "${context}: WAF challenge (streak ${_uat_waf_streak}/${WAF_FAIL_FAST_STREAK})"
  if (( _uat_waf_streak >= WAF_FAIL_FAST_STREAK )); then
    echo "::error title=UAT WAF blocking CI::${WAF_FAIL_FAST_STREAK} consecutive o2switch WAF challenges from GitHub Actions — whitelisting runner egress is not available on this host. Failing fast to save CI minutes (~3 min vs ~18 min). Retry the deploy later or validate manually in a browser. Infra escalation: docs/e2e/uat-live-operations-runbook.md"
    return 2
  fi
  return 1
}

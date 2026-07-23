#!/usr/bin/env bash
# Confirm UAT auth signup responds after /backend/health is green.
# Health-only probes can pass before Passenger has reloaded E2E env or auth routes
# are ready — live @smoke-uat then stalls on #/landing for the full post-login timeout.
set -euo pipefail

UAT_BASE_URL="${UAT_BASE_URL:-https://uat.agathatrack.com}"
MAX_ATTEMPTS="${AUTH_WARMUP_ATTEMPTS:-12}"
SLEEP_SECS="${AUTH_WARMUP_SLEEP_SEC:-10}"
CURL_TLS_FLAGS="${CURL_TLS_FLAGS:--k}"

signup_probe() {
  local email="e2e-warmup-$(date +%s)-${RANDOM}@example.com"
  local -a headers=(
    -H "Content-Type: application/json"
  )
  if [ -n "${E2E_BYPASS_TOKEN:-}" ]; then
    headers+=(-H "X-E2E-Bypass-Token: ${E2E_BYPASS_TOKEN}")
  fi

  local tmp body code
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  code="$(
    curl -sS ${CURL_TLS_FLAGS} -o "$tmp" -w "%{http_code}" \
      -X POST "${UAT_BASE_URL}/backend/api/auth/signup" \
      "${headers[@]}" \
      -d "{\"email\":\"${email}\",\"password\":\"E2eTestPass1\",\"first_name\":\"Warm\",\"last_name\":\"Up\",\"category\":\"pet_guardian\"}" \
      || echo "000"
  )"
  body="$(cat "$tmp")"

  if [ "$code" = "201" ] && grep -q '"access_token"' <<<"$body"; then
    return 0
  fi

  echo "signup probe HTTP ${code}: ${body:0:200}"
  return 1
}

echo "Warming UAT auth (up to ${MAX_ATTEMPTS} signup probes, ${SLEEP_SECS}s apart)..."

for i in $(seq 1 "$MAX_ATTEMPTS"); do
  if signup_probe; then
    echo "UAT auth warmup OK after attempt ${i}"
    exit 0
  fi
  if [ "$i" -lt "$MAX_ATTEMPTS" ]; then
    echo "Auth not ready (${i}/${MAX_ATTEMPTS}), sleeping ${SLEEP_SECS}s..."
    sleep "$SLEEP_SECS"
  fi
done

echo "::error::UAT auth signup did not return 201 after ${MAX_ATTEMPTS} attempts — defer live @smoke-uat"
exit 1

#!/usr/bin/env bash
# Confirm UAT auth signup responds after /backend/health is green.
# Health-only probes can pass before Passenger has reloaded E2E env or auth routes
# are ready — live @smoke-uat then stalls on #/landing for the full post-login timeout.
set -euo pipefail

UAT_BASE_URL="${UAT_BASE_URL:-https://uat.agathatrack.com}"
MAX_ATTEMPTS="${AUTH_WARMUP_ATTEMPTS:-18}"
SLEEP_SECS="${AUTH_WARMUP_SLEEP_SEC:-10}"
CURL_TLS_FLAGS="${CURL_TLS_FLAGS:--k}"

is_waf_body() {
  local body="$1"
  grep -qiE 'o2s-browser-check|Security check|Test de sécurité' <<<"$body"
}

curl_landing() {
  curl -sfk ${CURL_TLS_FLAGS} "${UAT_BASE_URL}/landing" -o /dev/null 2>/dev/null || true
}

WARMUP_EMAIL=""
WARMUP_PASSWORD="E2eTestPass1"

signup_probe() {
  WARMUP_EMAIL="e2e-warmup-$(date +%s)-${RANDOM}@example.com"
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
      -d "{\"email\":\"${WARMUP_EMAIL}\",\"password\":\"${WARMUP_PASSWORD}\",\"first_name\":\"Warm\",\"last_name\":\"Up\",\"category\":\"pet_guardian\"}" \
      || echo "000"
  )"
  body="$(cat "$tmp")"

  if [ "$code" = "201" ] && grep -q '"access_token"' <<<"$body"; then
    return 0
  fi

  if is_waf_body "$body"; then
    echo "signup probe WAF challenge (HTTP ${code})"
    return 2
  fi

  echo "signup probe HTTP ${code}: ${body:0:200}"
  return 1
}

login_probe() {
  if [ -z "${WARMUP_EMAIL}" ]; then
    echo "login probe skipped — no warmup user"
    return 1
  fi

  local tmp body code
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  code="$(
    curl -sS ${CURL_TLS_FLAGS} -o "$tmp" -w "%{http_code}" \
      -X POST "${UAT_BASE_URL}/backend/api/auth/login" \
      -H "Content-Type: application/json" \
      -d "{\"email\":\"${WARMUP_EMAIL}\",\"password\":\"${WARMUP_PASSWORD}\"}" \
      || echo "000"
  )"
  body="$(cat "$tmp")"

  if [ "$code" = "200" ] && grep -q '"access_token"' <<<"$body"; then
    return 0
  fi

  if is_waf_body "$body"; then
    echo "login probe WAF challenge (HTTP ${code})"
    return 2
  fi

  echo "login probe HTTP ${code}: ${body:0:200}"
  return 1
}

echo "Warming UAT auth (up to ${MAX_ATTEMPTS} signup probes, ${SLEEP_SECS}s apart)..."
curl_landing

for i in $(seq 1 "$MAX_ATTEMPTS"); do
  curl_landing
  signup_probe
  rc=$?
  if [ "$rc" -eq 0 ]; then
    login_probe
    login_rc=$?
    if [ "$login_rc" -eq 0 ]; then
      echo "UAT auth warmup OK after attempt ${i} (signup + login)"
      exit 0
    fi
    if [ "$login_rc" -eq 2 ]; then
      rc=2
    else
      echo "signup OK but login probe failed on attempt ${i}"
      rc=1
    fi
  fi
  if [ "$i" -lt "$MAX_ATTEMPTS" ]; then
    if [ "$rc" -eq 2 ]; then
      echo "WAF challenge (${i}/${MAX_ATTEMPTS}), sleeping ${SLEEP_SECS}s..."
    else
      echo "Auth not ready (${i}/${MAX_ATTEMPTS}), sleeping ${SLEEP_SECS}s..."
    fi
    sleep "$SLEEP_SECS"
  fi
done

echo "::error::UAT auth signup did not return 201 after ${MAX_ATTEMPTS} attempts — defer live @smoke-uat"
exit 1

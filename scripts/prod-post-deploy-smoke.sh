#!/usr/bin/env bash
# Post-deploy HTTP smoke for production — teaser vs app modes.
# Env: PROD_BASE_URL, PROD_PUBLIC_MODE (coming_soon|app)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/ci/public-access-smoke-lib.sh
source "${ROOT}/scripts/ci/public-access-smoke-lib.sh"

PROD_BASE_URL="${PROD_BASE_URL:?PROD_BASE_URL is required}"
PROD_PUBLIC_MODE="${PROD_PUBLIC_MODE:?PROD_PUBLIC_MODE is required}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-12}"
SLEEP_SECS="${SLEEP_SECS:-10}"
CURL_MAX_TIME="${CURL_MAX_TIME:-30}"

case "$PROD_PUBLIC_MODE" in
  coming_soon|app) ;;
  *)
    echo "::error title=invalid_prod_public_mode::PROD_PUBLIC_MODE must be 'coming_soon' or 'app' (got: '${PROD_PUBLIC_MODE}')"
    exit 1
    ;;
esac

emit_failure_kind() {
  local kind="$1"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf 'failure_kind=%s\n' "$kind" >>"$GITHUB_OUTPUT"
  fi
  echo "failure_kind=${kind}"
}

fail() {
  local kind="$1"
  local msg="$2"
  echo "::error title=${kind}::${msg}"
  emit_failure_kind "$kind"
  exit 1
}

# Probe URL; prints "code|body" (body may contain newlines — use NUL delimiter via temp file).
probe() {
  local url="$1"
  local tmp code
  tmp="$(mktemp)"
  code="$(curl -sS --max-time "${CURL_MAX_TIME}" -o "$tmp" -w "%{http_code}" "$url" || echo "000")"
  printf '%s\t' "$code"
  cat "$tmp"
  rm -f "$tmp"
}

probe_code() {
  local url="$1"
  curl -sS --max-time "${CURL_MAX_TIME}" -o /dev/null -w "%{http_code}" "$url" || echo "000"
}

wait_for_health() {
  local i code body kind
  echo "Probing ${PROD_BASE_URL}/backend/health (up to ${MAX_ATTEMPTS} attempts)..."
  for i in $(seq 1 "$MAX_ATTEMPTS"); do
    local raw
    raw="$(probe "${PROD_BASE_URL}/backend/health")"
    code="${raw%%$'\t'*}"
    body="${raw#*$'\t'}"
    if [[ "$code" == "200" ]] && grep -q '"status":"OK"' <<<"$body"; then
      echo "Backend healthy after attempt ${i} (HTTP ${code})"
      return 0
    fi
    echo "Waiting for Passenger restart (${i}/${MAX_ATTEMPTS})... HTTP ${code}"
    sleep "$SLEEP_SECS"
  done
  fail "health_unhealthy" "Backend health did not return OK JSON at ${PROD_BASE_URL}/backend/health"
}

smoke_coming_soon() {
  local raw code body kind dart_code

  wait_for_health

  echo "Probing ${PROD_BASE_URL}/ for coming-soon teaser..."
  raw="$(probe "${PROD_BASE_URL}/")"
  code="${raw%%$'\t'*}"
  body="${raw#*$'\t'}"
  if [[ "$code" != "200" ]]; then
    fail "teaser_mismatch" "GET / returned HTTP ${code}; expected teaser HTML"
  fi
  kind="$(pas_classify_teaser_body coming_soon "$body")"
  if [[ "$kind" != "ok" ]]; then
    fail "$kind" "GET / teaser check failed (${kind})"
  fi
  echo "Teaser HTML OK (data-site-mode=coming-soon)"

  dart_code="$(probe_code "${PROD_BASE_URL}/main.dart.js")"
  echo "GET /main.dart.js → HTTP ${dart_code}"
  if [[ "$dart_code" == "200" ]]; then
    fail "flutter_served_in_teaser_mode" "Flutter main.dart.js still returns HTTP 200 while PROD_PUBLIC_MODE=coming_soon"
  fi
  echo "Flutter asset not served (expected in teaser mode)"
}

smoke_app() {
  local code

  wait_for_health

  echo "Probing app landing..."
  code="$(probe_code "${PROD_BASE_URL}/landing")"
  if [[ "$code" == "200" ]]; then
    echo "Landing page reachable (HTTP ${code})"
    return 0
  fi
  echo "GET /landing → HTTP ${code}; falling back to /"
  code="$(probe_code "${PROD_BASE_URL}/")"
  if [[ "$code" != "200" ]]; then
    fail "app_unreachable" "Neither /landing nor / returned HTTP 200 (last=/ → ${code})"
  fi
  echo "Root page reachable (HTTP ${code})"
}

echo "prod_public_mode=${PROD_PUBLIC_MODE}"
echo "prod_base_url=${PROD_BASE_URL}"

case "$PROD_PUBLIC_MODE" in
  coming_soon) smoke_coming_soon ;;
  app) smoke_app ;;
esac

echo "Production post-deploy smoke passed (mode=${PROD_PUBLIC_MODE})"
exit 0

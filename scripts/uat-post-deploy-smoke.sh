#!/usr/bin/env bash
# Post-deploy HTTP smoke for UAT — classifies failure modes and emits actionable CI errors.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/ci/uat-waf.lib.sh
source "${ROOT}/scripts/ci/uat-waf.lib.sh"

UAT_BASE_URL="${UAT_BASE_URL:-https://uat.agathatrack.com}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-18}"
SLEEP_SECS="${SLEEP_SECS:-10}"
CURL_TLS_FLAGS="${CURL_TLS_FLAGS:--k}"

classify_body() {
  local body="$1"
  if grep -q '"status":"OK"' <<<"$body"; then
    echo "ok"
  elif grep -qiE '<title>404 Not Found</title>|The requested URL was not found' <<<"$body"; then
    echo "apache_404"
  elif grep -q 'Index of /backend' <<<"$body"; then
    echo "directory_listing"
  elif grep -qE 'flutter-view|flutter\.js|<base href="/">' <<<"$body"; then
    echo "flutter_spa"
  elif grep -qiE 'o2s-browser-check|Security check|Test de sécurité' <<<"$body"; then
    echo "waf"
  elif grep -q 'Backend alive' <<<"$body"; then
    echo "backend_root"
  elif grep -qiE 'Passenger|application error|Internal Server Error' <<<"$body"; then
    echo "passenger_crash"
  else
    echo "unknown"
  fi
}

probe_url() {
  local url="$1"
  local tmp
  tmp="$(mktemp)"
  local code
  code="$(curl -sS ${CURL_TLS_FLAGS} -o "$tmp" -w "%{http_code}" "$url" || echo "000")"
  local body kind
  body="$(cat "$tmp")"
  kind="$(classify_body "$body")"
  rm -f "$tmp"
  # Expose body on 5xx so CI log shows the Passenger error page snippet.
  if [[ "$code" =~ ^5 ]] && [ "$kind" != "ok" ]; then
    echo "::debug::HTTP ${code} response body (first 500 chars): ${body:0:500}" >&2
  fi
  printf '%s|%s' "$code" "$kind"
}

error_hint() {
  local kind="$1"
  case "$kind" in
    apache_404)
      cat <<'EOF'
Apache returned a static 404 page for /backend/health — Passenger is not handling /backend.
Usually backend/.htaccess (cPanel Passenger config) is missing or the Node.js app is not registered.
cPanel: Setup Node.js App -> app root .../backend, startup file bin/start.js -> Save -> Restart.
Ensure FTP deploy excludes backend/.htaccess (do not delete the cPanel-generated file).
EOF
      ;;
    directory_listing)
      cat <<'EOF'
Apache is serving /backend/ as a static directory listing — Passenger/Node is not running.
cPanel: Node.js App Manager → app root .../backend, startup file bin/start.js, set JWT_SECRET,
Run NPM Install (CloudLinux symlink for node_modules), then Restart.
If a real backend/node_modules folder exists on the server, delete it once before Run NPM Install.
EOF
      ;;
    flutter_spa)
      cat <<'EOF'
/backend/health returned Flutter index.html (SPA rewrite) instead of JSON.
Passenger may be down, or the site-root .htaccess is missing the /backend exclusion
(flutter_app/web/.htaccess must be deployed at the domain root). Do not overwrite
cPanel-generated backend/.htaccess (Passenger config) via FTP.
EOF
      ;;
    waf)
      echo 'Hosting WAF challenge page (o2switch Tiger Protect) — GitHub Actions egress cannot be whitelisted on this host; deploy will fail fast after repeated WAF responses. Retry later or validate manually.'
      ;;
    passenger_crash)
      cat <<'EOF'
Passenger returned a 500 crash page — the Node.js app is failing to start.
Most common causes on o2switch CloudLinux:
  1. node_modules is a real dir instead of the nodevenv symlink — SSH step should have fixed it.
     Manual fix: cPanel → File Manager → /backend → delete node_modules → Node.js Apps → Run NPM Install.
  2. JWT_SECRET or other required env vars missing — set them in cPanel → Node.js Apps → Env vars.
  3. .env file absent or has wrong DB credentials — verify /backend/.env on the server.
  4. SSH key not authorized — add the public key printed in "Verify UAT SSH" step to cPanel → SSH Access.
EOF
      ;;
    unknown)
      echo "Backend did not return {\"status\":\"OK\"}. On the server: curl -sk ${UAT_BASE_URL}/backend/health"
      echo "Enable debug logs in the workflow run to see the response body."
      ;;
    *)
      echo "Backend did not return {\"status\":\"OK\"}. On the server: curl -sk ${UAT_BASE_URL}/backend/health"
      ;;
  esac
}

emit_error() {
  local kind="$1"
  local code="$2"
  local hint
  hint="$(error_hint "$kind")"
  echo "::error title=UAT backend unhealthy (HTTP ${code}, ${kind})::${hint//$'\n'/ }"
}

curl_landing() {
  curl -sfk ${CURL_TLS_FLAGS} "${UAT_BASE_URL}/landing" -o /dev/null 2>/dev/null || true
}

echo "Probing ${UAT_BASE_URL}/backend/ (directory listing check)..."
IFS='|' read -r root_code root_kind <<<"$(probe_url "${UAT_BASE_URL}/backend/")"
if [ "$root_kind" = "directory_listing" ]; then
  echo "Backend root is an Apache directory listing (HTTP ${root_code}) — Passenger is not running."
  error_hint "$root_kind" | while IFS= read -r line; do
    [ -n "$line" ] && echo "::notice::${line}"
  done
  emit_error "$root_kind" "$root_code"
  exit 1
fi

echo "Probing ${UAT_BASE_URL}/backend/health (up to ${MAX_ATTEMPTS} attempts, ${SLEEP_SECS}s apart)..."
curl_landing

last_code=""
last_kind="unknown"

for i in $(seq 1 "$MAX_ATTEMPTS"); do
  curl_landing
  IFS='|' read -r last_code last_kind <<<"$(probe_url "${UAT_BASE_URL}/backend/health")"

  if [ "$last_kind" = "ok" ]; then
    uat_waf_clear_streak
    echo "Backend healthy after attempt ${i} (HTTP ${last_code})"
    curl -sfk "${UAT_BASE_URL}/landing" -o /dev/null
    echo "Landing page reachable"

    IFS='|' read -r root_code root_kind <<<"$(probe_url "${UAT_BASE_URL}/backend/")"
    if [ "$root_kind" != "backend_root" ]; then
      emit_error "$root_kind" "$root_code"
      exit 1
    fi
    echo "Backend root OK (HTTP ${root_code})"
    exit 0
  fi

  if [ "$last_kind" = "waf" ]; then
    waf_rc=0
    uat_waf_note_challenge "health probe" || waf_rc=$?
    if [ "$waf_rc" -eq 2 ]; then
      exit 2
    fi
  else
    uat_waf_clear_streak
  fi

  if [ "$i" -eq 1 ] || [ $((i % 6)) -eq 0 ]; then
    echo "Attempt ${i}/${MAX_ATTEMPTS}: HTTP ${last_code} — ${last_kind}"
    if [ "$last_kind" = "directory_listing" ] || [ "$last_kind" = "flutter_spa" ] || [ "$last_kind" = "passenger_crash" ] || [ "$last_kind" = "apache_404" ]; then
      error_hint "$last_kind" | while IFS= read -r line; do
        [ -n "$line" ] && echo "::notice::${line}"
      done
    fi
  else
    echo "Waiting for backend (${i}/${MAX_ATTEMPTS})..."
  fi
  sleep "$SLEEP_SECS"
done

emit_error "$last_kind" "$last_code"
exit 1

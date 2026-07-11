#!/usr/bin/env bash
# Post-deploy HTTP smoke for UAT — classifies failure modes and emits actionable CI errors.
set -euo pipefail

UAT_BASE_URL="${UAT_BASE_URL:-https://uat.agathatrack.com}"
MAX_ATTEMPTS="${MAX_ATTEMPTS:-18}"
SLEEP_SECS="${SLEEP_SECS:-10}"
CURL_TLS_FLAGS="${CURL_TLS_FLAGS:--k}"

classify_body() {
  local body="$1"
  if grep -q '"status":"OK"' <<<"$body"; then
    echo "ok"
  elif grep -q 'Index of /backend' <<<"$body"; then
    echo "directory_listing"
  elif grep -qE 'flutter-view|flutter\.js|<base href="/">' <<<"$body"; then
    echo "flutter_spa"
  elif grep -qiE 'o2s-browser-check|Security check|Test de sécurité' <<<"$body"; then
    echo "waf"
  elif grep -q 'Backend alive' <<<"$body"; then
    echo "backend_root"
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
  printf '%s|%s' "$code" "$kind"
}

error_hint() {
  local kind="$1"
  case "$kind" in
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
      echo 'Hosting WAF challenge page — verify in a browser or whitelist GitHub Actions egress for UAT.'
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

echo "Probing ${UAT_BASE_URL}/backend/health (up to ${MAX_ATTEMPTS} attempts, ${SLEEP_SECS}s apart)..."

last_code=""
last_kind="unknown"

for i in $(seq 1 "$MAX_ATTEMPTS"); do
  IFS='|' read -r last_code last_kind <<<"$(probe_url "${UAT_BASE_URL}/backend/health")"

  if [ "$last_kind" = "ok" ]; then
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

  if [ "$i" -eq 1 ] || [ $((i % 6)) -eq 0 ]; then
    echo "Attempt ${i}/${MAX_ATTEMPTS}: HTTP ${last_code} — ${last_kind}"
    if [ "$last_kind" = "directory_listing" ] || [ "$last_kind" = "flutter_spa" ]; then
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

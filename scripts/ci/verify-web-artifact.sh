#!/usr/bin/env bash
# Smoke-check flutter_app/build/web after release build (no secret values logged).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_DIR="${WEB_DIR:-${ROOT}/flutter_app/build/web}"
INDEX="${WEB_DIR}/index.html"

if [[ ! -f "${WEB_DIR}/main.dart.js" && ! -f "${WEB_DIR}/main.dart.mjs" ]]; then
  echo "::error::Expected compiled Dart web output (main.dart.js or main.dart.mjs) in ${WEB_DIR}" >&2
  exit 1
fi

if [[ ! -f "$INDEX" ]]; then
  echo "::error::Missing ${INDEX}" >&2
  exit 1
fi

if [[ -n "${POSTHOG_API_KEY:-}" ]]; then
  if ! grep -q 'POSTHOG_WEB_BEGIN' "$INDEX"; then
    echo "::error::PostHog injection marker missing from built index.html" >&2
    exit 1
  fi
  if ! grep -q 'eu.i.posthog.com' "$INDEX"; then
    echo "::error::PostHog EU host missing from built index.html" >&2
    exit 1
  fi
  echo "PostHog web markers present in built index.html"
else
  echo "::notice::POSTHOG_API_KEY unset — skipping PostHog marker checks"
fi

if [[ ! -f "${WEB_DIR}/build-manifest.json" ]]; then
  echo "::error::Missing build-manifest.json in web artifact output" >&2
  exit 1
fi

echo "Web artifact verification passed"

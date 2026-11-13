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

if [[ ! -f "${WEB_DIR}/.htaccess" ]]; then
  echo "::error::Missing ${WEB_DIR}/.htaccess (SPA rewrite + /backend exclusion for Passenger)" >&2
  exit 1
fi

if [[ ! -f "${WEB_DIR}/htaccess.spa" ]]; then
  echo "::error::Missing ${WEB_DIR}/htaccess.spa (FTP-visible copy of SPA .htaccess)" >&2
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

if ! python3 -m json.tool "${WEB_DIR}/build-manifest.json" >/dev/null; then
  echo "::error::build-manifest.json is not valid JSON" >&2
  exit 1
fi

VERSION_JSON="${WEB_DIR}/version.json"
if [[ ! -f "$VERSION_JSON" ]]; then
  python3 - "$VERSION_JSON" "${ROOT}/flutter_app/pubspec.yaml" <<'PY'
import json
import re
import sys

out_path, pubspec_path = sys.argv[1:3]
version_line = ""
with open(pubspec_path, encoding="utf-8") as fh:
    for line in fh:
        if line.strip().startswith("version:"):
            version_line = line.split(":", 1)[1].strip()
            break
match = re.match(r"^(\S+?)(?:\+(\S+))?$", version_line)
app_version = match.group(1) if match else ""
build = match.group(2) if match and match.group(2) else ""
payload = {"version": app_version, "build": build}
with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(payload, fh, indent=2)
    fh.write("\n")
print(f"Wrote version.json ({app_version}+{build})")
PY
fi

if [[ ! -f "$VERSION_JSON" ]]; then
  echo "::error::Missing ${VERSION_JSON} beside index.html" >&2
  exit 1
fi

if ! python3 -m json.tool "$VERSION_JSON" >/dev/null; then
  echo "::error::version.json is not valid JSON" >&2
  exit 1
fi

echo "Web artifact verification passed"

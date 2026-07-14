#!/usr/bin/env bash
# Write build-manifest.json into flutter_app/build/web/ for artifact provenance.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WEB_DIR="${WEB_DIR:-${ROOT}/flutter_app/build/web}"
MANIFEST="${WEB_DIR}/build-manifest.json}"
LOCKFILE="${ROOT}/flutter_app/pubspec.lock"

if [[ ! -d "$WEB_DIR" ]]; then
  echo "::error::Web build output not found at ${WEB_DIR}" >&2
  exit 1
fi

export POSTHOG_INJECTED="${POSTHOG_INJECTED:-$([[ -n "${POSTHOG_API_KEY:-}" ]] && echo true || echo false)}"
export LOCKFILE_SHA256="${LOCKFILE_SHA256:-}"
if [[ -z "$LOCKFILE_SHA256" && -f "$LOCKFILE" ]]; then
  export LOCKFILE_SHA256="$(sha256sum "$LOCKFILE" | awk '{print $1}')"
fi

python3 - "$MANIFEST" <<'PY'
import json
import os
from datetime import datetime, timezone

manifest = {
    "git_sha": os.environ.get("GITHUB_SHA", ""),
    "git_ref": os.environ.get("GITHUB_REF", ""),
    "repo": os.environ.get("GITHUB_REPOSITORY", ""),
    "flutter_version": os.environ.get("FLUTTER_VERSION", "3.32.0"),
    "pubspec_lock_sha256": os.environ.get("LOCKFILE_SHA256", ""),
    "posthog_injected": os.environ.get("POSTHOG_INJECTED", "false") == "true",
    "dart_defines": {
        "POSTHOG_HOST": "https://eu.i.posthog.com",
    },
    "run_clean": os.environ.get("RUN_CLEAN", "false") == "true",
    "run_codegen": os.environ.get("RUN_CODEGEN", "true") == "true",
    "source_workflow": os.environ.get("SOURCE_WORKFLOW", os.environ.get("GITHUB_WORKFLOW", "")),
    "source_run_id": os.environ.get("GITHUB_RUN_ID", ""),
    "artifact_name": os.environ.get("ARTIFACT_NAME", "web-build"),
    "built_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
}
with open("$MANIFEST", "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
print(f"Wrote {manifest['artifact_name']} manifest to $MANIFEST")
PY

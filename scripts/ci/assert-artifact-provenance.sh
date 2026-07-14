#!/usr/bin/env bash
# Validate build-manifest.json provenance before PROD promotion.
set -euo pipefail

MANIFEST_PATH="${MANIFEST_PATH:-flutter_app/build/web/build-manifest.json}"
EXPECTED_SHA="${EXPECTED_SHA:?EXPECTED_SHA required}"
EXPECTED_WORKFLOW="${EXPECTED_WORKFLOW:-Deploy UAT (uat.agathatrack.com)}"
UAT_RUN_ID="${UAT_RUN_ID:-}"
REPO="${GITHUB_REPOSITORY:-}"

if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "::error::Manifest not found at ${MANIFEST_PATH}" >&2
  exit 1
fi

python3 - "$MANIFEST_PATH" "$EXPECTED_SHA" "$EXPECTED_WORKFLOW" <<'PY'
import json
import sys

path, expected_sha, expected_workflow = sys.argv[1:4]
with open(path, encoding="utf-8") as fh:
    data = json.load(fh)

errors = []
if data.get("git_sha") != expected_sha:
    errors.append(f"git_sha mismatch: manifest={data.get('git_sha')!r} expected={expected_sha!r}")
if data.get("source_workflow") != expected_workflow:
    errors.append(
        f"source_workflow mismatch: manifest={data.get('source_workflow')!r} expected={expected_workflow!r}"
    )
expected_artifact = f"web-build-{expected_sha}"
if data.get("artifact_name") != expected_artifact:
    errors.append(
        f"artifact_name mismatch: manifest={data.get('artifact_name')!r} expected={expected_artifact!r}"
    )
if errors:
    for err in errors:
        print(f"::error::{err}")
    raise SystemExit(1)
print(f"Manifest provenance OK for {expected_sha}")
PY

if [[ -n "$UAT_RUN_ID" ]]; then
  if [[ -z "$REPO" ]]; then
    echo "::error::GITHUB_REPOSITORY required when UAT_RUN_ID is set" >&2
    exit 1
  fi
  prod_ready="$(gh run view "$UAT_RUN_ID" --repo "$REPO" --json jobs \
    --jq '.jobs[] | select(.name=="Prod ready") | .conclusion' | head -1)"
  if [[ "$prod_ready" != "success" ]]; then
    echo "::error::UAT run ${UAT_RUN_ID} Prod ready conclusion is '${prod_ready:-missing}' (expected success)" >&2
    exit 1
  fi
  echo "UAT run ${UAT_RUN_ID} Prod ready: success"
fi

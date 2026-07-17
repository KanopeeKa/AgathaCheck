#!/usr/bin/env bash
# Write promotion-manifest.json for traceability (promotion contract).
#
# Environment:
#   COMMIT_SHA, PR_NUMBER, UAT_TAG, PROMOTE_RUN_ID (GITHUB_RUN_ID)
#   UAT_DEPLOY_RUN_ID, PROD_RUN_ID — optional downstream updates
#
# Usage:
#   scripts/ci/write-promotion-manifest.sh [output-path]
set -euo pipefail

OUT="${1:-promotion-manifest.json}"

python3 - "$OUT" <<'PY'
import json
import os
import sys

out_path = sys.argv[1]
manifest = {
    "commit_sha": os.environ.get("COMMIT_SHA", ""),
    "pr_number": int(os.environ.get("PR_NUMBER", "0") or 0),
    "uat_tag": os.environ.get("UAT_TAG", ""),
    "artifact_name": os.environ.get("ARTIFACT_NAME", ""),
    "promote_run_id": os.environ.get("PROMOTE_RUN_ID", os.environ.get("GITHUB_RUN_ID", "")),
    "uat_deploy_run_id": os.environ.get("UAT_DEPLOY_RUN_ID", ""),
    "prod_run_id": os.environ.get("PROD_RUN_ID", ""),
    "promotion_status": os.environ.get("PROMOTION_STATUS", ""),
}
with open(out_path, "w", encoding="utf-8") as fh:
    json.dump(manifest, fh, indent=2)
    fh.write("\n")
print(f"Wrote {out_path}")
PY

#!/usr/bin/env bash
# Download a versioned UAT web artifact and validate provenance for PROD promotion.
set -euo pipefail

SHA=""
UAT_RUN_ID=""
OUTPUT_DIR="flutter_app/build/web"

usage() {
  echo "usage: download-uat-artifact.sh --sha <commit> [--uat-run-id <id>] [--output-dir <path>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --sha)
      SHA="$2"
      shift 2
      ;;
    --uat-run-id)
      UAT_RUN_ID="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$SHA" ]]; then
  echo "::error::--sha is required" >&2
  usage
  exit 1
fi

REPO="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
if [[ -z "$REPO" ]]; then
  echo "::error::Could not resolve GITHUB_REPOSITORY" >&2
  exit 1
fi

ARTIFACT_NAME="web-build-${SHA}"

if [[ -z "$UAT_RUN_ID" ]]; then
  UAT_RUN_ID="$(gh run list --repo "$REPO" --workflow=deploy-uat.yml --limit=40 \
    --json databaseId,headSha,conclusion,createdAt \
    --jq --arg sha "$SHA" \
      '[.[] | select(.headSha == $sha and .conclusion == "success")]
       | sort_by(.createdAt) | reverse | .[0].databaseId // empty')"
  if [[ -z "$UAT_RUN_ID" ]]; then
    echo "::error::No successful Deploy UAT workflow run found for commit ${SHA}" >&2
    exit 1
  fi
  echo "Resolved UAT workflow run ${UAT_RUN_ID} for commit ${SHA} (most recent successful)"
fi

prod_ready="$(gh run view "$UAT_RUN_ID" --repo "$REPO" --json jobs \
  --jq '.jobs[] | select(.name=="Prod ready") | .conclusion' | head -1)"
if [[ "$prod_ready" != "success" ]]; then
  echo "::error::UAT run ${UAT_RUN_ID} Prod ready is '${prod_ready:-missing}' — cannot promote to PROD" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
echo "Downloading artifact ${ARTIFACT_NAME} from UAT run ${UAT_RUN_ID}"
gh run download "$UAT_RUN_ID" --repo "$REPO" -n "$ARTIFACT_NAME" -D "$TMP_DIR"

bash "$(cd "$(dirname "$0")" && pwd)/materialize-web-artifact.sh" \
  --source "$TMP_DIR" \
  --artifact-name "$ARTIFACT_NAME" \
  --dest "$OUTPUT_DIR"

MANIFEST_PATH="${OUTPUT_DIR}/build-manifest.json" \
  EXPECTED_SHA="$SHA" \
  UAT_RUN_ID="$UAT_RUN_ID" \
  bash "$(cd "$(dirname "$0")" && pwd)/assert-artifact-provenance.sh"

echo "Promoted artifact ${ARTIFACT_NAME} from UAT run ${UAT_RUN_ID}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "uat_run_id=${UAT_RUN_ID}"
    echo "artifact_name=${ARTIFACT_NAME}"
  } >> "$GITHUB_OUTPUT"
fi

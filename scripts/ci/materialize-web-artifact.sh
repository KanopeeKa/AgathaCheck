#!/usr/bin/env bash
# Flatten a downloaded web artifact into the deploy web root (index.html at dest/).
set -euo pipefail

SOURCE=""
DEST=""
ARTIFACT_NAME=""

usage() {
  echo "usage: materialize-web-artifact.sh --source <dir> --dest <dir> [--artifact-name <name>]" >&2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE="$2"
      shift 2
      ;;
    --dest)
      DEST="$2"
      shift 2
      ;;
    --artifact-name)
      ARTIFACT_NAME="$2"
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

if [[ -z "$SOURCE" || -z "$DEST" ]]; then
  echo "::error::--source and --dest are required" >&2
  usage
  exit 1
fi

is_web_root() {
  local dir="$1"
  [[ -f "${dir}/index.html" ]] && { [[ -f "${dir}/main.dart.js" ]] || [[ -f "${dir}/main.dart.mjs" ]]; }
}

is_complete_web_artifact() {
  local dir="$1"
  is_web_root "$dir" && [[ -f "${dir}/build-manifest.json" ]]
}

copy_web_root() {
  local from="$1"
  local to="$2"
  mkdir -p "$to"
  shopt -s dotglob nullglob
  rm -rf "${to:?}"/*
  cp -a "${from}/." "${to}/"
}

mkdir -p "$DEST"

SOURCE_MODE=""
if is_web_root "$SOURCE"; then
  SOURCE_MODE="flat"
  copy_web_root "$SOURCE" "$DEST"
  echo "Materialized web root from flat download at ${SOURCE}"
elif [[ -n "$ARTIFACT_NAME" ]] && is_web_root "${SOURCE}/${ARTIFACT_NAME}"; then
  SOURCE_MODE="nested"
  copy_web_root "${SOURCE}/${ARTIFACT_NAME}" "$DEST"
  echo "Materialized web root from nested download ${SOURCE}/${ARTIFACT_NAME}"
else
  found=""
  for candidate in "${SOURCE}"/*; do
    if [[ -d "$candidate" ]] && is_web_root "$candidate"; then
      found="$candidate"
      break
    fi
  done
  if [[ -n "$found" ]]; then
    SOURCE_MODE="nested"
    copy_web_root "$found" "$DEST"
    echo "Materialized web root from nested download ${found}"
  elif is_complete_web_artifact "$DEST"; then
    SOURCE_MODE="already-present"
    echo "Complete web artifact already present at ${DEST}"
  else
    if is_web_root "$DEST"; then
      echo "::warning::Stale partial web root at ${DEST} (missing build-manifest.json) — could not replace from ${SOURCE}" >&2
    fi
    echo "::error::Could not locate web root under ${SOURCE} (expected index.html + main.dart.js)" >&2
    find "$SOURCE" -maxdepth 3 -type f 2>/dev/null | head -20 || true
    exit 1
  fi
fi

WEB_DIR="$DEST" bash "$(cd "$(dirname "$0")" && pwd)/verify-web-artifact.sh"

summary_args=(
  "source_mode=${SOURCE_MODE}"
  "dest=${DEST}"
)
if [[ -n "$ARTIFACT_NAME" ]]; then
  summary_args+=("artifact_name=${ARTIFACT_NAME}")
fi
bash "$(cd "$(dirname "$0")" && pwd)/append-summary.sh" "Web artifact materialize" "${summary_args[@]}"

#!/usr/bin/env bash
# Detect server/package*.json changes since the previous deploy tag.
#
# UAT: compare current uat-* tag to the prior uat-* tag (by creatordate).
# PROD: compare current deploy commit to the newest ancestor v* prod tag.
#
# Usage:
#   DEPLOY_REF=uat-260906-1052 bash scripts/ci/detect-deploy-package-changed.sh --kind uat
#   DEPLOY_REF=<sha> bash scripts/ci/detect-deploy-package-changed.sh --kind prod
#
# Outputs (stdout + GITHUB_OUTPUT when set):
#   changed=true|false
#   baseline_tag=<tag-or-none>
set -euo pipefail

usage() {
  echo "usage: detect-deploy-package-changed.sh --kind uat|prod" >&2
  exit 2
}

KIND=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)
      KIND="${2:?--kind requires uat or prod}"
      shift 2
      ;;
    -h | --help)
      usage
      ;;
    *)
      echo "::error::Unknown argument: $1" >&2
      usage
      ;;
  esac
done

[[ -n "$KIND" ]] || usage

DEPLOY_REF="${DEPLOY_REF:-HEAD}"

emit_output() {
  local key="$1"
  local value="$2"
  if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    printf '%s=%s\n' "$key" "$value" >>"$GITHUB_OUTPUT"
  fi
  printf '%s=%s\n' "$key" "$value"
}

is_valid_prod_tag() {
  local tag="$1"
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] && return 0
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$ ]] && return 0
  return 1
}

fetch_tags() {
  case "$KIND" in
    uat)
      git fetch origin 'refs/tags/uat-*:refs/tags/uat-*' --force 2>/dev/null \
        || git fetch --tags origin 2>/dev/null \
        || true
      ;;
    prod)
      git fetch origin 'refs/tags/v*:*' --force 2>/dev/null \
        || git fetch --tags origin 2>/dev/null \
        || true
      ;;
  esac
}

resolve_baseline_tag() {
  local current_sha="$1"
  local deploy_label="$2"
  local baseline=""

  if [[ "$KIND" == "uat" ]]; then
    local prev="" t
    while IFS= read -r t; do
      [[ -n "$t" ]] || continue
      if [[ "$t" == "$deploy_label" ]] || [[ "$(git rev-parse "$t")" == "$current_sha" ]]; then
        baseline="$prev"
        break
      fi
      prev="$t"
    done < <(git tag -l 'uat-*' --sort=creatordate)
  else
    local t tag_sha
    while IFS= read -r t; do
      [[ -n "$t" ]] || continue
      is_valid_prod_tag "$t" || continue
      tag_sha="$(git rev-parse "$t")"
      [[ "$tag_sha" == "$current_sha" ]] && continue
      if git merge-base --is-ancestor "$tag_sha" "$current_sha" 2>/dev/null; then
        baseline="$t"
        break
      fi
    done < <(git tag -l 'v*' --sort=-creatordate)
  fi

  printf '%s\n' "$baseline"
}

fetch_tags

current_sha="$(git rev-parse "$DEPLOY_REF")"
deploy_label="${DEPLOY_REF#refs/tags/}"
baseline_tag="$(resolve_baseline_tag "$current_sha" "$deploy_label")"

changed=false
if [[ -z "$baseline_tag" ]]; then
  changed=true
  echo "::notice::No prior ${KIND} deploy tag found — treating server/package*.json as changed for safety."
else
  if git diff --name-only "${baseline_tag}" "${DEPLOY_REF}" -- server/package.json server/package-lock.json | grep -q .; then
    changed=true
  fi
  echo "package baseline: ${baseline_tag} → ${deploy_label} (${current_sha:0:7})"
fi

if [[ "$changed" == true ]]; then
  emit_output changed true
  echo "::warning title=Dependencies changed::server/package.json or package-lock.json changed since ${baseline_tag:-<no prior ${KIND} tag>} — run cPanel Setup Node.js App → Run NPM Install before the backend can start."
else
  emit_output changed false
  echo "No server/package*.json changes since ${baseline_tag}."
fi

emit_output baseline_tag "${baseline_tag:-none}"

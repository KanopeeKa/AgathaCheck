#!/usr/bin/env bash
# Validate production release tag format (stable or stub -rc).
#
# Usage:
#   scripts/ci/assert-prod-tag.sh <tag-or-ref> [--kind stable|rc|any]
#
# Exits 0 when valid; 1 with ::error:: when malformed.
set -euo pipefail

raw="${1:?usage: assert-prod-tag.sh <tag-or-ref> [--kind stable|rc|any]}"
kind="any"
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)
      kind="${2:?--kind requires stable|rc|any}"
      shift 2
      ;;
    *)
      echo "::error::Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

tag="${raw#refs/tags/}"
stable_re='^v[0-9]+\.[0-9]+\.[0-9]+$'
rc_re='^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$'

case "$kind" in
  stable)
    if [[ ! "$tag" =~ $stable_re ]]; then
      echo "::error::Invalid stable prod tag '${tag}' — expected vX.Y.Z" >&2
      exit 1
    fi
    ;;
  rc)
    if [[ ! "$tag" =~ $rc_re ]]; then
      echo "::error::Invalid prod stub tag '${tag}' — expected vX.Y.Z-rc.N" >&2
      exit 1
    fi
    ;;
  any)
    if [[ ! "$tag" =~ $stable_re && ! "$tag" =~ $rc_re ]]; then
      echo "::error::Invalid prod tag '${tag}' — expected vX.Y.Z or vX.Y.Z-rc.N" >&2
      exit 1
    fi
    ;;
  *)
    echo "::error::Unknown kind '${kind}'" >&2
    exit 1
    ;;
esac

echo "Prod tag OK: ${tag}"

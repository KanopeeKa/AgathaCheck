#!/usr/bin/env bash
# Validate UAT promotion tag format: uat-YYMMDD-PR# (UTC date, PR number).
#
# Usage:
#   scripts/ci/assert-uat-tag.sh <tag-or-ref>
#
# Exits 0 when valid; 1 with ::error:: when malformed.
set -euo pipefail

raw="${1:?usage: assert-uat-tag.sh <tag-or-ref>}"
tag="${raw#refs/tags/}"

if [[ ! "$tag" =~ ^uat-[0-9]{6}-[0-9]+$ ]]; then
  echo "::error::Invalid UAT tag '${tag}' — expected uat-YYMMDD-PR# (e.g. uat-260716-170)" >&2
  exit 1
fi

echo "UAT tag OK: ${tag}"

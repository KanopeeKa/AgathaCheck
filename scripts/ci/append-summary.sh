#!/usr/bin/env bash
# Append a standardized markdown section to the GitHub Actions step summary.
#
# Usage:
#   scripts/ci/append-summary.sh "<Section title>" key=value [key=value ...]
#
# Special keys:
#   duration_sec — rendered as human-readable duration
#   gate_outcome — highlighted in summary
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: append-summary.sh <section_title> [key=value ...]" >&2
  exit 1
fi

title="$1"
shift

SUMMARY_FILE="${GITHUB_STEP_SUMMARY:-}"
if [[ -z "$SUMMARY_FILE" ]]; then
  exec 3>&1
else
  exec 3>>"$SUMMARY_FILE"
fi

format_duration() {
  local sec="$1"
  if [[ "$sec" -lt 60 ]]; then
    printf '%ss' "$sec"
  else
    printf '%sm %ss' "$((sec / 60))" "$((sec % 60))"
  fi
}

{
  echo "### ${title}"
  echo
  echo "| Field | Value |"
  echo "|-------|-------|"
  for pair in "$@"; do
    key="${pair%%=*}"
    value="${pair#*=}"
    case "$key" in
      duration_sec)
        if [[ "$value" =~ ^[0-9]+$ ]]; then
          value="$(format_duration "$value") (${value}s)"
        fi
        ;;
      gate_outcome)
        value="\`${value}\`"
        ;;
    esac
    echo "| ${key} | ${value} |"
  done
  echo
} >&3

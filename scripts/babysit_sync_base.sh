#!/usr/bin/env bash
# Proactive base sync for /babysit and /babysit-plus.
# Fetch origin/<base> and rebase when the branch is behind — do not wait for CI to fail.
#
# Usage:
#   ./scripts/babysit_sync_base.sh                    # rebase onto origin/main if behind
#   ./scripts/babysit_sync_base.sh --pr <url|num>   # use PR base branch (via gh)
#   ./scripts/babysit_sync_base.sh --base main      # explicit base (default: main)
#   ./scripts/babysit_sync_base.sh --check          # exit 1 if behind, 0 if up to date
#   ./scripts/babysit_sync_base.sh --no-rebase      # report only, never rebase
#   ./scripts/babysit_sync_base.sh --push           # force-with-lease push after rebase
#
# Exit codes: 0 up to date (or rebase ok), 1 behind (--check / --no-rebase), 2 usage/error, 3 rebase conflict
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE="main"
REBASE=true
PUSH=false
CHECK_ONLY=false
PR=""

usage() {
  cat <<'EOF'
Usage: ./scripts/babysit_sync_base.sh [options]

Options:
  --base <branch>   Base branch on origin (default: main)
  --pr <url|num>    Derive base from PR via gh (overrides --base)
  --check           Exit 1 when behind; do not rebase
  --no-rebase       Print status only; do not rebase
  --push            git push --force-with-lease after a successful rebase
  -h, --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      BASE="${2:?--base requires a branch name}"
      shift 2
      ;;
    --pr)
      PR="${2:?--pr requires a PR URL or number}"
      shift 2
      ;;
    --check)
      CHECK_ONLY=true
      REBASE=false
      shift
      ;;
    --no-rebase)
      REBASE=false
      shift
      ;;
    --push)
      PUSH=true
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "babysit_sync_base: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -n "$PR" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "babysit_sync_base: gh is required for --pr" >&2
    exit 2
  fi
  BASE="$(gh pr view "$PR" --json baseRefName -q .baseRefName)"
fi

REMOTE_BASE="origin/$BASE"
git fetch origin "$BASE" --quiet

if ! git rev-parse --verify "$REMOTE_BASE" >/dev/null 2>&1; then
  echo "babysit_sync_base: $REMOTE_BASE not found after fetch" >&2
  exit 2
fi

BEHIND="$(git rev-list --count HEAD.."$REMOTE_BASE")"
AHEAD="$(git rev-list --count "$REMOTE_BASE"..HEAD)"

if [[ "$BEHIND" -eq 0 ]]; then
  echo "babysit_sync_base: up to date with $REMOTE_BASE ($AHEAD commit(s) ahead)"
  exit 0
fi

echo "babysit_sync_base: behind $REMOTE_BASE by $BEHIND commit(s) ($AHEAD ahead)"

if [[ "$CHECK_ONLY" == true ]] || [[ "$REBASE" == false ]]; then
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "babysit_sync_base: working tree not clean — commit or stash changes before rebase" >&2
  exit 2
fi

if ! git rebase "$REMOTE_BASE"; then
  echo "babysit_sync_base: rebase conflict — resolve manually, then git rebase --continue" >&2
  exit 3
fi

echo "babysit_sync_base: rebased onto $REMOTE_BASE"

if [[ "$PUSH" == true ]]; then
  BRANCH="$(git branch --show-current)"
  if [[ -z "$BRANCH" ]]; then
    echo "babysit_sync_base: detached HEAD — cannot --push" >&2
    exit 2
  fi
  git push --force-with-lease origin "HEAD:$BRANCH"
  echo "babysit_sync_base: pushed $BRANCH"
fi

exit 0

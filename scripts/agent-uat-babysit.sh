#!/usr/bin/env bash
# UAT subagent entry: full localhost E2E → promote tag → wait deploy → PR comment.
#
# Usage:
#   ./scripts/agent-uat-babysit.sh --merge <sha> --pr <n> --pr-url <url> [--ref "plan:…"]
#
# Environment:
#   UAT_BABYSIT_MAX_ATTEMPTS (default 3)
#   UAT_BABYSIT_LOCK_DIR (default /tmp/agatha-uat-babysit)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="/opt/flutter/bin:${PATH:-}"

MERGE_SHA=""
PR_NUMBER=""
PR_URL=""
REF_LABEL=""
MAX_ATTEMPTS="${UAT_BABYSIT_MAX_ATTEMPTS:-3}"
LOCK_DIR="${UAT_BABYSIT_LOCK_DIR:-/tmp/agatha-uat-babysit}"
SHARD_TOTAL=11

while [[ $# -gt 0 ]]; do
  case "$1" in
    --merge) MERGE_SHA="${2:?}"; shift 2 ;;
    --pr) PR_NUMBER="${2:?}"; shift 2 ;;
    --pr-url) PR_URL="${2:?}"; shift 2 ;;
    --ref) REF_LABEL="${2:?}"; shift 2 ;;
    --max-attempts) MAX_ATTEMPTS="${2:?}"; shift 2 ;;
    -h|--help)
      sed -n '2,8p' "$0"
      exit 0
      ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
done

if [[ -z "$MERGE_SHA" || -z "$PR_NUMBER" ]]; then
  echo "agent-uat-babysit: --merge and --pr are required" >&2
  exit 1
fi

PR_URL="${PR_URL:-$(gh pr view "$PR_NUMBER" --json url -q .url 2>/dev/null || true)}"

comment_pr() {
  local body="$1"
  if [[ -n "$PR_URL" ]]; then
    gh pr comment "$PR_URL" --body "$body" || true
  fi
}

acquire_lock() {
  mkdir -p "$LOCK_DIR"
  local lockfile="${LOCK_DIR}/active.lock"
  if [[ -f "$lockfile" ]]; then
    local holder
    holder="$(cat "$lockfile" 2>/dev/null || echo unknown)"
    if kill -0 "$holder" 2>/dev/null; then
      comment_pr "## UAT babysit skipped

Another UAT babysit is active (pid ${holder}). Latest \`main\` will be picked up when it finishes.
- requested merge: \`${MERGE_SHA:0:7}\`
- PR: #${PR_NUMBER}"
      echo "agent-uat-babysit: lock held by pid ${holder} — exiting"
      exit 0
    fi
  fi
  echo $$ >"$lockfile"
  trap 'rm -f "${LOCK_DIR}/active.lock"' EXIT
}

run_localhost_e2e() {
  echo "==> Bootstrapping stack for E2E"
  sudo pg_ctlcluster 16 main start 2>/dev/null || true
  chmod +x "${ROOT}/e2e/scripts/bootstrap-db.sh"
  "${ROOT}/e2e/scripts/bootstrap-db.sh"

  echo "==> Building Flutter web"
  cd "${ROOT}/flutter_app"
  flutter pub get
  flutter build web --release --no-tree-shake-icons

  echo "==> Installing E2E deps"
  cd "${ROOT}/e2e"
  npm ci
  npx playwright install chromium --with-deps

  echo "==> Starting server"
  cd "${ROOT}/server"
  export PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db
  export E2E=1
  if lsof -i :3000 >/dev/null 2>&1; then
    fuser -k 3000/tcp 2>/dev/null || true
    sleep 1
  fi
  node bin/start.js &
  SERVER_PID=$!
  trap 'kill $SERVER_PID 2>/dev/null || true; rm -f "${LOCK_DIR}/active.lock"' EXIT
  sleep 3

  echo "==> Running ${SHARD_TOTAL} localhost E2E shards"
  cd "${ROOT}/e2e"
  local shard
  for shard in $(seq 1 "$SHARD_TOTAL"); do
    echo "--- shard ${shard}/${SHARD_TOTAL} ---"
    npm run test:ci-shard -- "$shard"
  done
}

resolve_main_head() {
  git -C "$ROOT" fetch origin main --depth=1
  git -C "$ROOT" rev-parse origin/main
}

acquire_lock

attempt=1
while [[ $attempt -le $MAX_ATTEMPTS ]]; do
  current_head="$(resolve_main_head)"
  if [[ "$current_head" != "$MERGE_SHA" ]]; then
    echo "::notice::main advanced ${MERGE_SHA:0:7} → ${current_head:0:7} — babysitting latest HEAD"
    MERGE_SHA="$current_head"
  fi

  git -C "$ROOT" checkout "$MERGE_SHA"

  comment_pr "## UAT babysit attempt ${attempt}/${MAX_ATTEMPTS}

- merge: \`${MERGE_SHA}\`
- ref: ${REF_LABEL:-pr-${PR_NUMBER}}
- status: running localhost E2E"

  if ! run_localhost_e2e; then
    comment_pr "## UAT babysit — E2E failed (attempt ${attempt}/${MAX_ATTEMPTS})

Open remedial PR for blocking E2E on \`main\` at \`${MERGE_SHA:0:7}\`, merge, then re-run babysit."
    if [[ $attempt -ge $MAX_ATTEMPTS ]]; then
      echo "agent-uat-babysit: E2E failed — retry cap reached" >&2
      exit 1
    fi
    attempt=$((attempt + 1))
    continue
  fi

  uat_tag="uat-$(date -u +%y%m%d)-${PR_NUMBER}"
  promote_out="$(mktemp)"
  if ! bash "${ROOT}/scripts/ci/trigger-promote-uat.sh" --commit "$MERGE_SHA" --pr "$PR_NUMBER" | tee "$promote_out"; then
    comment_pr "## UAT babysit — promote dispatch failed (attempt ${attempt}/${MAX_ATTEMPTS})"
    rm -f "$promote_out"
    exit 1
  fi
  promote_run_id="$(grep -E '^promote_run_id=' "$promote_out" | cut -d= -f2- || true)"
  rm -f "$promote_out"

  if ! bash "${ROOT}/scripts/ci/wait-uat-deploy.sh" --tag "$uat_tag" ${promote_run_id:+--promote-run "$promote_run_id"}; then
    comment_pr "## UAT babysit — deploy failed (attempt ${attempt}/${MAX_ATTEMPTS})

Tag \`${uat_tag}\` may exist — check deploy-uat workflow. Remedial or manual promote per docs/e2e/uat-promote-manual.md"
    if [[ $attempt -ge $MAX_ATTEMPTS ]]; then
      exit 1
    fi
    attempt=$((attempt + 1))
    continue
  fi

  comment_pr "## UAT prod-ready ✅

- merge: \`${MERGE_SHA}\`
- tag: \`${uat_tag}\`
- attempt: ${attempt}/${MAX_ATTEMPTS}

HTTP post-deploy smoke passed. Production promotion may follow via deploy-prod."
  echo "agent-uat-babysit: success"
  exit 0
done

exit 1

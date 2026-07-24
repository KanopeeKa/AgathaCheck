---
name: uat-coordinator
description: Own UAT deploy failures — triage gates, open remedial PRs or escalate infra blockers, advance ledger barrier. Dispatched from uat-coordinator-dispatch.yml on prod-ready failure.
---

# UAT coordinator

Single failure owner for UAT `deploy-uat` / `prod-ready` failures. Work agents enqueue and continue; **you** triage, remediate, and clear the queue hold.

**Plan:** `docs/agent-efficiency/uat-coordinator-plan.md`  
**Ledger CLI:** `scripts/uat_queue_runtime.js`  
**Coordination issue:** `UAT_COORDINATION_ISSUE` (pinned `[uat-coordinator] UAT deploy queue`)

---

## Inputs

| Input | Source |
|-------|--------|
| Sanitized payload | Dispatch comment on coordination issue (`<!-- uat-coordinator-run:`) or workflow log JSON |
| Failed workflow URL | Payload `failure.workflow_url` |
| PR number | Payload `failure.pr_number` |
| Gate table | Payload `gates.failed` |

---

## Workflow

### 0. Preflight

```bash
export UAT_COORDINATION_ISSUE=<n>   # or pass --issue on every CLI call
node scripts/uat_queue_runtime.js health-check
node scripts/uat_queue_runtime.js status
```

Confirm you hold the watcher lease (dispatch acquires it). If not:

```bash
node scripts/uat_queue_runtime.js acquire-watcher --holder "coordinator-<session>" --write
```

### 1. Classify (mandatory)

Use the gate table from the payload. **Do not open code remedials for infra blockers.**

| Failed gate | First check | Action |
|-------------|-------------|--------|
| HTTP smoke — WAF body | `WAF challenge` / `o2switch` in logs | **Escalate** — no code PR |
| HTTP smoke — Passenger/404 | `uat-post-deploy-smoke.sh` hints | Infra / cPanel — escalate |
| Live E2E — `#/landing` stall | HTTP smoke / WAF on same run | Infra first; else auth E2E fix |
| Localhost E2E — single shard | Shard name + Playwright artifact | **Remedial PR** — one root cause |
| Localhost E2E — Nav v2 cluster | Multiple shards, same sprint | Batch remedial; note integration branch |
| Flutter build | Compile log | **Remedial PR** — should be PR CI gap |
| Migrations pending | `migrate_pending_count` | Escalate if `UAT_AUTO_MIGRATE` off |

When `payload.gates.escalate` is true → comment on coordination issue + linked PR; **stop** without weakening gates.

### 2. Remedial PR (code failures only)

- Branch: `cursor/uat-fix-<pr>-2b0b`
- Body: `Refs #<linked-issue>` + failed run URL + gate table
- One PR per failure **burst** when root cause is shared
- Run `./scripts/pre-push-changed.sh`; use `/babysit-plus` with `merge_mode: auto` when CI green

**Forbidden:** weaken gates, disable shards, skip prod-ready checks, merge with red CI.

### 3. After remedial merge

```bash
node scripts/uat_queue_runtime.js set-barrier --sha <remedial_merge_sha> --reason "uat fix pr-<n>" --write
node scripts/uat_queue_runtime.js release-watcher --write
```

Comment on coordination issue: barrier advanced (`set-barrier` also clears promote hold).

### 4. Escalation (halt)

Per `uat-coordinator-plan.md` §9: WAF whitelist unavailable, pending migrations with `UAT_AUTO_MIGRATE` off, SSH deploy proofs missing, security/crypto, breaking API.

Post on coordination issue with `question` label on linked product issue if applicable.

---

## Recovery

If dispatch was skipped (`watcher_lease_held`, `remedial_in_progress`):

- Wait for lease expiry, or
- `workflow_dispatch` on **UAT coordinator dispatch** with `workflow_run_id` + `force: true` (human only)

---

## Related

| Skill | When |
|-------|------|
| `/babysit-plus` | Remedial PR hygiene and merge |
| `/pre-push-verify` | Before push on remedial PR |

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
| HTTP smoke — WAF body | `WAF challenge` / `o2switch` in logs | **Infra** — retry deploy / tune Tiger Protect in cPanel; **never** request CI IP whitelist |
| HTTP smoke — Passenger/404 | `uat-post-deploy-smoke.sh` hints | Infra / cPanel — check Passenger, not code PR |
| Live E2E — `#/landing` stall | HTTP smoke / WAF on same run | Check WAF cookie persistence + probe path; remedial PR only for real auth/E2E drift |
| Localhost E2E — single shard | Shard name + Playwright artifact | **Remedial PR** — one root cause |
| Localhost E2E — Nav v2 cluster | Multiple shards, same sprint | Batch remedial; note integration branch |
| Flutter build | Compile log | **Remedial PR** — should be PR CI gap |
| Migrations pending | `migrate_pending_count` | Escalate if `UAT_AUTO_MIGRATE` off |

**HTTP WAF constraint:** GitHub Actions egress **cannot** be IP-whitelisted on UAT. Do not open remedial PRs for pure WAF rate-limits; fix client/workflow mitigations (`passHostingWaf`, storage state, `run-live-uat-gate.sh` retry). Escalate only for cPanel Tiger Protect sensitivity or non-WAF host misconfig.

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

Per `uat-coordinator-plan.md` §Escalation: pending migrations with `UAT_AUTO_MIGRATE` off, SSH deploy proofs missing, security/crypto, breaking API.

**Never escalate for:** GitHub Actions HTTP WAF IP whitelisting — it is not available. Use workflow retry, Tiger Protect cPanel tuning, and code mitigations in `docs/e2e/uat-waf-queue-lessons.md`.

---

## Recovery

If dispatch was skipped (`watcher_lease_held`, `remedial_in_progress`):

- `uat-queue-health.yml` (weekly + manual dispatch) clears stale watcher leases and re-dispatches the coordinator for a stuck `failed` head entry.
- Or wait for lease expiry, or
- `workflow_dispatch` on **UAT coordinator dispatch** with `workflow_run_id` + `force: true` (human only)

---

## Related

| Skill | When |
|-------|------|
| `/babysit-plus` | Remedial PR hygiene and merge |
| `/pre-push-verify` | Before push on remedial PR |

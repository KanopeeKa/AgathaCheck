---
title: Execute-plan v2 — data contracts
owner: Kanopee
audience: agent
status: active
last_updated: 2026-11-02
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — data contracts

Part of [execute-plan-v2.md](../execute-plan-v2.md). Normative for every work package. The
decision logic that consumes these contracts is in [state-machine.md](./state-machine.md).

## 3.1 Snapshot v2 (`.agents/plans/<plan_id>.snapshot.json`)

Every field is immutable after approval. There are **no runtime fields**: progress is derived from
GitHub (state-machine §4). This exact object is the worked example of the hash vector in §3.4.

```json
{
  "schema_version": 2,
  "plan_id": "proof-build-label-7f3a",
  "title": "Proof run: UAT build label",
  "plan_file": ".agents/plans/proof-build-label-7f3a.md",
  "plan_file_sha256": "3b1f0d7c1a4e2f9b8c6d5e4f3a2b1c0d9e8f7a6b5c4d3e2f1a0b9c8d7e6f5a4b",
  "release_branch": "main",
  "integration_branch": "cursor/proof-build-label-7f3a-integration-7f3a",
  "control_issue": 1900,
  "created_at": "2026-10-16T09:00:00Z",
  "approved_until": "2026-10-23T09:00:00Z",
  "settings": {
    "release_owner_review": false,
    "tier3_blocking": false,
    "budgets": { "ci_per_phase": 8, "launches_per_phase": 15, "remedial_rounds": 6, "sync_attempts": 5, "daily_launches": 80 }
  },
  "protected_paths_version": 1,
  "phases": [
    { "id": "1", "title": "Server build label", "branch": "cursor/proof-build-label-7f3a-p1",
      "allowed_paths": ["server/bin/server.js", "server/test/healthProofLabel.test.js"],
      "forbidden_paths": [], "allowed_exceptions": ["tests"], "companions": [],
      "exit_checklist": ["health test green"] },
    { "id": "2", "title": "Docs note", "branch": "cursor/proof-build-label-7f3a-p2",
      "allowed_paths": ["docs/e2e/uat-deploy-tiers.md"],
      "forbidden_paths": [], "allowed_exceptions": ["docs"], "companions": [],
      "exit_checklist": ["docs gate green"] }
  ],
  "approval_hash": "sha256:fdaabc2824a1c11fc508b1425b7ab18ab5d0abd639794298535fcf43845b1e53"
}
```

| Field | Rule |
|-------|------|
| `schema_version` | `2`. Files with no `schema_version` or `1` go to the v1 code paths, unchanged. |
| `plan_id` | `^[a-z0-9][a-z0-9-]{2,48}$`; equals the file stem. |
| `plan_file`, `plan_file_sha256` | Path and SHA-256 (lowercase hex) of the plan markdown bytes at `init`. Covered by the hash (B4). The value above is illustrative; only the hash vector in §3.4 is normative. |
| `release_branch` | Always `"main"`. (Renamed from v1 `base_branch`, whose v1 validation rules do not apply to v2.) |
| `integration_branch` | `^cursor/<plan_id>-integration-[a-z0-9]{4}$`, so `ci.yml:10-13` and the integration ruleset apply. |
| `control_issue` | Issue number created by `init` before the hash is computed. |
| `created_at` | ISO-8601 UTC, set by `init`. |
| `approved_until` | `created_at + window_days`; window ≤ 14 days (cap in code). Must equal the `until` of the **approve** comment (§3.3). |
| `settings.budgets.*` | Integers ≥ 1, each ≤ the cap in `V2_CAPS` (`scripts/lib/execute_plan_constants.js`); validation rejects higher values. |
| `protected_paths_version` | Informational. The scope check always uses the protected set from `main`. |
| `phases[]` | 1–8 entries, ordered; one PR each. `id` = `"1"`, `"2"`, …; `branch` = `cursor/<plan_id>-p<id>`; `allowed_paths` non-empty globs; `allowed_exceptions` ⊆ `{"tests","docs"}`; `companions` ≤ 5 globs; `exit_checklist` non-empty strings. |
| `approval_hash` | §3.4. The only field excluded from its own input. |

Globs: `**` matches any number of path segments, `*` matches within one segment. Reuse
`globToRegExp` from `scripts/lib/execute_plan_schema.js:72` (it already implements this).

## 3.2 Plan file (`.agents/plans/<plan_id>.md`)

Human-readable scope that workers follow. Exact layout (headings in this order):

````markdown
# <title>

## Goal
<one paragraph>

## Phases

### Phase 1 — <phase title>
```json
{ "allowed_paths": ["…"], "forbidden_paths": [], "allowed_exceptions": ["tests"],
  "companions": [], "exit_checklist": ["…"] }
```
Scope: <what to build>
Out of scope: <what not to touch>

### Phase 2 — <phase title>
…

## Proof on UAT
<how the result is observed on https://uat.agathatrack.com>
````

Rules: the scope block is **JSON** (parsed with `JSON.parse`; no YAML, no dependency). The
heading separator is an em dash `—` (U+2014) surrounded by single spaces. The file must not
contain a heading named `Contract`, `Rules` or `Process` at any level (process rules belong in
code, not plans). Immutable after approval: the scope check treats any change as `drift` (§4.3).

## 3.3 Control-issue comments (approve, resume, revoke)

All three are one-line comments on the control issue. Body after `trim()`:

```
APPROVE_RE = ^approve-autonomous (?<plan>[a-z0-9][a-z0-9-]{2,48}) sha256:(?<hash>[0-9a-f]{64}) until (?<until>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)$
RESUME_RE  = ^resume-autonomous (?<plan>[a-z0-9][a-z0-9-]{2,48}) sha256:(?<hash>[0-9a-f]{64}) until (?<until>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z)$
REVOKE_RE  = ^revoke-autonomous (?<plan>[a-z0-9][a-z0-9-]{2,48})$
```

**Valid** (all must hold, checked by `validateControlComment`):
1. `comment.user.login` ∈ `config.owners` (§3.8) **and** `comment.author_association == "OWNER"`
   **and** `comment.user.login != config.bot_login`.
2. `comment.created_at == comment.updated_at` (never edited).
3. `plan` equals the snapshot `plan_id`; for approve/resume, `hash` equals `snapshot.approval_hash`.
4. Approve: `until == snapshot.approved_until`. Resume: `until ≤ comment.created_at + 14 days`.
5. `until > comment.created_at`.

**Authorizing comment** = the most recent valid approve **or** resume comment. Its `created_at` is
the **epoch**; its `until` is the **effective deadline**. Budgets count only events after the
epoch (state-machine §4.1). A resume never changes scope (same hash); it renews time and budgets.

**Revocation** is in force when label `autonomous-revoked` is present (anyone may add it) **or**
a valid revoke comment is newer than the epoch. **Escalation**: label `needs-owner` present
(added by `tick` on every STOP, or by a human). To resume after a STOP or revoke, the owner
removes `needs-owner` / `autonomous-revoked` and posts a resume comment (runbooks §7.5).

Labels written by the approve workflow: `autonomous-approved`, `plan:<plan_id>`.

## 3.4 `approval_hash`

```
input  = snapshot object with the key "approval_hash" removed
canon  = canonical(input)
hash   = "sha256:" + hex(SHA-256(UTF-8(canon)))
```

`canonical(v)`: arrays → `[` + elements joined by `,` + `]`; plain objects → `{` + entries sorted
by key (JavaScript default string sort), each `JSON.stringify(key) + ":" + canonical(value)`,
joined by `,` + `}`; every other value → `JSON.stringify(v)`. No whitespace.

Test vectors (`scripts/test/execute_plan_approval.test.js`, inline objects — not files):

| Input | `canonical` | Hash |
|-------|-------------|------|
| `{}` | `{}` | `sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a` |
| `{b:1,a:[true,null,"x"]}` | `{"a":[true,null,"x"],"b":1}` | `sha256:54a65415ad370228851a1da4b31b6fd42dc58b19a50d35cae759325f7388ce64` |
| §3.1 object minus `approval_hash` | 1136 bytes, starts `{"approved_until":"2026-10-23T09:00:00Z","control_issue":1900,` | `sha256:fdaabc2824a1c11fc508b1425b7ab18ab5d0abd639794298535fcf43845b1e53` |

## 3.5 Status comment (one per control issue, edited in place)

Body = marker line, then a fenced `json` block, then a human table. `tick` finds the comment by the
marker, creates it once (the approve workflow creates it first), and edits it afterwards. All
writes use the bot token (one identity, item 13). Valid example of the JSON block:

```json
{
  "schema": 1,
  "plan_id": "proof-build-label-7f3a",
  "init_sha": "0f1e2d3c4b5a69788796a5b4c3d2e1f00f1e2d3c",
  "state": "phase:implementing",
  "phase": "1",
  "lease": { "platform": "cursor", "agent_id": "bc-123", "run_id": "run-456", "launched_at": "2026-10-16T09:10:00Z", "last_tick_at": "2026-10-16T09:40:00Z" },
  "launches": [ { "at": "2026-10-16T09:10:00Z", "phase": "1", "kind": "implement", "agent_id": "bc-123", "run_id": "run-456" } ],
  "dispatched": { "preuat_heads": [], "deploy_tags": [] },
  "release": null,
  "uat": null,
  "stop": null,
  "updated_at": "2026-10-16T09:40:00Z"
}
```

| Field | Type | Written by | Meaning |
|-------|------|------------|---------|
| marker | `<!-- execute-plan-status:<plan_id> -->` | approve | First line of the comment body. |
| `init_sha` | string | approve | Commit holding the approved plan files (§3.1/§3.2). All readers load the snapshot here and re-verify the hash. |
| `state`, `phase` | string / string\|null | tick | Last decided state (state-machine §4.2). |
| `lease` | object\|null | driver (launch), worker tick (`last_tick_at`) | The live worker, if any. |
| `launches` | array, newest last, keep last 50 | driver | One entry per launch. |
| `dispatched.preuat_heads` | array of SHAs | driver | `main` heads for which Pre-UAT was dispatched (once per head). |
| `dispatched.deploy_tags` | array of tags | driver | Tags re-dispatched to Deploy UAT (once per tag). |
| `dispatched.scope_republish` | array of `{ sha, at }` (last 20; absent until first use) | driver | PR heads whose `execute-plan-scope` status the driver re-evaluated and republished; an entry counts only when `at` is after the epoch (state-machine PR-ladder 3b/10a). |
| `release` | `{ "pr": n, "merge_sha": s }`\|null | tick | Set when the release PR merges. |
| `uat` | `{ "preuat_run": id, "tag": s, "deploy_run": id, "tier3": "pending"\|"success"\|"failure" }`\|null | tick | Evidence so far. |
| `stop` | `{ "reason": s, "detail": s, "at": ISO }`\|null | tick | Last STOP; ignored when older than the epoch. |
| `updated_at` | ISO | tick | Last write. |

The human table below the JSON block has columns `Phase | Branch | PR | State | Failed attempts |
Launches`. Besides this comment, `tick` posts exactly one **log comment** per state change:
`execute-plan: <old state> → <new state> — <evidence url>`. Nothing else (R6).

## 3.6 Handoff prompt (every worker launch)

Built by `buildHandoffPrompt(decision, snapshot, planMarkdown)`; placeholders in `<>`:

```
/execute-plan <plan_id>

You are a worker for execute-plan <plan_id>. Do exactly the action below. Then run
`env -u OWNER_GH_TOKEN -u BOT_GH_TOKEN node scripts/execute_plan_runtime.js tick <plan_id> --json --actor agent` and continue with what
it returns, until it returns an action whose actor is "driver", or a stop. Then end your turn
with one line: "worker done: <state>".

Action: <kind> — <one-line description>
Branch: <branch>   Base: <base>   PR: <#n or none>   Phase: <id> "<title>"
Scope (allowed): <allowed_paths joined by ", ">   Companions: <companions or none>
Forbidden: the protected set (scripts/lib/execute_plan_scope.js) + <forbidden_paths or none>
Evidence: <failing check names / unresolved thread urls / conflict files / failing shards>
Plan file: .agents/plans/<plan_id>.md (read it first; never edit it or the snapshot)

Rules: if no PR exists, open a draft PR into <base> right after your first commit. Run
./scripts/pre-push-changed.sh before every push and push only when it is green (one push per batch of
fixes: every push costs a full CI run and counts as an attempt against the phase budget); mark the PR
ready only after it is green; never touch protected paths; never approve, label, merge or close
anything; never edit the control issue yourself.
If a failing check cannot be fixed inside your scope (it needs a protected path, a CI gate or another
budget file; the web bundle budget below is the exception), do not work around it and do not retry: describe the cause in the PR description and end your
turn with "worker done: blocked <check>: <reason>".

Web bundle budget (scripts/ci/web-bundle-budget.json): when only check-web-bundle-budget fails and the
overshoot comes from this phase's planned code (no new package or asset), raise the cap in this PR to
the measured size plus about 1% and give before/after bytes in the PR body. Never cut planned scope to
fit. A jump over about 1.5% of main.dart.js, or one you cannot explain, gets one trimming attempt
(deferred import, drop the asset); if it is still over, report it as blocked with the numbers.
```

## 3.7 `tick` output (`--json`) and actions

```json
{ "schema": 1, "plan_id": "proof-build-label-7f3a", "state": "phase:ready", "phase": "1",
  "action": { "actor": "driver", "kind": "arm-auto-merge", "launch": false, "args": { "pr": 1950, "method": "squash" } },
  "stop": null,
  "evidence": [ { "label": "phase 1 PR", "url": "https://github.com/KanopeeKa/AgathaCheck/pull/1950" } ],
  "budgets": { "failed_attempts": { "1": 0 }, "launches_phase": { "1": 1 }, "launches_today": 1, "sync_resolves": 0, "remedial_rounds": 0 } }
```

Exit codes: `0` action (including `wait`) or complete; `2` stop; `3` config/approval error that
prevents a decision (missing config, snapshot not found at `init_sha`). `action` is always
non-null except in state `complete`; on a stop, `action.kind` is `enforce-stop`.

| Actor | Kind | Args | Meaning |
|-------|------|------|---------|
| agent | `implement` | phase, branch, base, pr? | Build the phase on its branch; draft PR first. |
| agent | `fix-ci` | pr, branch, failing (check names) | Make the failing required checks green. |
| agent | `fix-scope` | pr, branch, violations `[{file, reason}]` | Remove out-of-scope files; a file the phase truly needs is left out, named in the PR description and reported as `worker done: blocked execute-plan-scope: <file>` so the owner lands it as a plan-linked side PR (runbooks §7.5). |
| agent | `triage-review` | pr, branch, threads (urls) | Address and resolve review threads. |
| agent | `resolve-conflict` | pr, branch, base | Merge the base into the branch and fix conflicts. |
| agent | `resolve-sync` | sync_pr, branch `cursor/<id>-sync-<n>` | Merge `main` into a new branch off integration, fix conflicts, PR into integration. |
| agent | `remedial` | branch `cursor/<id>-remedial-<n>`, failing (shards or `deploy-smoke`), evidence urls | Fix the UAT failure; PR into `main`. |
| driver | `create-phase-branch` | phase, branch, from_sha (integration head) | Create the phase branch before the first launch. |
| driver | `arm-auto-merge` | pr, method (`squash` / `merge` for sync PRs), head_sha, scope_republished | Enable auto-merge; if GitHub answers that the PR is already clean, merge it directly (same refusal handling as `merge`). |
| driver | `merge` | pr, method, head_sha, scope_republished | Merge directly after an auto-merge stall. A 405 naming an uncounted `execute-plan-scope` (`is expected` / `was not set by the expected GitHub app`) with `scope_republished: false` → run `republish-scope` instead; any other uncounted required check, or a second refusal → STOP `check-missing`; any other refusal → STOP `merge-blocked`. Both stops add `needs-owner` and are enforced on that PR in the same pass (auto-merge disabled, `plan-stopped` published), since an armed auto-merge would otherwise merge once the check appears. |
| driver | `republish-scope` | pr, head_sha | Re-run the scope evaluation from trusted `main` code and post the `execute-plan-scope` status with `GITHUB_TOKEN` through `publishScopeResult` (a green result is re-checked against STOP first); record the head in `dispatched.scope_republish`. No-op when the head moved. |
| driver | `update-branch` | pr | PR is behind a strict base. |
| driver | `open-sync-pr` | head `main`, base integration | Integration is behind `main` before the release. |
| driver | `open-release-pr` | head integration, base `main` | All phases merged and integration not behind. |
| driver | `dispatch-preuat` | main_head_sha | Dispatch `pre-uat-e2e.yml` on `main`, once per head. |
| driver | `dispatch-deploy` | tag | Re-dispatch `deploy-uat.yml` with `deploy_ref`, once per tag. |
| driver | `enforce-stop` | prs (open plan PRs) | Disable auto-merge, set scope check `failure` (`plan-stopped`) on each head, add `needs-owner`, write `stop`. Idempotent. |
| driver | `complete-plan` | evidence | Run `verifyComplete`; if true, final status, log comment, label `plan:complete`, close the issue. |
| driver | `wait` | reason (`agent-alive`, `checks`, `copilot`, `owner-review`, `preuat`, `preuat-dispatched`, `promote`, `deploy`, `main-green`, `tier3`, `daily-cap`) | Nothing to do now. |

`launch: true` appears only on agent actions decided for the driver when no live worker holds the
lease (state-machine §4.1 L-rules).

## 3.8 Config file (`.github/execute-plan.config.json`, read from `main`)

```json
{
  "owners": ["KanopeeKa"],
  "bot_login": "pawpet-bot",
  "cursor_model_implement": "<model id from the policy below>",
  "cursor_model_fix": "<model id from the policy below>",
  "required_checks": {
    "integration": ["ci-gate / CI passed", "execute-plan-scope"],
    "main": ["Analyze JavaScript", "ci-gate / CI passed", "execute-plan-scope"]
  },
  "uat": {
    "preuat_workflow": "pre-uat-e2e.yml",
    "preuat_gate_job": "Pre-UAT E2E gate",
    "promote_workflow": "promote-uat.yml",
    "deploy_workflow": "deploy-uat.yml",
    "deploy_proof_job": "Prod ready",
    "deploy_job": "Build and deploy to UAT",
    "smoke_job": "UAT post-deploy smoke",
    "tier3_workflow": "uat-live-e2e.yml",
    "tag_pattern": "^uat-(\\d{6})-(\\d+)$"
  }
}
```

`bot_login` is the machine-user login chosen in Phase 0 (`pawpet-bot`). `cursor_model_*` = the
model id that `docs/agent-efficiency/pr-review-cost-efficiency.md` §Cloud Agent model policy names
for implementation and babysit work (WP7a copies it from there; both keys get the same value today). Job names are the live
names in `deploy-uat.yml` / `pre-uat-e2e.yml` (verified 2026-10-15); code never hard-codes them.
Tags look like `uat-261014-1892` (`uat-YYMMDD-<PR number>`, annotated, created by
`scripts/ci/promote-uat-tag.sh:48`).

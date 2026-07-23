---
name: execute-plan
description: Multi-phase autonomous orchestrator — runs frozen plan snapshots phase-by-phase, gates on merge-done, delegates PR hygiene to /babysit-plus (default merge mode auto). Use after approve-autonomous or to resume a halted plan.
---

# Execute-plan

Multi-phase autonomous orchestrator. Drives work from a **frozen snapshot** (`.agents/plans/<plan_id>.snapshot.json`) and live plan (`.agents/plans/<plan_id>.md`), one phase at a time.

**Canonical policy (do not restate here):**

- [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md) — triage, debt issues, merge modes, halt/resume
- [execute-plan-schema.md](../../docs/agent-efficiency/execute-plan-schema.md) — snapshot fields, drift, status model
- [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md) — CLI commands
- [phase-exit-checklists.md](../../docs/agent-efficiency/phase-exit-checklists.md) — per-phase exit profiles
- [github-labels.md](../../docs/agent-efficiency/github-labels.md) — control issue + debt labels
- [plan-template.md](../../docs/agent-efficiency/plan-template.md) — authoring template

**PR hygiene:** Always delegate to **/babysit-plus**, never plain `/babysit` alone.

**Default merge mode:** When triggering `/execute-plan`, use **babysit-plus with `auto` merge** unless the frozen snapshot sets `default_merge_mode` or a per-phase `merge_mode` override. Effective mode per phase:

```
effective_merge_mode = phase.merge_mode ?? snapshot.default_merge_mode ?? auto
```

---

## Invocation

| Command | When |
|---------|------|
| `/execute-plan <plan_id>` | Start or continue an approved plan from `current_phase` |
| `/execute-plan <plan_id> resume` | After human removed `autonomous-revoked` and commented `resume-plan <plan_id>` |

Do **not** invoke `/execute-plan example-plan` — `_example` is documentation-only.

---

## Inputs

| Input | Required | Notes |
|-------|----------|-------|
| `plan_id` | yes | Matches `.agents/plans/<plan_id>.{md,snapshot.json}` |
| Frozen snapshot | yes | Validated, `autonomy: active`, `approved_until` in future |
| Control issue | yes | Labels: `execute-plan`, `plan:<id>`, `autonomous-approved`; not `autonomous-revoked` |
| Human approval | yes (first run) | Keyword `approve-autonomous <plan_id>` on control issue |

---

## Before autonomy grant (human + agent sanity check)

Run when drafting a plan, **before** `approve-autonomous`:

1. Copy [plan-template.md](../../docs/agent-efficiency/plan-template.md) → `.agents/plans/<plan_id>.md`
2. Author snapshot JSON; set **`default_merge_mode: auto`** unless human chose `manual` or `labeled`
3. Validate: `node scripts/validate_execute_plan_snapshot.js .agents/plans/<plan_id>.snapshot.json`
4. Bootstrap control issue:
   ```bash
   node scripts/execute_plan_runtime.js init-control-issue <plan_id>
   ```
   Create issue via rendered `gh issue create` command; set `control_issue` in snapshot; re-validate.
   **Project status:** new control issues enter **Backlog** (default when added to the project board).
5. Sanity check (plan-template §Sanity check expectations): `proceed` \| `proceed-high-risk` \| `reject`
6. Human comments `approve-autonomous <plan_id>`; freeze snapshot (`content_hash` must not change after approval)

`approved_until` = `approved_at + 48 hours` (mandatory).

---

## Session preflight (every run)

1. `git fetch origin main`
2. Load snapshot from artifact branch (default `phase-branch` policy) or `main` per `artifact_branch_policy`
3. **Gate:**
   ```bash
   node scripts/execute_plan_runtime.js gate <plan_id> \
     --labels execute-plan,plan:<plan_id>,autonomous-approved
   ```
   Exit `2` → halt; do not start work
4. **Resume** (when subcommand `resume` or after halt):
   ```bash
   node scripts/execute_plan_runtime.js resume-check <plan_id> \
     --phase <id> --pr-head <sha> --labels autonomous-approved
   ```
   `resume_mismatch` → halt unless human commented `accept-head` on control issue
5. **Current phase:**
   ```bash
   node scripts/execute_plan_runtime.js current-phase <plan_id>
   ```
6. Rebase phase branch on `origin/<base_branch>` (or integration parent when spawn phase)
7. **Project status — In Progress** (control issue; every session after gate passes):
   ```bash
   node scripts/execute_plan_runtime.js set-project-status <plan_id> --status "In Progress"
   ```
   Distinguishes active plan work from backlog. Skip only if already **In Progress**. Requires `GH_PROJECTS_PAT`, `GH_PROJECT_ID`, `GH_STATUS_FIELD_ID` (see `docs/github-issue-workflow.md`); when unset, CLI prints `skipped` — use `node scripts/github_issue_workflow.js set-status --issue <n> --status "In Progress"` after configuring secrets, or move manually on the board.
8. **Control issue session comment** — post what you are starting (phase id, branch, PR if any):
   ```bash
   gh issue comment <control_issue> --body "## Session start
   - phase: <id> — <title>
   - branch: <branch>
   - next: implement | babysit+ | resume"
   ```
   Or: `node scripts/github_issue_workflow.js comment --issue <n> --body "..."`

---

## Issue hygiene (mandatory)

The **control issue** is the human dashboard for plan status. Keep it current.

| When | Action |
|------|--------|
| Work starts (session preflight) | **In Progress** (`set-project-status`) + session-start comment |
| Phase milestone (PR opened, CI green, merged) | Short comment on control issue |
| **Pause** (UAT remedial, waiting on you) | `pause --write --post-comment` — state checkpoint + what you need |
| **Halt** (revoke, escalation, CI exhausted) | `halt --write --post-comment` — state reason + resume steps |
| **Question for human** (blocks work) | Comment on control issue with `**Needs you:**` + halt if execute-plan cannot continue |
| All phases merged | `complete-plan <plan_id> --write` → **Done** + close with summary comment |

Debt issues created during babysit+ stay **Backlog** until picked up. When you **start work** on any issue (debt or otherwise), move it to **In Progress** and comment what you are doing:

```bash
node scripts/github_issue_workflow.js start-work --issue <n> --body "Starting remedial fix for …"
```

---

## Phase loop

Repeat until all phases `merged` or autonomy halts.

### 1. Select phase

- First `pending` phase after last `merged`, or resume from `next_action` in live plan
- Skip phases already `merged` — never redo merged work
- Checkout `phase.branch`; create branch if missing

### 2. Mark in progress

```bash
node scripts/execute_plan_runtime.js set-phase <plan_id> \
  --phase <id> --status in_progress --write
node scripts/execute_plan_runtime.js sync-runtime <plan_id> --write
```

Commit plan artifacts on the phase branch (`artifact_branch_policy: phase-branch`).

### 3. Implement scope

- Stay within `allowed_paths`; respect `forbidden_paths`
- Out-of-path files only with mapped `allowed_exceptions` (see execute-plan-schema §Drift)
- Commit messages: `phase(<id>/<total>): <type>: <description> [exception:<code>]`
- Run `./scripts/pre-push-changed.sh` after each logical batch
- On drift → `halt --reason drift` (see §Halt)

**Spawn:** When `spawn_allowed: true`, invoke **/spawn-sprint-agents** per `spawn_config` before parallel work. Publish ownership map first.

### 4. Open or update PR

- Target `base_branch` from snapshot (or integration branch for spawn phases)
- Register PR URL + head SHA:
  ```bash
  node scripts/execute_plan_runtime.js set-phase <plan_id> \
    --phase <id> --status in_progress --pr-url <url> --pr-head <sha> --write
  node scripts/execute_plan_runtime.js sync-runtime <plan_id> --write
  ```
- Push plan artifact commits to phase branch before babysit-plus

### 5. Babysit+ through merge; spawn UAT sub-agent (mandatory)

**Main agent** invokes **/babysit-plus** §0–7 for the phase PR (sync → triage → fixes → debt issues → CI → exit checklist → **merge** per effective mode).

| Parameter | Value |
|-----------|-------|
| PR URL / branch | phase PR |
| `plan_id` | current plan |
| Phase snapshot | current phase object |
| `approved_until` | from snapshot |
| **Effective `merge_mode`** | `phase.merge_mode ?? snapshot.default_merge_mode ?? auto` |

**After merge is verified** (PR `MERGED`, merge commit on base), **main agent** spawns the **UAT babysit sub-agent** (babysit-plus §8a) — a background Task that owns §8b until **Prod ready** is green or triggers a pause. **Do not wait** for UAT/prod-ready before completing the phase or starting the next one.

```text
Main agent                          UAT babysit sub-agent (background)
──────────                          ─────────────────────────────────
babysit+ §0–7 → merge ─────────────► spawn after merge SHA known
complete phase §6                   poll promote-uat → deploy-uat → prod-ready
start next phase §7                 on failure: pause main + remedial loop
                                    on success: comment + exit (no interrupt)
```

**Phase gate = merge-done** — do not advance until:

- PR `state == MERGED`
- `merge_commit` recorded
- `git merge-base --is-ancestor <merge_commit> origin/<base_branch>`

```bash
gh pr view <url> --json state,mergedAt,mergeCommit,baseRefName
git fetch origin <base_branch>
git merge-base --is-ancestor <mergeCommit.oid> origin/<base_branch>
```

**UAT prod-ready is not a phase gate.** The §8 sub-agent watches deploy in parallel; on failure it **pauses** main work (`uat_paused`) and auto-resumes when remedial prod-ready is green. Do not wait for prod-ready before starting the next phase.

### 6. Complete phase

```bash
node scripts/execute_plan_runtime.js set-phase <plan_id> \
  --phase <id> --status merged --pr-url <url> --pr-head <sha> --write
```

Update snapshot `merge_commit` via runtime (`set-phase` + `saveSnapshot`). Sync live plan; comment phase summary on control issue.

### 7. Next phase (parallel with UAT babysit)

If more `pending` phases → loop to §1 **immediately** — any in-flight UAT babysit sub-agents from prior merges continue in the background per babysit-plus §8.

If all `merged` → **complete plan** (snapshot + project board + close control issue):

```bash
node scripts/execute_plan_runtime.js complete-plan <plan_id> --write
```

This sets `autonomy: completed`, syncs runtime, moves the control issue to **Done**, and closes it with a summary comment. Use `--skip-close` only for dry-run inspection. If `gh issue close` fails, post the rendered `comment` manually on the control issue.

---

## Halt (graceful shutdown)

Stop immediately on: revoke label, past `approved_until`, escalation, drift, CI budget exhausted, debt issue create failure, merge failure, or session limit.

**UAT prod-ready failure** → pause (`uat_paused`) via §8 sub-agent; auto-resume when remedial prod-ready is green — not a halt trigger.

```bash
node scripts/execute_plan_runtime.js halt <plan_id> \
  --reason <status_reason> --detail "<checkpoint>" --write --post-comment
node scripts/execute_plan_runtime.js render-halt-comment <plan_id> \
  --reason <status_reason> --detail "<checkpoint>"
```

1. Finish safe atomic step only; **do not merge** if revoke detected pre-merge
2. Post halt comment on control issue (and open PRs) — prefer `--post-comment` on `halt`
3. Push plan artifact to phase branch
4. **Halt only** — do not close PRs, delete branches, or revert merged commits
5. On revoke: human adds `autonomous-revoked` on control issue; optional `do-not-merge` on open PRs

---

## Resume

1. Human removes `autonomous-revoked`; comments `resume-plan <plan_id>`
2. `/execute-plan <plan_id> resume`
3. `resume-check` (gate + `pr_head_sha` match or `accept-head`)
4. Continue from `next_action`; do not redo `merged` phases
5. Plan changes after approval → new snapshot + `approve-autonomous` again

---

## Escalation (always halt)

See autonomous-pr-policy §Escalation. Includes security/crypto, breaking API, prod migrations, CI workflow changes, product/legal, drift, CI exhausted, issue tracking failed.

---

## Related skills

| Skill | When |
|-------|------|
| `/babysit-plus` | **Every phase PR** — triage, debt, CI, merge (default mode `auto`) |
| `/pre-push-verify` | Before every push; full suite before merge |
| `/spawn-sprint-agents` | Phase with `spawn_allowed: true` |
| `/single-backend-route-change` | Route phases per exit checklist |
| `/split-flutter-screen` | Screen-split phases per exit checklist |

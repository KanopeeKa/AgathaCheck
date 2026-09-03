---
name: execute-plan
description: >-
  Multi-phase autonomous orchestrator — runs frozen plan snapshots phase-by-phase,
  gates on merge-done, delegates PR hygiene to /babysit-plus (default merge mode auto).
  Post-merge UAT is CI-owned (pre-uat-e2e) — main session never polls deploy.
  May spawn Task sub-agents per phase for implementation; use integration branch for 2+ phases.
---

# Execute-plan

Multi-phase autonomous orchestrator. Drives work from a **frozen snapshot** (`.agents/plans/<plan_id>.snapshot.json`) and live plan (`.agents/plans/<plan_id>.md`), one phase at a time.

**Memory:** [.agents/memory/execute-plan-autonomy.md](../../../.agents/memory/execute-plan-autonomy.md)

## Autonomy contract

When session preflight **gate** exits `0`, autonomy is **active**. You have upfront approval — **do not ask the human for permission** to implement, open/update PRs, babysit+, merge (`auto`), advance phases, or resume after a routine checkpoint.

| Do | Do not |
|----|--------|
| Run gate every session; treat exit `0` as green light | Ask "shall I continue?" or "want me to proceed?" in user chat |
| Post milestones on the **control issue** | Use user chat for permission-seeking mid-flow |
| Loop to the next phase immediately after merge-done | Wait for prod-ready UAT before the next phase |
| When a standing grant covers a multi-plan roadmap, auto-bootstrap the next `plan_id` and keep looping (see §Roadmap chaining) | End a turn with a soft offer ("let me know", "whenever you want", "say which wave and I'll bootstrap") for scope already granted |
| Halt only on §Halt / §Escalation list | Pause for non-blocking follow-ups or turn boundaries |

**Anti-pattern (soft-stop):** phrases like "I can spin up the next plan on request," "whenever you want to keep going," or "say which wave and I'll bootstrap it" are permission-seeking even though they don't look like a question. If the human's chat authorization already names the remaining scope (multiple journeys/waves, "all phases," "the entire plan/roadmap"), treat that as the standing grant for every plan it covers — do not re-ask per slice.

**User chat (status + blocker alerts):** brief progress + what's next on routine turns. When you **need the human** (halt, `**Needs you:**`, escalation, `session_limit`), post full detail on the **control issue** first, then a **short chat alert** with the issue link and the one action that unblocks you — chat is where they'll see it first; the issue is the canonical record. Non-blocking follow-ups may be bundled at end of turn — never as a flow break. See §Scope follow-ups and §Issue hygiene.

**Handoff (chat → autonomous):** Discuss and shape the plan in chat; freeze snapshot + control issue; human grants once (`approve-autonomous <plan_id>` or standing grant in `approved_by`). After `/execute-plan` gate exit `0`, **full handover** — no permission prompts for implement, PR, babysit+, merge, or next phase.

**Human checkpoint (no manual merge):** use `halt` on the control issue + chat alert; human acts on the issue (`resume-plan`, `approve-autonomous`, etc.) — agents always merge when gates pass.

**Conflicting rules:** execute-plan snapshot wins over generic "stop and ask" guidance. Only halt when the **goal is unclear**, or §Escalation applies. Minor policy wording conflicts with clear intent → proceed. See autonomous-pr-policy §Execute-plan overrides.

---

**Canonical policy (do not restate here):**

- [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md) — triage, debt issues, merge modes, halt/resume
- [execute-plan-schema.md](../../docs/agent-efficiency/execute-plan-schema.md) — snapshot fields, drift, status model
- [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md) — CLI commands
- [phase-exit-checklists.md](../../docs/agent-efficiency/phase-exit-checklists.md) — per-phase exit profiles
- [github-labels.md](../../docs/agent-efficiency/github-labels.md) — control issue + debt labels
- [plan-template.md](../../docs/agent-efficiency/plan-template.md) — authoring template

**PR hygiene:** Delegate to **/babysit-plus** for intermediate phase PRs and **/babysit-uat** for the **final PR to `main`**. Never plain `/babysit` alone. Orchestrator babysit steps use **`composer-2.5` only**. Workers must complete **pre-PR critical self-review** before opening/updating a PR (`docs/agent-efficiency/pr-review-cost-efficiency.md`).

**Merge:** Always squash-merge when gates pass (no `manual` / `labeled` modes).

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
| Human approval | yes (first run) | Keyword `approve-autonomous <plan_id>` on control issue — **except** self-bootstrapped roadmap-chain plans, see §Roadmap chaining |

---

## Before autonomy grant (human + agent sanity check)

Run when drafting a plan, **before** `approve-autonomous`:

1. Copy [plan-template.md](../../docs/agent-efficiency/plan-template.md) → `.agents/plans/<plan_id>.md`
2. Author snapshot JSON; set **`default_merge_mode: auto`** (only valid value)
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

   **Gate exit `0` = proceed without asking the human.** This is the authoritative green light for the session.
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
7. **Control issue session comment** — post what you are starting (phase id, branch, PR if any). Add `busy` on first session:
   ```bash
   node scripts/github_issue_workflow.js start-work --issue <control_issue> --body "## Session start
   - phase: <id> — <title>
   - branch: <branch>
   - next: implement | babysit+ | resume"
   ```

   **Do not** attempt GitHub Project board status updates — Cloud Agents cannot write Projects. Comments + `busy` are the agent-visible signal; you move board columns manually if needed.

8. **Session limit check** — if this plan has run continuously for **~24 hours** (or the pod is near timeout), finish the current safe atomic step, then `halt --reason session_limit` with `next_action` recorded. Post on control issue + short chat alert (issue link, `resume-plan <plan_id>`). Do **not** ask for permission in chat.

---

## Cloud session continuity (turn boundaries)

Cloud agents end each **turn** when you respond. That is normal — it is **not** a phase boundary and **not** permission to stop the plan.

| At turn end | Do | Do not |
|-------------|-----|--------|
| Phase still `in_progress` | Commit, push, update PR + plan artifacts; post milestone on control issue; end user chat with brief status + explicit `next_action` (e.g. "next: babysit+ merge phase 2") | Ask "shall I continue?", "want me to proceed?", or soft offers ("let me know", "whenever you want") |
| Phase just merged, more `pending` | Immediately start next phase in the **same session** when context/time allows; otherwise record `next_action` on control issue and exit with status only | Treat merge as session complete |
| Waiting on CI / pre-UAT watch | `gh pr checks --watch` (phase PR CI) or `./scripts/babysit_uat_watch_preuat.sh <merge_sha>` (final main merge); resume when green — do not ask the human to nudge CI | Poll deploy-uat or prod-ready |
| Queued follow-up messages exist | Keep working through the queue in this session | Stop after one phase because the turn ended |

**Standing grant:** If the human authorized the full plan/roadmap once (`approve-autonomous`, or chat grant recorded in `approved_by`), you do **not** need a new approval per phase, per turn, or per PR.

**Gate exit `2`:** Halt via control issue (`halt --write --post-comment`) with resume steps, plus a short chat alert (issue #, reason, unblock action). Common codes: `expired` (`approved_until` past — re-approve on control issue), `revoked`, `not_approved`.

---

## Multi-phase integration branch (recommended)

For plans with **2+ phases** (especially UI or the same product area), batch merges to `main`:

1. At plan start, create `cursor/<plan-id>-integration-<suffix>` from `main`.
2. Set snapshot `base_branch` to that integration branch.
3. Each phase PR targets `base_branch` (integration), not `main`.
4. After **all** phases are `merged` into integration, open **one** PR: integration → `main` (coordinator runs `./scripts/pre-push.sh`).

Single-phase or disjoint-domain plans may keep `base_branch: main`. See uat-coordinator-plan §Goals (integration branches for multi-phase UI sprints).

---

## Roadmap chaining (multi-plan grants)

A single `plan_id` stays small on purpose (tight `allowed_paths`, one reviewable slice). A **roadmap** — several journeys/waves the human describes in one chat message — spans **multiple** `plan_id`s. Do not let "plan complete" silently become "session complete" when the standing grant covers more than the plan that just finished.

**Trigger:** the human's authorization names scope beyond the current plan (e.g. "go ahead through the entire plan/roadmap," "all phases," "the full journey list," or explicitly invokes `/spawn-sprint-agents` for a wave you identified).

**On plan completion, if the standing grant still covers remaining scope:**

1. Do **not** end the turn with a soft offer. Draft the next slice's plan + snapshot immediately (§Before autonomy grant §1–3), reusing the standing grant as `approved_by` (reference the originating chat message/timestamp) instead of waiting for a fresh literal `approve-autonomous <plan_id>`.
2. Still bootstrap a real control issue with `execute-plan`, `plan:<id>`, `autonomous-approved` and run the gate — self-authorized plans keep the same auditability, just skip the round-trip for a keyword the human already gave in spirit.
3. Before slicing sequentially, re-check the roadmap for independent waves (disjoint `allowed_paths`, e.g. backend-only vs Flutter-only, or unrelated features). If the human named `/spawn-sprint-agents` or you identify such a wave yourself, set `spawn_allowed: true` and invoke **/spawn-sprint-agents** for that wave rather than defaulting to one plan at a time — sequential slicing when parallel was explicitly requested is itself a standing-grant violation.
4. Only fall back to a soft closer / control-issue `**Needs you:**` when: the roadmap is genuinely exhausted, the next slice needs a decision the grant didn't cover (e.g. new escalation-list item), or `approved_until` would be exceeded before it can be re-validated.

---

## Phase delegation (orchestrator vs workers)

The **orchestrator** (this session running `/execute-plan`) owns: gate, runtime sync, control-issue hygiene, babysit+, merge, and advancing phases.

### Per-phase implementation worker (recommended)

At each phase **§3 Implement scope**, the orchestrator **must** delegate implementation to a **Task sub-agent** (`generalPurpose`) when practical, scoped to that phase's `allowed_paths`, exit criteria, and branch — then verify diff, open/update PR, and run babysit+. Do not stop after the worker returns; continue through babysit+ and the next phase without asking the human.

| Role | Owns |
|------|------|
| **Orchestrator** | Gate, `set-phase`, PR registration, babysit skill selection, merge, next phase |
| **Phase worker** (Task sub-agent) | Implement one phase scope; commit on phase branch; return summary |

Spawn a **fresh worker at each phase boundary** (after prior phase `merged`). This limits context drift and mirrors "one agent per phase."

**Do not await** the worker for deploy — only for implementation return.

### Within-phase parallel (`spawn_allowed: true`)

Invoke **/spawn-sprint-agents** per `spawn_config` before parallel work. Publish ownership map first. Phase PR still goes through orchestrator babysit+.

### Post-merge pre-UAT

| PR target | Skill after CI-ready |
|-----------|----------------------|
| Integration / non-`main` base | **/babysit-plus** only — ends at merge |
| **`main`** (final plan PR) | **/babysit-uat** — pre-UAT E2E gate on merge SHA |

**Pre-UAT failure on final merge:** `/babysit-uat` delegates remedial work to **/e2e-debug** (diff since last green, parallel shard fixes on one remedial branch), then merges the remedial PR and re-watches. Do **not** inline remedial playbooks in execute-plan.

Do **not** poll `deploy-uat` or prod-ready. See [uat-deploy-tiers.md](../../../docs/e2e/uat-deploy-tiers.md), `/babysit-uat`, and `/e2e-debug`.

---

## Scope follow-ups (snags and debt)

During implementation, apply the snag ladder without breaking flow:

| Follow-up | Action |
|-----------|--------|
| Same file, ≤15 lines, stability / correctness / low-risk tech debt in touched code | Fix inline |
| In-scope but larger, or risky | Debt issue; continue phase |
| Out of phase `allowed_paths` | Debt issue or halt if drift |
| Interesting but non-blocking | Bundle as end-of-turn questions in user chat, **or** one `tech-debt` / `review-follow-up` issue — do not pause the phase |

Low-confidence **review triage** (must-fix vs ignore) is rare with tight phase scope. Prefer debt issue + continue; halt only when classification affects merge safety. See autonomous-pr-policy §Review triage (execute-plan override).

---

## Issue hygiene (mandatory)

The **control issue** is the canonical plan dashboard. **User chat** gets a short alert when you need the human (they see chat first).

| When | Control issue | User chat |
|------|---------------|-----------|
| Work starts (session preflight) | `start-work` comment + `busy` | Optional one-line "session start, phase N" |
| Phase milestone (PR opened, CI green, merged) | Short comment | Brief status + what's next (routine) |
| **Pause** (UAT remedial, waiting on you) | `pause --write --post-comment` — checkpoint + what you need | Short alert: issue link + what you need |
| **Halt** (revoke, escalation, CI exhausted, `session_limit`) | `halt --write --post-comment` — reason + resume steps | Short alert: issue link + unblock action (e.g. `resume-plan <plan_id>`) |
| **Question for human** (blocks work) | `**Needs you:**` comment; halt if cannot continue | Short alert: issue link + the decision or action required |
| All phases merged | `complete-plan <plan_id> --write` → close with summary | Brief "plan complete" + integration→main PR if any |

**Chat alert format (blockers only):** one short paragraph — plan id, control issue link (`#N`), reason, single unblock action. Full detail stays on the issue.

Debt issues created during babysit+ are deferred until picked up. When you **start work** on any issue, comment and add `busy`:

Debt issues created during babysit+ are deferred until picked up. When you **start work** on any issue, comment and add `busy`:

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
- **Delegate implementation** to a per-phase Task worker when practical (see §Phase delegation)

**Spawn (parallel within phase):** When `spawn_allowed: true`, invoke **/spawn-sprint-agents** per `spawn_config` before parallel work. Publish ownership map first.

### 4. Open or update PR

- Target `base_branch` from snapshot (or integration branch for spawn phases)
- Register PR URL + head SHA:
  ```bash
  node scripts/execute_plan_runtime.js set-phase <plan_id> \
    --phase <id> --status in_progress --pr-url <url> --pr-head <sha> --write
  node scripts/execute_plan_runtime.js sync-runtime <plan_id> --write
  ```
- Push plan artifact commits to phase branch before babysit-plus

### 5. Babysit through merge

**Final PR to `main`?** Use **/babysit-uat** (babysit+ merge + pre-UAT gate).  
**Intermediate phase PR** (integration or non-main base)? Use **/babysit-plus** only.

| Check | Skill |
|-------|-------|
| `baseRefName == main` **and** (last pending phase **or** integration→main batch PR) | `/babysit-uat` |
| Otherwise | `/babysit-plus` |

**Main agent** runs the selected skill through merge.

| Parameter | Value |
|-----------|-------|
| PR URL / branch | phase PR |
| `plan_id` | current plan |
| Phase snapshot | current phase object |
| `approved_until` | from snapshot |

**Phase gate = merge-done** — do not advance until:

- PR `state == MERGED`
- `merge_commit` recorded
- `git merge-base --is-ancestor <merge_commit> origin/<base_branch>`

For **babysit-uat** on final main merge, phase gate also requires **pre-UAT E2E green** for that `merge_commit` before `complete-plan`. If watch fails, run **/e2e-debug** (reactive) before remedial merge — remedial branch is usually already prepared by `/e2e-debug` on the same execute-plan session.

```bash
gh pr view <url> --json state,mergedAt,mergeCommit,baseRefName
git fetch origin <base_branch>
git merge-base --is-ancestor <mergeCommit.oid> origin/<base_branch>
./scripts/babysit_uat_watch_preuat.sh <mergeCommit.oid> --timeout-min 90
```

**UAT prod-ready is not a phase gate.** Do not poll deploy-uat.

### 6. Complete phase

```bash
node scripts/execute_plan_runtime.js set-phase <plan_id> \
  --phase <id> --status merged --pr-url <url> --pr-head <sha> --write
```

Update snapshot `merge_commit` via runtime (`set-phase` + `saveSnapshot`). Sync live plan; comment phase summary on control issue.

### 7. Next phase

If more `pending` phases → loop to §1 **immediately** — no pre-UAT polling on intermediate merges.

If all phases `merged` into integration → open **one** PR integration → `main` → **/babysit-uat** → then **complete plan**.

```bash
node scripts/execute_plan_runtime.js complete-plan <plan_id> --write
```

This sets `autonomy: completed`, syncs runtime, and closes the control issue with a summary comment (removes `busy` if still present). Use `--skip-close` only for dry-run inspection. If `gh issue close` fails, post the rendered `comment` manually on the control issue. Project board columns are human-maintained — agents do not update them.

---

## Halt (graceful shutdown)

Stop immediately on: revoke label, past `approved_until`, escalation, drift, CI budget exhausted, debt issue create failure, merge failure, or **session limit** (~24h continuous work — see Session preflight §9).

**Session limit** is a **checkpoint**, not a revoke. Post `halt --reason session_limit` on the control issue with `next_action`. Human comments `resume-plan <plan_id>`; no chat permission prompt.

**UAT prod-ready failure** → next merge agent or human manual promote owns remedial work — **not** a halt or `uat_paused` trigger.

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
| `/babysit-plus` | Intermediate phase PRs — triage, debt, CI, merge |
| `/babysit-uat` | **Final** PR to `main` — babysit+ + pre-UAT E2E |
| `/e2e-debug` | Pre-UAT remedial — delegated from babysit-uat / execute-plan on failure |
| `/pre-push-verify` | Before every push; full suite before merge |
| `/spawn-sprint-agents` | Phase with `spawn_allowed: true` (parallel within one phase) |
| Task `generalPurpose` | Per-phase implementation worker (orchestrator retains babysit+ / merge) |
| `/single-backend-route-change` | Route phases per exit checklist |
| `/split-flutter-screen` | Screen-split phases per exit checklist |

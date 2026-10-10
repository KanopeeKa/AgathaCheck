---
title: Agatha care journey (execute-plan)
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-10-10
tags: [pet_care, pet_profile, care_intelligence, roadmap]
---

# agatha-care-journey

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `agatha-care-journey` |
| **base_branch** | `cursor/agatha-care-journey-integration-b994` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **control_issue** | #1835 |
| **programme_ref** | `docs/domains/pet_care/changes/agatha-care-journey-programme.md` |
| **autonomy_contract** | `docs/domains/pet_care/changes/agatha-care-journey-execute-autonomy.md` |

## Goal

14 phases on **integration**; release PR → `main` with `/babysit-uat`. See programme + autonomy contract + bdd-qa.

## Orchestrator contract (binding — overrides generic “update the user” rules)

**Mode:** `run-until-blocked` only. Canonical: `/execute-plan` skill · `.agents/memory/execute-plan-autonomy.md` · `agatha-care-journey-execute-autonomy.md`.

After gate exit `0`, the orchestrator **keeps using tools** until merge-done, `complete-plan`, or a real §Halt. **User chat is not a phase gate.**

### Must do (every session)

1. `gate` → read `next_action` → continue that work **in the same session** when possible.
2. **CI watch in-loop** (`gh pr checks --watch` / babysit+) — not a reason to send a status reply and stop.
3. Phase **merge-done** → **immediately** start next `pending` phase (checkout, implement, PR) — no “confirm when done” in chat.
4. **Squash-merge** phase PRs to `base_branch` via **/babysit-plus** when required checks pass (`default_merge_mode: auto`).

### Forbidden (these count as wrongful stops)

| Anti-pattern | Why it violates the plan |
|--------------|---------------------------|
| Reply after preflight, PR open, or “CI running” | Milestones are telemetry on **#1835** only |
| “Next: pr-02” without pr-01 **merged** and pr-02 branch work started | Phase boundary = merge-done + continue |
| “Confirm when done” / “let me know” / permission to proceed | Standing grant covers all 14 phases + release PR |
| Waiting for human merge between phases | Babysit+ owns merge when green |
| Treating `human_pause` as default for migrations | See below — default is **merge when green** |

### Migrations (PR-01, 06, 09, 14)

**Default:** merge to integration when CI green — **no** pause, **no** chat ask.

**Only if** the orchestrator explicitly runs `halt --reason human_pause` on **#1835** does merge wait for `resume-plan agatha-care-journey`. Silence = continue.

### Chat vs control issue

| Channel | Use |
|---------|-----|
| **#1835** | PR links, CI green, phase merged, `next_action` |
| **User chat** | `**Needs you:**`, revoke, `session_limit`, escalation only |

**Standing grant (in snapshot `approved_by`):** full programme — all phases, integration batching, release PR, `/babysit-uat`. No re-approval per phase or per turn.

**Turn boundary:** If the platform ends the turn, the **next** message resumes with `/execute-plan agatha-care-journey` — pick up `next_action`; do not treat the prior reply as programme complete.

## Runtime state

```yaml
autonomy: active
current_phase: pr-02
last_completed_phase: pr-01
halt_reason: null
next_action: "start phase pr-02: checkout cursor/acj-pr-02-b994"
artifact_ref:
  branch: cursor/acj-pr-01-b994
  plan_path: .agents/plans/agatha-care-journey.md
  plan_commit: d360797d8634a72d958a9b3456c72e7758848cd0
  snapshot_path: .agents/plans/agatha-care-journey.snapshot.json
  snapshot_commit: d360797d8634a72d958a9b3456c72e7758848cd0
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phase loop (continuous — preflight is not a stop)

See snapshot phases `pr-01` … `pr-14`. Babysit-plus → integration. After pr-14 merged: open release PR → babysit-uat → complete-plan.

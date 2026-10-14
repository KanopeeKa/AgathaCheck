---
title: Agatha care journey (execute-plan)
owner: Product / Agent
audience: agent
status: completed
last_updated: 2026-10-14
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
| **programme_ref** | `docs/domains/pet_care/features/care-intelligence.md` (Agatha care journey §) |
| **autonomy_contract** | `.agents/plans/agatha-care-journey.md` §Orchestrator contract (plan **completed** 2026-10-14) |

## Goal

**Completed 2026-10-14.** All 14 phases merged via integration; release [#1875](https://github.com/KanopeeKa/AgathaCheck/pull/1875) → `main`. Product spec: `care-intelligence.md` (Agatha care journey sections). Pre-UAT on the release commit failed; remedial E2E fix shipped in [#1888](https://github.com/KanopeeKa/AgathaCheck/pull/1888) (first green pre-UAT on `895977c`).

## Orchestrator contract (binding — overrides generic “update the user” rules)

**Mode:** `run-until-blocked` only (historical). Canonical: `/execute-plan` skill · `.agents/memory/execute-plan-autonomy.md`.

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
autonomy: completed
current_phase: null
last_completed_phase: pr-14
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/agatha-care-journey.md
  snapshot_path: .agents/plans/agatha-care-journey.snapshot.json
open_prs: []
merge_commits: {"release":"7a6ea79d","pre_uat_green":"895977c0"}
debt_issue_refs: []
```

## Phase loop (continuous — preflight is not a stop)

See snapshot phases `pr-01` … `pr-14`. Babysit-plus → integration. After pr-14 merged: open release PR → babysit-uat → complete-plan.

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

## Orchestrator contract (binding — do not soft-stop)

This plan runs under **`/execute-plan` run-until-blocked** (skill + `.agents/memory/execute-plan-autonomy.md`). After gate exit `0`:

| Rule | Meaning |
|------|---------|
| **No turn-end checkpoints** | A user-visible chat reply does **not** end the programme. Same session: implement → PR → babysit+ → merge → next phase until §Halt or `complete-plan`. |
| **Forbidden stops** | Ending after preflight, PR opened, “CI pending”, milestone comment on #1835, or “next: pr-02” without merging pr-01 and starting implementation. |
| **Merge** | `default_merge_mode: auto` — orchestrator runs **/babysit-plus** and **squash-merges** when CI is green. No waiting for human merge between phases. |
| **Migration `human_pause`** | **Optional** explicit `halt --reason human_pause` on #1835 only when orchestrator chooses review before merge — **not** the default; default is merge when gates pass. |
| **Chat** | Blocker alerts only (`**Needs you:**`, revoke, `session_limit`). Progress → control issue #1835 only. |
| **Standing grant** | User authorized **full plan** (all 14 phases + release PR + babysit-uat). Do not re-ask per phase or per turn. |

If the platform forces a turn boundary: next message is `/execute-plan agatha-care-journey` (or `resume-plan` on #1835) — continue `next_action` without permission prompts.

## Runtime state

```yaml
autonomy: active
current_phase: pr-01
last_completed_phase: null
halt_reason: null
next_action: "continue phase pr-01 on branch cursor/acj-pr-01-b994"
artifact_ref:
  branch: cursor/acj-pr-01-b994
  plan_path: .agents/plans/agatha-care-journey.md
  plan_commit: 93dbf0c78fa2727031a72749d5dc053d06b5a133
  snapshot_path: .agents/plans/agatha-care-journey.snapshot.json
  snapshot_commit: 93dbf0c78fa2727031a72749d5dc053d06b5a133
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1837"]
merge_commits: {}
debt_issue_refs: []
```

## Preflight (completed)

- Integration branch created and pushed
- Snapshot `autonomy: active`, `control_issue: 1835`
- Gate validated
- Control issue #1835 — `approve-autonomous` recorded

## Phase loop

See snapshot phases `pr-01` … `pr-14`. Babysit-plus → integration. After pr-14 merged: open release PR → babysit-uat → complete-plan.

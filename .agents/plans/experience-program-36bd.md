# Experience program — execute plan

> **plan_id:** `experience-program-36bd`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `experience-program-36bd` |
| **title** | Experience program — navigation reversal + guardian/org dashboards |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver the locked Experience program (Phase R + 0–5): reverse Navigation v2, unified notifications,
Guardian dashboard redesign, Organisation presentation/access-control rework, foster/pet ops
extensions, and org customisations — sequential direct-to-`main` per D33 unless Phase 3 spawns
parallel agents.

**Canonical docs:** `docs/experience-program/` · **Epic issue:** #378

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-25T23:41:00Z` |
| **approved_until** | `2026-07-27T23:41:00Z` |
| **control_issue** | #379 |
| **autonomy** | `active` |

**Grant:** User chat 2026-07-25 — babysit+ PR #377, then `/execute-plan` with `/spawn-sprint-agents`
and `/ui-design-deep` as needed.

## Sanity check

**proceed-high-risk** — multi-phase cross-stack program; phases are atomic with BDD/TDD gates per
`program-contract.md`.

## Runtime state

```yaml
autonomy: active
current_phase: 0
last_completed_phase: R
halt_reason: null
next_action: "continue phase 0 on branch cursor/experience-foundation-36bd"
artifact_ref:
  branch: cursor/experience-foundation-36bd
  plan_path: .agents/plans/experience-program-36bd.md
  plan_commit: 32ebc9155097f79cdd9bfaab42603b460db32280
  snapshot_path: .agents/plans/experience-program-36bd.snapshot.json
  snapshot_commit: 32ebc9155097f79cdd9bfaab42603b460db32280
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/380"]
merge_commits: {"R":"15bc8a3da7b257c3ee68e9085edd3b1108b4751c"}
debt_issue_refs: []
```

## Phases

See snapshot JSON for `allowed_paths`, branches, and spawn config. Phase 3 may invoke
`/spawn-sprint-agents` when sprint scope warrants parallel disjoint tracks.

| Phase | Title | Branch |
|-------|-------|--------|
| R | Reconciliation | `cursor/experience-program-plan-36bd` (merged #377) |
| 0 | Foundation | `cursor/experience-foundation-36bd` |
| 1 | Shell & navigation reversal | `cursor/experience-nav-shell-36bd` |
| 2 | Guardian journey | `cursor/experience-guardian-journey-36bd` |
| 3 | Organisation presentation | `cursor/experience-org-presentation-36bd` |
| 4 | Foster & pet ops | `cursor/experience-foster-pet-ops-36bd` |
| 5 | Org customisations | `cursor/experience-org-customisations-36bd` |

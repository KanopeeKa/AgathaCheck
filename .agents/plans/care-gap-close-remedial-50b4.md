# Care gap-close remedial (post-review)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-gap-close-remedial-50b4` |
| **title** | Gap-close remedial: v4 occurrence actions, sheets, edit, BDD gate, bookkeeping |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **programme_ref** | Post-merge review after squash `171e751` / PR #1527 |

## Goal

Close verified gaps from the gap-close review: move Postpone and Plan another date to the occurrence screen (v4 §18.6.4), fix sheet defaults and server `as_of` / copy, allow editing finished planned items, exclude header-only BDD mappings from the coverage gate, and refresh debt/docs bookkeeping.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-05T14:59:47Z |
| **approved_until** | 2026-10-07T14:59:47Z |
| **approved_by** | User chat 2026-10-05 — create plan and implement as /execute-plan full autonomy |
| **control_issue** | (see snapshot) |

## Phases

### R1 — Occurrence screen menus (v4)

Move Postpone and Plan another date off the Care Item hero; expose them on the occurrence screen ⋯ menu. Update Playwright page objects and specs.

### R2 — Care action sheets

Plan-another-date default picks a valid new day; Pause/Resume/Plan sheets use item `as_of` and localized dates; Postpone until copy alignment.

### R3 — Finished planned item edit

Editing archived/done one-off planned items saves without client due-date failure; preserve server `completed_on` when appropriate.

### R4 — BDD gate header-only

Header-only `@bdd` mappings do not count toward the 68% mapped gate.

### R5 — Bookkeeping

Close resolved debt issues, fix stale plan/memory/docs from findings 9.

---

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: R5
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/care-remedial-r5-bookkeeping-50b4
  plan_path: .agents/plans/care-gap-close-remedial-50b4.md
  plan_commit: 2af8f2a5a449a7a3ce5f3d5d60e19159af8503a4
  snapshot_path: .agents/plans/care-gap-close-remedial-50b4.snapshot.json
  snapshot_commit: 2af8f2a5a449a7a3ce5f3d5d60e19159af8503a4
open_prs: []
merge_commits: {"R1":"6ee50f1fe057e8f3ad7de288decd90c6ea791725","R2":"6ee50f1fe057e8f3ad7de288decd90c6ea791725","R3":"6ee50f1fe057e8f3ad7de288decd90c6ea791725","R4":"6ee50f1fe057e8f3ad7de288decd90c6ea791725","R5":"6ee50f1fe057e8f3ad7de288decd90c6ea791725"}
debt_issue_refs: []
```

## Related

- Parent programme: `care-requirements-gap-close-c1a7` (integration #1527 → main)
- Control issue: #1646
- Implementation PR: [#1650](https://github.com/KanopeeKa/AgathaCheck/pull/1650)

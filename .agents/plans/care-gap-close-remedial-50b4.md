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
autonomy: active
current_phase: R1
last_completed_phase: null
halt_reason: null
next_action: implement R1
artifact_ref:
  branch: cursor/care-remedial-r1-occurrence-menus-50b4
  plan_path: .agents/plans/care-gap-close-remedial-50b4.md
  snapshot_path: .agents/plans/care-gap-close-remedial-50b4.snapshot.json
open_prs: []
```

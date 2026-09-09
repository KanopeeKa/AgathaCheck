---
title: Care Through Change V1
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-09-09
tags: [pet_care, care_context, execute-plan]
---

# Care Through Change V1

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-through-change-v1` |
| **title** | Care Through Change V1 (CC-1 through CC-4) |
| **author** | Cloud agent |
| **created** | 2026-09-09 |
| **base_branch** | `cursor/care-through-change-v1-integration-6605` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **canonical spec** | `docs/domains/pet_care/features/care-context.md` |
| **delivery plan** | `docs/domains/pet_care/changes/care-through-change-delivery-plan.md` |

## Goal

Deliver the first trustworthy **Care Through Change** vertical slice: a pet parent can preview (and optionally save) a declared absence window and see an accurate, read-only projection of existing care scheduled during those dates — with server-authoritative coverage/reassurance that never converts uncertainty into false comfort.

Four atomic phases (CC-1 … CC-4). Phase PRs merge to the integration branch; one final PR integration → `main` after merge prerequisites are satisfied.

## Merge prerequisites (frozen)

| PR | Purpose | Gate |
|----|---------|------|
| [#1107](https://github.com/KanopeeKa/AgathaCheck/pull/1107) | Dependabot batch on `main` | **Merged** — rebase all branches onto `origin/main` at `8e50b42b`+ before phase work |
| [#1108](https://github.com/KanopeeKa/AgathaCheck/pull/1108) | Copy-tone / True North docs (`cursor/brand-docs-restructure-c0d1`) | **CC-4 only** — rebase integration before final integration→`main`; user-facing copy must follow merged `docs/design/copy-tone.md` |

Do **not** open the final integration→`main` PR until #1108 is merged (or explicitly waived on control issue).

## Shipping gates (non-negotiable)

1. Projection and coverage fixtures must be green before reassurance wording ships.
2. Zero projected items may only mean “nothing scheduled” when projection completeness is proven.
3. CC-1 through CC-4 ship as **separate atomic PRs**, not one blob.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-09T23:05:00Z |
| **approved_until** | 2026-09-11T23:05:00Z |
| **approved_by** | user chat 2026-09-09 — frozen Care Through Change V1 scope + `/execute-plan` with hold on #1107/#1108 |
| **control_issue** | [#1110](https://github.com/KanopeeKa/AgathaCheck/issues/1110) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous care-through-change-v1`

## Phases

See snapshot for branch names, `allowed_paths`, and exit criteria.

## Runtime

```yaml
autonomy: active
current_phase: cc1
last_completed_phase: null
halt_reason: null
next_action: "continue phase cc1 on branch cursor/care-through-change-cc1-6605"
artifact_ref:
  branch: cursor/care-through-change-v1-integration-6605
  plan_path: .agents/plans/care-through-change-v1.md
  plan_commit: b1a8e9927f99b0357ddb941cc17056ba6f226dc7
  snapshot_path: .agents/plans/care-through-change-v1.snapshot.json
  snapshot_commit: b1a8e9927f99b0357ddb941cc17056ba6f226dc7
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

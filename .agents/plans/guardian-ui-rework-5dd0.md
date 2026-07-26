# Guardian UI rework — execute plan

> **plan_id:** `guardian-ui-rework-5dd0`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-ui-rework-5dd0` |
| **title** | Guardian UI rework — landing, dashboard, events, pet screen, shell |
| **base_branch** | `cursor/guardian-ui-rework-integration-5dd0` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver the guardian-facing UI rework from the 2026-07-26 brief: global navigation shell, landing layout, unified pet tiles, Due and Overdue events, vet list reliability, pet screen event management, and drawer/account refresh. Phases merge to an integration branch; one final PR integration → `main`.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Landing path cards | Become non-expandable buttons scrolling to full-width audience sections below hero |
| Password toggle | Sign-in + signup confirm password |
| Pet groups | My pets (includes shared) + My foster pets; sort by `createdAt` ASC |
| Passed-away pets | Collapsible section at bottom of Manage pets only, collapsed by default |
| Pet preview cap | None — fixed-width tiles fill screen |
| Events label | **Due and Overdue** — within `remindDaysBefore` window |
| Weight in events | No — scrap D17 |
| Route | Rename `/health` → `/g/events`; redirect old URLs |
| Vets row | Name · city; pet count right-aligned |
| Pet share | Copy link (existing flow); richer share sheet deferred |
| Foster sessions in manage list | Read-only for now |
| Admin log | Reuse existing PDF export on History tab |
| Add pet FAB | Stays on Manage pets; removed from dashboard |
| Foster settings link | Foster's own People card per org |
| Bell placement | Always right of contextual menu, separated by `\|` |
| Pet detail shell | Harmonise with `ExperienceShellScaffold` visual pattern |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-26T16:35:00Z` |
| **approved_until** | `2026-07-28T16:35:00Z` |
| **approved_by** | user chat 2026-07-26 (`/execute-plan` + answers) |
| **control_issue** | #393 |
| **autonomy** | `active` |

## Sanity check

**proceed-high-risk** — 7 phases, cross-cutting Flutter UI + small API (`createdAt`); integration branch batches merges.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/guardian-ui-shell-foundation-5dd0"
artifact_ref:
  branch: cursor/guardian-ui-rework-integration-5dd0
  plan_path: .agents/plans/guardian-ui-rework-5dd0.md
  plan_commit: 6f97e05509f8c48aac942d2cce82a63c9df4f518
  snapshot_path: .agents/plans/guardian-ui-rework-5dd0.snapshot.json
  snapshot_commit: 6f97e05509f8c48aac942d2cce82a63c9df4f518
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See snapshot JSON for `allowed_paths` / branches.

## Final merge

After all phases `merged` into integration, open one PR: `cursor/guardian-ui-rework-integration-5dd0` → `main` with `./scripts/pre-push.sh`.

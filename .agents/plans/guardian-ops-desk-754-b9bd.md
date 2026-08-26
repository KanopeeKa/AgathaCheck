# Guardian operations desk standards — execute plan

> **plan_id:** `guardian-ops-desk-754-b9bd`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-ops-desk-754-b9bd` |
| **title** | Harden PR #754 Guardian operations desk to AgathaTrack standards |
| **base_branch** | `cursor/guardian-ops-desk-754-b9bd-integration-b9bd` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Land the Guardian operations desk redesign from PR #754 in reviewable atomic slices: record superseding navigation decisions, isolate Flutter 3.44 compatibility churn, deliver the desk UI with accessibility and modularity fixes, then complete BDD/E2E coverage before one integration → `main` merge.

## Locked product decisions (2026-08-26)

| Topic | Decision |
|-------|----------|
| Mobile primary nav | Five-tab bottom bar (Today, Pets, Care, Fostering, Account) **supersedes** blueprint §15 anti-pattern |
| Account entry | Account reachable from bottom nav **and** drawer for now; drawer-only rule superseded pending drawer removal |
| Design tokens | New background `#EAE8E8` and `guardianLight` `#E8E1E3` supersede prior warm-paper values globally |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-08-26T09:46:00Z` |
| **approved_until** | `2026-08-28T09:46:00Z` |
| **approved_by** | user chat 2026-08-26 (decision gates + `/execute-plan`) |
| **control_issue** | #755 |
| **autonomy** | `active` |

## Sanity check

**proceed-high-risk** — 5 phases, cross-cutting Flutter UI + docs + E2E; integration branch batches merges; source PR #754 is ~145 files.

## Runtime state

```yaml
autonomy: active
current_phase: null
last_completed_phase: 5
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/guardian-ops-desk-754-b9bd-integration-b9bd
  plan_path: .agents/plans/guardian-ops-desk-754-b9bd.md
  plan_commit: 4d05b136848c87fb0f3170f5b6900bcb532a46b8
  snapshot_path: .agents/plans/guardian-ops-desk-754-b9bd.snapshot.json
  snapshot_commit: 4d05b136848c87fb0f3170f5b6900bcb532a46b8
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See snapshot JSON for `allowed_paths` / branches.

## Final merge

After all phases `merged` into integration, open one PR: `cursor/guardian-ops-desk-754-b9bd-integration-b9bd` → `main` with `./scripts/pre-push.sh` and `/babysit-uat`.

## Source reference

- PR #754: `replit/guardian-operations-desk-ui` — analysis baseline for desk UI and scope split.

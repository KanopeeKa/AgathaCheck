# Guardian adaptive navigation — execute plan

> **plan_id:** `guardian-adaptive-nav-7221`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-adaptive-nav-7221` |
| **title** | Guardian adaptive navigation — rail, sidebar, decisions |
| **base_branch** | `cursor/guardian-adaptive-nav-7221-integration-7221` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver adaptive Guardian navigation for tablet and desktop: preserve the five-destination IA (Today, Pets, Care, Fostering, Account) while replacing the post-600px navigation desert with a leading navigation rail (600–839px) and expanded sidebar (≥840px). Record D-v4-4/5 decisions, resolve D-v4-2 (drawer retirement on medium+), relocate workspace switcher into the shell, and add BDD/E2E coverage.

## Prerequisite — PR #767

**Must merge before Phase 2 implementation.** PR #767 expands compact bottom nav to all Guardian workspace screens (`/pet/*`, `/health`, `/g/vets`, etc.) with workspace-wide `supports()` / `indexFor()` mapping. Adaptive leading nav reuses the same destination config and route-detection semantics — not the old five-route-only model.

## Locked product decisions (this plan)

| Topic | Decision |
|-------|----------|
| Breakpoints | &lt;600 bottom bar; 600–839 icon rail; ≥840 expanded sidebar (aligns with `docs/design/system.md` Medium/Expanded) |
| IA | Same five Guardian destinations; presentation changes only |
| Drawer | Retired on widths where leading nav is visible; workspace switcher moves to shell header |
| D-v4-2 | Resolved: Account in leading nav footer on medium+; drawer dual-entry ends when rail/sidebar ships |
| Shelter sidebar | Deferred — Guardian-only in this plan |
| Care badge | Deferred to follow-up debt issue |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-08-26T22:12:00Z` |
| **approved_until** | `2026-08-28T22:12:00Z` |
| **approved_by** | user chat 2026-08-26 (/execute-plan + adaptive nav analysis authorization) |
| **control_issue** | #768 |
| **autonomy** | `active` |

## Sanity check

**proceed-high-risk** — 4 phases, cross-cutting Flutter shell + docs + E2E; integration branch; depends on PR #767 merge.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 4
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/guardian-adaptive-nav-7221.md
  plan_commit: 8f39cdf5cfc54728e0f4e67d566086cbca2b9e7d
  snapshot_path: .agents/plans/guardian-adaptive-nav-7221.snapshot.json
  snapshot_commit: 8f39cdf5cfc54728e0f4e67d566086cbca2b9e7d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See snapshot JSON for `allowed_paths` / branches.

## Final merge

After all phases `merged` into integration, open one PR: `cursor/guardian-adaptive-nav-7221-integration-7221` → `main` with `./scripts/pre-push.sh` and `/babysit-uat`.

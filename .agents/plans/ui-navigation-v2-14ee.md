# UI navigation v2 — execute plan

> **plan_id:** `ui-navigation-v2-14ee`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ui-navigation-v2-14ee` |
| **title** | UI navigation v2 — shell, drawer, theming, vets |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver maintainable navigation v2: config-driven drawer (g/p/w groups), Home+Hamburger-only chrome, compact shell on deep routes, guardian-preselected chooser, ownership plum/green accents, org list/detail palette, vet org-scoping, and aligned BDD/E2E.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Dual-role login | Keep `/app/choose`; **Guardian pre-selected** |
| Contact | Mailto `contact@agathatrack.com` in utility drawer group |
| Shell | **Full** on hubs; **compact** (☰ Back Home) on deep routes |
| Top nav | Home + Hamburger only |
| Org switcher | Guardian drawer → `/organizations` |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-23T20:05:00Z` |
| **approved_until** | `2026-07-25T20:05:00Z` |
| **control_issue** | #299 |
| **autonomy** | `active` |

## Sanity check

**proceed-high-risk** — multi-phase UI + API + E2E; phases are atomic with paired test updates.

## Runtime state

```yaml
autonomy: active
current_phase: 9
last_completed_phase: 8
halt_reason: null
next_action: "continue phase 9 on branch cursor/ui-nav-v2-phase9-vet-api-14ee"
artifact_ref:
  branch: cursor/ui-nav-v2-phase9-vet-api-14ee
  plan_path: .agents/plans/ui-navigation-v2-14ee.md
  plan_commit: d24f41ecfcee948db9d8677fa99ee635d3dd61c4
  snapshot_path: .agents/plans/ui-navigation-v2-14ee.snapshot.json
  snapshot_commit: d24f41ecfcee948db9d8677fa99ee635d3dd61c4
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See snapshot JSON for `allowed_paths` / branches.

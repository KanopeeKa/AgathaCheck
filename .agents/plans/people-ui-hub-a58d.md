# People UI hub — execute-plan

**plan_id:** `people-ui-hub-a58d`  
**title:** People discoverability — 5-tab nav, desk module, list hub  
**created:** 2026-09-28  
**base_branch:** `cursor/people-ui-hub-integration-a58d`  
**default_merge_mode:** `auto`  
**artifact_branch_policy:** `phase-branch`

## Goal

Make People & Care Team **discoverable** in Pet Care: replace the dashboard **My Vets** block with a single **People** desk module (top professionals, top carers, household rail), add **People** as a **fifth primary bottom-nav destination** (Option A — **always five icons** on all widths; adjust padding/icon size only), canonical route `/pc/people`, and upgrade the People list toward spec grouping. Amend prior navigation/dashboard decisions documented in phase 0. One integration → `main` PR after all phases merge.

**Product lock-in (user chat 2026-09-28):** Option A — Today · Pets · Care · **People** · Account on the compact bar at every breakpoint; no collapsing to four icons.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-28: bootstrap `people-ui-hub-a58d` with `/execute-plan`, Option A, always 5 bottom-nav icons |
| **control_issue** | (set in snapshot after bootstrap) |

## Runtime

```yaml
autonomy: active
current_phase: p4-ship-main
last_completed_phase: p3-list
halt_reason: null
next_action: "continue phase p4-ship-main on branch cursor/people-ui-hub-integration-a58d"
artifact_ref:
  branch: cursor/people-ui-hub-integration-a58d
  plan_path: .agents/plans/people-ui-hub-a58d.md
  plan_commit: 31f512dc7d9ad396eae0b8ce6575bd31b631e283
  snapshot_path: .agents/plans/people-ui-hub-a58d.snapshot.json
  snapshot_commit: 31f512dc7d9ad396eae0b8ce6575bd31b631e283
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1380"]
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase p0-decisions — Navigation & desk decision pack

Document amendments to people-care-team § UI, guardian-dashboard-brief (My Vets → People module), phase-1-navigation (fifth tab), and Option A five-icon bar policy. Add `docs/domains/people/changes/ui-hub-navigation.md`.

### Phase p1-nav — Fifth tab + `/pc/people`

Insert People into `PetCarePrimaryDestinations` (5 routes, fixed count). `BottomNavigationBar` always renders 5 items; responsive padding/label style only. Rail/sidebar include People. Redirect `/account/people` → `/pc/people`. E2E semantics `pet_care_nav_people`.

### Phase p2-desk — Dashboard People module

Remove `PetCareMyVetsSection`; add `PetCarePeopleDeskModule` (top 2 professionals by linked pet count, top 2 trusted carers, household member rail). Optional `GET /api/people/desk-preview` if client ranking is insufficient. `/pc/vets` redirect to People with professionals filter.

### Phase p3-list — People hub list parity

Household-named sections, filter chips (All / Household / Carers / Professionals), search (client-first). Keep vocabulary labels; page title may be longer than nav label.

### Phase p4-ship-main — Integration → main

Rebase integration on `origin/main`, `./scripts/pre-push.sh`, single PR integration → `main`, babysit-uat on merge.

# Guardian UI wave 2 — execute plan

> **plan_id:** `guardian-ui-wave2-5dd0`  
> **Briefs:** `docs/experience-program/briefs/guardian-ui-wave2-issue-briefs.md`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-ui-wave2-5dd0` |
| **title** | Guardian UI wave 2 — pets, events overhaul, profile screens, drawer |
| **base_branch** | `cursor/guardian-ui-wave2-integration-5dd0` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver wave-2 guardian UX: vertical pet tiles, drawer identity, unified due-event cards, pet profile navigation to dedicated screens (timeline, weight, health issues), four-type event model with view-entry flow, manage-events list, global `/g/events`, notification deep links, and health-issue documents API.

Phases merge to integration branch `cursor/guardian-ui-wave2-integration-5dd0`; one final PR integration → `main`.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Pet subgroups | Option A — titled My pets / My foster pets in one section |
| Pet card height | Same as current tile width (160–220px) |
| Due card Open | Event edit route |
| Close recurring | `status=completed` + `repeat_end_date=yesterday` |
| Reopen event | `status=active`, clear `repeat_end_date`, clear `next_due_date` |
| Skip iteration | Not delete; `skipped` status; unskip supported |
| Unmark done | Last marked-as-done iteration only |
| See history vs past iterations | Different (admin log vs occurrence list) |
| Health issue reopen note | Append to **description** |
| Issue since / resolved | Date pickers; open/resolved status |
| Timeline v1 | List only; no custody/gap fill |
| Drawer Account | Top block; phase-1 bottom-pin superseded |
| Export PDF | Section picker from profile menu |
| Bulk create | Keep; one row per pet |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-27T13:10:00Z` |
| **approved_until** | `2026-07-29T13:10:00Z` |
| **approved_by** | user chat 2026-07-27 (`/execute-plan` + wave-2 briefs) |
| **control_issue** | #423 |
| **autonomy** | `active` |

## Sanity check

**proceed-high-risk** — 15 phases, backend migrations, events lifecycle APIs, parallel spawn phase 8.

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 15
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/guardian-ui-wave2-integration-5dd0
  plan_path: .agents/plans/guardian-ui-wave2-5dd0.md
  plan_commit: 65ab9df766687f1952a2761a00ebd800da6af73b
  snapshot_path: .agents/plans/guardian-ui-wave2-5dd0.snapshot.json
  snapshot_commit: 65ab9df766687f1952a2761a00ebd800da6af73b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

| Phase | Title | Briefs |
|-------|-------|--------|
| 1 | Landing password eye icon (web) | W01 |
| 2 | Drawer user identity header | W02 |
| 3 | Vertical wrap pet cards + merged section | W03 |
| 4 | Vet labels + edit pet polish | W04, W05 |
| 5 | Event types four-way migration | W06 |
| 6 | DueEventCard + due sections | W07, W08 |
| 7 | Pet profile section nav rows | W09 |
| 8 | **Spawn:** weight screen, timeline screen, health-issue docs API | W10, W11, W12 |
| 9 | Health issues screen + profile sharing/export menu | W13, W14 |
| 10 | Event lifecycle API | W15 |
| 11 | View entry screen | W16 |
| 12 | Manage events unified list | W17 |
| 13 | Unified event edit form | W18 |
| 14 | Global `/g/events` rework | W19 |
| 15 | Notification deep links to view entry | W20 |

## Spawn phase 8 ownership

| Agent | Branch | Owns |
|-------|--------|------|
| weight | `cursor/guardian-wave2-weight-5dd0` | `flutter_app/**/weight*` screens, weight_tracking_section extract |
| timeline | `cursor/guardian-wave2-timeline-5dd0` | `flutter_app/**/pet_timeline*`, timeline screen routes |
| health-docs | `cursor/guardian-wave2-health-docs-api-5dd0` | `server/routes/healthIssues/**`, `db/migrations/*health_issue_doc*` |

## Final merge

After all phases `merged` into integration, open one PR: `cursor/guardian-ui-wave2-integration-5dd0` → `main` with `./scripts/pre-push.sh`.

---
title: Shelter dashboard v2 (nav, tasks, pin)
plan_id: shelter-dashboard-v2-c4e8
---

# Shelter dashboard v2 — execute plan

## Goal

Transform the Shelter workspace (`/o/orgs` and org deep routes) into a **Care-shaped operations desk** with teal-only chrome: primary navigation (bottom / leading, persistent inside org), **Shelter tasks** preview (cross-org, invites included), **pinned shelter** in nav (account preference, one max), and a streamlined dashboard body — while **membership tile geometry** is delivered by the parallel **`unified-pet-tile-c4e8`** plan.

**Non-goals (deferred):** per-org profile nav redesign; full `OrgShellScaffold` unification with `ExperienceShellScaffold`; dedicated shelter-tasks API (v1 client aggregation only).

## Coordination — `unified-pet-tile-c4e8` (locked)

| Owner | Scope |
|-------|--------|
| **unified-pet-tile-c4e8** | Tile geometry: cover/meta ratio, logo scale, bio/location layout, shared pet-grid primitive + `topRightOverlay` slot |
| **shelter-dashboard-v2-c4e8** | Dashboard IA, Shelter tasks, primary nav, pin API + `ShelterMembershipPinButton`, teal shell tokens |

**Execution order (agreed):**

| Wave | Phases | Notes |
|------|--------|-------|
| **A** | 0 → 1 → 2 → 3 → 6 → **5a** | Canon, pin API, nav shell, tasks, dashboard layout (no tile geometry) |
| **Gate** | `unified-pet-tile-c4e8` merged to shared integration | Do not start phase 4 until unified membership tile is on integration |
| **B** | 4 → **5b** | Pin overlay on unified tile; wire bio/town/postcode on final card |
| **C** | 7 → 8 | Teal audit, tests + navigation contract |

**Pin widget:** `ShelterMembershipPinButton` — 48dp touch target, top-right on cover; unified tile exposes overlay slot only.

**Nav slots:** 5-slot geometry — slot 1 Dashboard, slot 2 pinned org (hidden when unset), slot 3 spacer, slot 4 Discover, slot 5 Account.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | user chat 2026-09-03 (/execute-plan shelter-dashboard-v2-c4e8, unified-tile handoff agreed) |
| **approved_until** | 2026-09-05T22:45:00Z |
| **base_branch** | `cursor/shelter-dashboard-v2-c4e8-integration-c4e8` |
| **control_issue** | #952 |

## Phases

### Phase 0 — Shelter dashboard v2 framing decisions

Lock `docs/domains/shelter/changes/shelter-dashboard-v2-framing-decisions.md` (D-desk-S7/S8, D-shelter-NAV-1..3, D-shelter-TASKS-1). Update `navigation-decisions.md` supersede notes and `docs/debt/refactoring-log.md`.

**Exit:** Framing doc `status: active`; validate docs (no inline hex outside tokens.md).

---

### Phase 1 — Pinned org account preference (API)

Add `pinned_organization_id` (nullable UUID FK → `organizations`, `ON DELETE SET NULL`) on `users`. Expose on `GET /auth/me` and `PUT /auth/me` (or dedicated `PUT /auth/me/preferences`) with validation: user must be active member of pinned org. Jest coverage.

**Exit:** Cross-device pin round-trip; 403/400 on invalid pin; membership loss clears pin server-side.

---

### Phase 2 — Shelter primary destinations config

New `ShelterPrimaryDestinations` (mirror `GuardianPrimaryDestinations`): routes, breakpoints, dynamic pinned slot, 5-slot geometry with empty centre when unpinned. Widgets: `ShelterBottomNavigation`, `ShelterNavigationRail`, `ShelterNavigationSidebar` (or shared parameterized shell nav).

**Exit:** Widget tests for destination list with/without pin; selected index on `/o/orgs`, `/o/orgs/:id`, discover, `/account`.

---

### Phase 3 — Org experience shell with persistent primary nav

Extend `ExperienceShellScaffold` for `AppExperience.organization`: leading nav + bottom bar on **all** org routes (including `/o/orgs/:id/**`). Workspace toggle remains everywhere (D-v5-WORKSPACE-4). Remove duplicate Discover body entry points from shell where nav replaces them. Teal app bar rules per D-desk-S8.

**Exit:** Org deep route keeps bottom/side nav visible; toggle + bell still present; no plum on org shell surfaces.

---

### Phase 4 — Pin control on membership tile

*Wave B only — **blocked** until `unified-pet-tile-c4e8` is on integration.*

`ShelterMembershipPinButton` in unified tile overlay slot. Wire to Phase 1 API; replace-on-pin; unpin on tap when pinned.

**Exit:** Pin/unpin updates nav slot without restart; invalid pin cleared after membership refresh.

---

### Phase 5 — Shelter dashboard body redesign (5a layout, 5b tile meta)

**5a (wave A):** `OrganizationListScreen` — remove dashboard title/subtitle header; start at **My organisations** eyebrow; remove `OrgDiscoverNavRow` from body; section order per framing doc.

**5b (wave B, after unified tile + phase 4):** Membership cards show **bio** + **town, postcode** on unified tile; finalize grid tests.

**Exit:** Hub matches framing doc; discover only via nav; widget tests updated.

---

### Phase 6 — Shelter tasks preview (v1 aggregation)

*Runs in wave A (before unified-tile gate).*

New `ShelterTasksPreview` section with `GuardianDashboardSectionHeader`-style eyebrow on `organizationLight` canvas. v1 provider aggregates across **all** memberships:

| Source (existing) | Task type |
|-------------------|-----------|
| `pendingOrgInvitesProvider` | Accept/decline invite rows |
| Per-org placements / pets attention | Foster finishing soon, need-attention pets (reuse `OrgPetAttentionReason` / placement status helpers) |
| Role-gated stubs | Foster onboarding steps, open foster requests (where data already on client) |

Cap ~8 rows; “See all” only when a real destination exists (D-desk-4 analogue). Link rows to existing routes.

**Exit:** Dashboard shows tasks for multi-org user; empty state calm; invites appear inside tasks block not separate section.

---

### Phase 7 — Teal token audit + design docs

Audit Shelter nav surfaces against D-desk-S8; document Shelter dashboard section surfaces in `docs/design/tokens.md`. Grep guard: no `petCarePrimary` / plum on `/o/**` presentation paths touched by this plan.

**Exit:** Token doc updated; analyze clean on changed files.

---

### Phase 8 — Tests and navigation contract

Widget tests for tasks, pin, shelter nav. Update `docs/e2e/navigation-contract.md` (Shelter primary nav, pin, tasks locators). BDD debt issue if new journeys exceed snag ladder.

**Exit:** `navigation-contract.md` reflects D-shelter-NAV-1; org shard tests green.

---

## Sanity check (pre-approval)

| Check | Result |
|-------|--------|
| Scope | **proceed-high-risk** — supersedes locked nav + desk decisions; touches shell + API migration |
| Overlap with unified-pet-tile | Mitigated via handoff rules |
| CI factor | 9 phases, Flutter shell + one migration |
| Blockers | Confirm `unified-pet-tile-c4e8` plan exists on branch before Phase 4/5 tile work |

## Runtime state

```yaml
autonomy: active
current_phase: 8
last_completed_phase: 7
halt_reason: null
next_action: "phase 8 complete — await merge PR"
artifact_ref:
  branch: cursor/shelter-dashboard-v2-tests-c4e8
  plan_path: .agents/plans/shelter-dashboard-v2-c4e8.md
  plan_commit: 821702e017dd671f94d8e49cfa23cddc9a6d8bd6
  snapshot_path: .agents/plans/shelter-dashboard-v2-c4e8.snapshot.json
  snapshot_commit: 821702e017dd671f94d8e49cfa23cddc9a6d8bd6
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

| Phase | Status | Branch |
|-------|--------|--------|
| 0 | done | cursor/shelter-dashboard-v2-framing-c4e8 |
| 1 | done | cursor/shelter-pinned-org-api-c4e8 |
| 2 | done | cursor/shelter-primary-nav-config-c4e8 |
| 3 | done | cursor/shelter-shell-primary-nav-c4e8 |
| 4 | done | cursor/shelter-tile-pin-c4e8 |
| 5 | done | cursor/shelter-dashboard-body-c4e8 |
| 6 | done | cursor/shelter-tasks-preview-c4e8 |
| 7 | done | cursor/shelter-teal-token-audit-c4e8 |
| 8 | in progress | cursor/shelter-dashboard-v2-tests-c4e8 |

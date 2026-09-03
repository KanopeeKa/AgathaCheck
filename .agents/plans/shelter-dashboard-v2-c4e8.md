---
title: Shelter dashboard v2 (nav, tasks, pin)
plan_id: shelter-dashboard-v2-c4e8
---

# Shelter dashboard v2 — execute plan

## Goal

Transform the Shelter workspace (`/o/orgs` and org deep routes) into a **Care-shaped operations desk** with teal-only chrome: primary navigation (bottom / leading, persistent inside org), **Shelter tasks** preview (cross-org, invites included), **pinned shelter** in nav (account preference, one max), and a streamlined dashboard body — while **membership tile geometry** is delivered by the parallel **`unified-pet-tile-c4e8`** plan.

**Non-goals (deferred):** per-org profile nav redesign; full `OrgShellScaffold` unification with `ExperienceShellScaffold`; dedicated shelter-tasks API (v1 client aggregation only).

## Coordination — `unified-pet-tile-c4e8`

| Owner | Scope |
|-------|--------|
| **unified-pet-tile-c4e8** (other agent) | Tile look-and-feel: cover/meta ratio (~50% image), logo scale, typography, shared pet-grid primitive |
| **shelter-dashboard-v2-c4e8** (this plan) | Dashboard IA, Shelter tasks, primary nav, pin preference + overlay, teal shell tokens, docs |

**Handoff rule:** Phase 4 (pin overlay) applies to whatever membership tile widget `unified-pet-tile-c4e8` lands. If unified tile is not merged when Phase 4 starts, Phase 4 is limited to **pin control + provider wire** on current `OrgMembershipTile`, then a follow-up micro-phase rebases pin onto the unified widget.

**Integration branch policy:** Prefer rebasing this plan’s integration branch onto `unified-pet-tile-c4e8` integration when that plan exists, before Phase 4.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_by** | *(pending human review)* |
| **approved_until** | *(set at `approve-autonomous` — +48h)* |
| **base_branch** | `cursor/shelter-dashboard-v2-c4e8-integration-c4e8` |
| **control_issue** | *(bootstrap after approval)* |

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

Pin icon top-right on tile cover (48dp touch target). Wire to Phase 1 API via Riverpod provider; replace-on-pin; unpin on tap when pinned. **Do not** change tile geometry here (unified-pet-tile plan).

**Exit:** Pin/unpin updates nav slot without restart; invalid pin cleared after membership refresh.

---

### Phase 5 — Shelter dashboard body redesign

`OrganizationListScreen`: remove `OrgHubSectionHeader` for dashboard title/subtitle; start at **My organisations** eyebrow only; remove `OrgDiscoverNavRow` from body. Membership cards show **bio** + **town, postcode** (client: `town` + `publicProfileMetadata['postcode']`).

**Exit:** Hub matches framing doc section order; discover only via nav; widget tests updated.

---

### Phase 6 — Shelter tasks preview (v1 aggregation)

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
autonomy: pending
current_phase: null
last_completed_phase: null
halt_reason: null
next_action: "human review — then approve-autonomous shelter-dashboard-v2-c4e8"
artifact_ref:
  branch: null
  plan_path: .agents/plans/shelter-dashboard-v2-c4e8.md
  plan_commit: null
  snapshot_path: .agents/plans/shelter-dashboard-v2-c4e8.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

| Phase | Status | Branch |
|-------|--------|--------|
| 0 | pending | cursor/shelter-dashboard-v2-framing-c4e8 |
| 1 | pending | cursor/shelter-pinned-org-api-c4e8 |
| 2 | pending | cursor/shelter-primary-nav-config-c4e8 |
| 3 | pending | cursor/shelter-shell-primary-nav-c4e8 |
| 4 | pending | cursor/shelter-tile-pin-c4e8 |
| 5 | pending | cursor/shelter-dashboard-body-c4e8 |
| 6 | pending | cursor/shelter-tasks-preview-c4e8 |
| 7 | pending | cursor/shelter-teal-token-audit-c4e8 |
| 8 | pending | cursor/shelter-dashboard-v2-tests-c4e8 |

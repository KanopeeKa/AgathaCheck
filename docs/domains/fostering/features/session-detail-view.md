---
title: Session detail view (foster + shelter lenses)
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-31
tags: [domain, fostering, specs, ui]
domain: fostering
feature_id: session-detail-view
---

# Session detail view

Canonical spec for the **View Session** screen: one fostering session (`foster_placements` row), multiple **viewer lenses** (foster participant vs shelter operator vs read-only history).

**Parent contracts:** [g0-contract-pack.md](g0-contract-pack.md) · [migration-appendix.md](migration-appendix.md) · [foster-placement-lifecycle.md](foster-placement-lifecycle.md)  
**Design UX:** [session-detail-view.md](/docs/design/session-detail-view.md)  
**Navigation / E2E:** [navigation-contract.md](/docs/e2e/navigation-contract.md)

## Problem

Fostering sessions are stored as `foster_placements` but exposed in product copy as **fostering sessions**. Shelter staff have a session detail screen under the org shell; foster carers have pending-invite cards and pet dashboard context but **no dedicated session view** from the pet profile. Actions and documents are split across placement expansion tiles, notifications, and the org sessions list.

## Decision

| Topic | Decision |
|-------|----------|
| Data model | Single table `foster_placements`; no parallel `fostering_sessions` table |
| UI architecture | One **shared session detail composition** with viewer-context-driven sections and actions |
| Flutter entity | Keep `FosterPlacement` until a rename debt issue is scheduled; UI strings use "session" |
| API | Viewer-scoped **session aggregate** read endpoint returns `viewer.role` + `allowed_actions[]` |
| Auth | Enforce on API; client action bar is driven by `allowed_actions`, not role heuristics |

## Viewer contexts

Resolved **server-side** and echoed in the aggregate response.

| `viewer.role` | Who | Typical entry |
|---------------|-----|---------------|
| `foster_participant` | `foster_user_id` on the session | Foster pet profile, pending invite, `/g/fostering` |
| `shelter_operator` | Org member with `manage_fostering_sessions` | Org pet profile, sessions list, placement section |
| `shelter_observer` | Org member with `view_fostering_sessions` only | Sessions list → read-only detail |
| `read_only_history` | Guardian/timeline on **terminal** sessions | Timeline card tap (ended sessions) |

Forbidden: inferring foster vs shelter capabilities from Flutter `AppExperience` alone.

## Routes

| Lens | Route | Shell |
|------|-------|-------|
| Shelter operator / observer | `/o/orgs/:orgId/sessions/:placementId` | Org (`OrgShellScaffold`) |
| Foster participant | `/pet/:petId/fostering-session` | Guardian (`ExperienceShellScaffold`) |
| Legacy alias (redirect) | `/o/orgs/:orgId/placements/:placementId/session` | → canonical org route |

Query param `?placementId=` optional on foster route when pet has multiple historical sessions (v2); v1 assumes at most one **open** session per pet (G0 I4).

## Screen sections (composition order)

Sections render only when data exists and the viewer is permitted to see them.

1. **Alert banner** — `flagged_for_admin_review` (withdrawal, admin flag)
2. **Header** — status chip, session type, pet name, org/foster counterparty
3. **Dates** — `start_date`, `end_date`, `nearly_finished` derived hint
4. **Lifecycle progress** — status-specific (dual-start tiles, adoption-in-progress summary)
5. **Preparation checklist** — template-driven `session_checklist_items`
6. **Documents** — checklist-linked templates + register export (shelter only)
7. **Adoption block** — journey + visits when `foster_in_view_to_adopt` or journey exists
8. **Notes** — participant-visible notes; staff-only notes filtered on foster lens
9. **Footer actions** — from `allowed_actions`

## Actions matrix

`allowed_actions` uses stable snake_case keys. Server is authoritative.

| Action key | Foster | Shelter operator | Observer | History |
|------------|--------|------------------|----------|---------|
| `accept_invite` | ✅ | — | — | — |
| `decline_invite` | ✅ | — | — | — |
| `confirm_foster_start` | ✅ | — | — | — |
| `confirm_shelter_start` | — | ✅ | — | — |
| `transition_preparation` | — | ✅ | — | — |
| `transition_ready_to_start` | — | ✅ | — | — |
| `update_checklist_item` | ✅ subset | ✅ | — | — |
| `register_export` | — | ✅ | — | — |
| `request_end` | — | ✅ | — | — |
| `complete_end_returned` | — | ✅ | — | — |
| `complete_end_cancelled` | — | ✅ | — | — |
| `start_adoption_journey` | — | ✅ | — | — |
| `expedite_visit_adoption` | — | ✅ | — | — |
| `confirm_adoption` | ✅ | ✅ | — | — |
| `complete_adoption_conditions` | — | ✅ | — | — |
| `cancel_adoption` | — | ✅ | — | — |
| `contact_counterparty` | ✅ | ✅ | — | — |
| `edit_session_metadata` | — | ✅ | — | — |

Existing mutation endpoints remain; action keys map to those routes (see §API).

## Status-specific UI

| `session_status` | Foster emphasis | Shelter emphasis |
|------------------|-----------------|------------------|
| `pending_acceptance` | Accept / decline invite | Start preparation / cancel invite |
| `preparation` | Complete assigned checklist items | Mark ready, full checklist admin |
| `ready_to_start` | Confirm foster start | Confirm shelter start |
| `active` | Care dates, contact shelter | Request end, view-to-adopt shortcuts |
| `end_pending_confirmation` | Awaiting handover message | Complete return / cancel |
| `adoption_in_progress` | Confirm adoption when eligible | Manage conditions, cancel journey |
| Terminal | Read-only outcome | Read-only + register export if retained |

## API contract (read aggregate)

### Foster participant

`GET /api/foster-placements/:placementId`

- **Auth:** Bearer; `foster_user_id` must match session (or pending invite to user)
- **403** if not participant

### Shelter

`GET /api/organizations/:orgId/placements/:placementId`

- **Auth:** `view_fostering_sessions` (read) or `manage_fostering_sessions` (read + operator actions in `allowed_actions`)
- Existing detail route evolves to aggregate shape; dual `status` / `session_status` preserved

### Response shape (illustrative)

```json
{
  "session": { "id": "…", "session_status": "active", "status": "in_progress", "…": "…" },
  "viewer": {
    "role": "foster_participant",
    "allowed_actions": ["confirm_foster_start", "update_checklist_item", "contact_counterparty"]
  },
  "pet": { "id": "…", "name": "Buddy", "species": "dog" },
  "organization": { "id": "…", "name": "Rescue Hearts", "contact": { "…": "…" } },
  "counterparty": { "display_name": "…", "contact": { "…": "…" } },
  "checklist": { "items": [], "templates": [] },
  "adoption": null,
  "documents": []
}
```

Field filtering:

- Foster lens: no staff-only foster PII beyond visibility rules; no register export body
- Observer: same fields as operator but `allowed_actions` excludes mutations

### Mutation mapping (unchanged routes)

| Action key | Endpoint |
|------------|----------|
| `accept_invite` | `POST /api/foster-placements/:id/accept` |
| `decline_invite` | `POST /api/foster-placements/:id/decline` |
| `confirm_foster_start` | `POST …/placements/:id/confirm-foster-start` |
| `confirm_shelter_start` | `POST …/placements/:id/confirm-shelter-start` |
| `transition_*` | `POST …/placements/:id/transition` |
| `request_end` | `POST …/placements/:id/request-end` |
| `complete_end_*` | `POST …/placements/:id/end-session` |
| Checklist | Document templates session checklist routes |
| Adoption | Existing adoption journey / placement action routes |

## Pet profile integration

### Shelter (org pet operational profile)

`PetFosterPlacementSection` becomes **summary + deep link**:

- Shows status, foster name, dates
- Primary CTA: **View session** → org session route
- **Start placement** / **Direct adopt** remain here when `not_in_foster` only
- Heavy lifecycle actions move to session detail (reduces duplication with `FosteringSessionDetailScreen`)

### Foster (guardian pet detail)

New **Fostering session** card when user is foster carer for an open session:

- Summary line (status, org name, end date)
- **View session** → guardian session route
- No shelter admin dialogs on guardian shell

### Pending invites

`PendingFosterPlacementCard` → tap opens foster session detail (accept/decline on detail or inline).

### Timeline

- **Open** session segment: tappable → appropriate lens route
- **Ended** session: tappable → `read_only_history` (no action bar)
- Deferred to phase 4 if timeboxed; track in plan debt list

## Permissions cross-reference

| Permission | Session detail capability |
|------------|---------------------------|
| `manage_fostering_sessions` | Shelter operator lens |
| `view_fostering_sessions` | Shelter observer lens |
| (none — foster participant) | Own sessions via foster API auth |
| `view_org_pets` | Does **not** grant session depth (Option B redacted profile) |

## Audit and activity

Session mutations continue to emit G0 audit events (`fostering_session_*`, `session_start_confirmed_*`, etc.) and `pet_activity_events` via `recordFosterSessionActivity`.

## Implementation plan

Tracked in `.agents/plans/session-detail-view-eec3.md`:

1. This document + design companion
2. Backend viewer aggregate + tests
3. Flutter shared composition + shelter refactor
4. Foster routes, pet dashboard entry, BDD

## Out of scope (deferred)

- Rename `FosterPlacement` → `FosteringSession` in Dart
- Auto-create session from foster request acceptance (J2→J3 handoff)
- Session-scoped file uploads beyond checklist/template links
- Timeline tap for open sessions if phase 4 timeboxed

## Acceptance criteria (program)

- [ ] Foster opens session from foster pet profile; cannot perform shelter-only actions
- [ ] Shelter opens same session from org pet; operator actions work
- [ ] Observer sees read-only detail
- [ ] `allowed_actions` matches server enforcement (Jest + widget tests)
- [ ] BDD: `fostering_session_detail.feature` mapped to Playwright

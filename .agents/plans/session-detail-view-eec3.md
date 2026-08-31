# Session detail view — execute-plan

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `session-detail-view-eec3` |
| **title** | Persona-driven fostering session detail (foster + shelter lenses) |
| **author** | cloud-agent |
| **created** | 2026-08-31 |
| **base_branch** | `cursor/session-detail-view-eec3-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Deliver a unified **View Session** experience for fostering sessions (`foster_placements` rows) with **viewer-context composition**: foster participants and shelter operators see the same session shell with different data depth, documents, and actions. Document the model in the fostering domain and design docs; implement backend viewer-scoped read API; refactor the existing org session detail screen; add foster entry from pet dashboard and pending invites.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-31T22:58:00Z |
| **approved_until** | 2026-09-02T22:58:00Z |
| **approved_by** | user chat standing grant (`/execute-plan` + `/ui-design-deep`) |
| **control_issue** | #804 |
| **autonomy** | `active` |

## Phases

### Phase 1 — Design spec + domain documentation

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/session-detail-docs-eec3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/domains/fostering/**
docs/design/**
docs/e2e/navigation-contract.md
docs/architecture/index.md
.agents/plans/session-detail-view-eec3.*
```

**forbidden_paths:**

```
server/**
flutter_app/**
e2e/**
.github/workflows/**
```

**Scope:**

- New `docs/domains/fostering/features/session-detail-view.md` — viewer contexts, sections, actions matrix, API contract
- Update `foster-placement-lifecycle.md`, `journeys.md`, `README.md`, `g0-contract-pack.md` (viewer permissions cross-ref)
- Update `docs/e2e/navigation-contract.md` with foster + shelter session routes
- Optional `docs/design/session-detail-view.md` — UX/a11y notes (tier-2 design deep output)

**Exit criteria:**

- [ ] Session detail spec is canonical for foster vs shelter lenses
- [ ] Domain README and journeys link to new doc
- [ ] Navigation contract lists routes and ready locators

---

### Phase 2 — Backend viewer-scoped session API

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/session-detail-api-eec3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**allowed_paths:**

```
server/lib/sessionDetail.js
server/lib/fosterSessions.js
server/lib/fosterPlacements.js
server/routes/fosterPlacements.js
server/routes/organizations/placements/**
server/test/sessionDetail.test.js
server/test/fosterPlacements.test.js
server/test/organizations/sessions/**
docs/domains/fostering/features/session-detail-view.md
.agents/plans/session-detail-view-eec3.*
```

**forbidden_paths:**

```
flutter_app/**
e2e/**
.github/workflows/**
db/migrations/**
```

**Scope:**

- `GET /api/foster-placements/:id` (foster participant) and/or viewer-aware org placement detail
- Response: `session`, `viewer` (`role`, `allowed_actions`), filtered `counterparty`, `checklist`, `adoption` summary
- Auth matrix tests (foster own session, shelter manage/view, forbidden cross-org)

**Exit criteria:**

- [ ] Foster can load own open session aggregate; shelter admin retains full detail
- [ ] `allowed_actions` drives client action bar
- [ ] Jest coverage for auth + field filtering

---

### Phase 3 — Flutter shared session detail + shelter refactor

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/session-detail-flutter-shelter-eec3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/fostering_session/**
flutter_app/lib/features/organization/presentation/screens/fostering_session/**
flutter_app/lib/features/organization/presentation/widgets/fostering_session/**
flutter_app/lib/features/organization/presentation/providers/fostering_session_providers.dart
flutter_app/lib/features/organization/data/**
flutter_app/lib/features/organization/domain/**
flutter_app/lib/core/router/organization_routes.dart
flutter_app/lib/l10n/**
flutter_app/test/features/organization/**
flutter_app/test/features/fostering_session/**
docs/domains/fostering/features/session-detail-view.md
.agents/plans/session-detail-view-eec3.*
```

**forbidden_paths:**

```
server/**
e2e/**
.github/workflows/**
```

**Scope:**

- Extract shared `SessionDetailBody` + section widgets from `FosteringSessionDetailScreen`
- `SessionViewerContext` from API `viewer` block
- Refactor shelter screen to thin shell; behaviour parity with current admin/foster actions

**Exit criteria:**

- [ ] Existing fostering session detail tests green
- [ ] No regression on shelter lifecycle actions
- [ ] File size ≤500 lines per hand-written file

---

### Phase 4 — Foster lens + pet dashboard entry + BDD

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/session-detail-foster-entry-eec3` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
flutter_app/lib/features/fostering_session/**
flutter_app/lib/features/pet_profile/**
flutter_app/lib/features/experience/**
flutter_app/lib/core/router/**
flutter_app/lib/l10n/**
flutter_app/test/**
e2e/playwright/tests/fostering.session*.ts
e2e/playwright/pages/**
e2e/playwright/support/api.ts
scripts/bdd-priority-tag-map.json
docs/e2e/navigation-contract.md
docs/domains/fostering/**
docs/quality/bdd-journey-matrix.md
.agents/plans/session-detail-view-eec3.*
```

**forbidden_paths:**

```
server/**
.github/workflows/**
db/**
```

**Scope:**

- Guardian route `/pet/:petId/fostering-session` (or `/g/pets/:petId/session`)
- Foster lens on shared session detail; pending invite → detail
- Slim `PetFosterPlacementSection` to summary + View session (shelter); foster card on pet detail
- BDD `fostering_session_detail.feature` + Playwright `@P1` scenarios
- Timeline open-session tap (optional debt if timeboxed)

**Exit criteria:**

- [ ] Foster opens session from foster pet profile; cannot perform shelter-only actions
- [ ] Shelter opens same session from org pet; full operator actions
- [ ] BDD mapped; `./scripts/pre-push-changed.sh` green

---

## Runtime state

```yaml
autonomy: active
current_phase: 3
last_completed_phase: 2
halt_reason: null
next_action: "start phase 3: checkout cursor/session-detail-flutter-shelter-eec3"
artifact_ref:
  branch: cursor/session-detail-view-eec3-integration
  plan_path: .agents/plans/session-detail-view-eec3.md
  plan_commit: 5cbc919da76cc7e7bbb2735b1642b0dc365e14fc
  snapshot_path: .agents/plans/session-detail-view-eec3.snapshot.json
  snapshot_commit: 5cbc919da76cc7e7bbb2735b1642b0dc365e14fc
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check

**Output:** `proceed` — four atomic phases, integration branch, docs-first; no migrations or CI workflow changes.

# Plan — Fostering platform Wave C (J4 gate + G1 UI + fostering BDD)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `fostering-platform-wave-c-e877` |
| **title** | Wave C — visit-path gate, G1 wiring, fostering Playwright |
| **author** | agent (user-refined 2026-07-25) |
| **created** | 2026-07-25 |
| **base_branch** | `cursor/fostering-platform-wave-c-e877-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Close Wave B follow-ups (#362) in **one integration branch → one PR to `main`**:

1. Simplify adoption visits to a single `visit_outcome` field; enforce visit-path gate before J5 journey start.
2. Wire G1 session checklist (foster readiness / compliance), adoption milestones, and register export (minimal UI).
3. Map all 6 fostering BDD scenarios to robust, API-first Playwright specs.
4. Clarify G0 I3/I4 and visit vs session-readiness semantics.

**Out of scope:** non-fostering BDD backlog; full J4 visit UX; direct-adopt shortcut; subscriptions E2E.

## Policy decisions (frozen — user confirmed 2026-07-25)

| Topic | Decision |
|-------|----------|
| Visit path | **Only** `session_type = foster_in_view_to_adopt` requires visit gate |
| Visit record | **One field:** `visit_outcome` (`positive` \| `negative` \| `no_show`); drop `outcome` + `validation_status` + validate endpoint |
| Journey gate | At least one visit for the session with `status = completed` **AND** `visit_outcome = positive` |
| Negative visit | Does **not** disqualify the foster permanently; journey remains blocked until a **later** visit records `visit_outcome = positive` |
| Foster readiness | **Separate** from visit outcome — G1 session checklist (forms, contracts, register items) on the fostering session |
| Same-day expedite | **(B) Explicit admin action** — e.g. “Complete visit & start adoption today” — runs all gate predicates atomically (visit outcome + journey start); not silent auto-detect |
| Concurrent sessions | One foster may hold multiple active sessions on **different pets** (I3/I4 clarified) |
| G1 | Session checklist + adoption milestones + register export in one wave |
| E2E | API-first; minimal UI; 6 fostering scenarios only |
| UI depth | Minimal — dashboard review follows later |

### Two different “validations” (do not conflate)

| Concept | What it means | Where it lives |
|---------|---------------|----------------|
| **Adoption visit outcome** | Did the adoption visit go well? (`visit_outcome`) | `adoption_visits` row |
| **Foster / session readiness** | Contracts signed, docs delivered, register entry, etc. | G1 `session_checklist_items` on fostering session |

A negative `visit_outcome` does not revoke foster approval; it only blocks **this** adoption path until a positive visit exists.

### Visit model (target)

```
adoption_visits:
  status: scheduled | completed | cancelled
  visit_outcome: null (until completed) | positive | negative | no_show
  -- removed: outcome, validation_status, validated_at, validated_by
```

Audit: keep `adoption_visit_outcome_recorded`; remove `adoption_visit_validated` (or map to outcome_recorded only).

### Same-day expedite (option B)

New orchestration endpoint or action, e.g.:

`POST …/placements/:id/adoption-path/complete-visit-and-start`

 Preconditions (all checked, none skipped):

1. Session `session_type = foster_in_view_to_adopt`, eligible status
2. Visit exists for session (or created in same request with `scheduled_at` today)
3. Sets `visit_outcome = positive`, `status = completed`
4. `assertVisitPathSatisfied` passes
5. `startAdoptionJourney` runs in same transaction

Calendar constraint: all involved dates (`scheduled_at`, outcome recorded_at) share today's `YYYY-MM-DD`.

## Autonomy (pending approval)

| Field | Value |
|-------|-------|
| **approved_at** | _(pending)_ |
| **approved_until** | _(pending — approved_at + 48h)_ |
| **control_issue** | _(pending — bootstrap on approval)_ |
| **content_hash** | _(set at freeze)_ |
| **autonomy** | `halted` |

**Grant keyword:** `approve-autonomous fostering-platform-wave-c-e877`

## Phases

### Phase 1 — Contract + G0 doc fixes

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/wave-c-g0-contract-e877` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**Scope:**

- Fix **I3**: one session *model*; foster may have **multiple concurrent sessions** (different pets).
- **I4**: at most one non-terminal session per pet; same-calendar-day end + start allowed.
- §5.5–5.6: `visit_outcome` semantics; gate predicate; separate from G1 session checklist.
- Update `fostering_platform.feature` scenario 3 title/steps: “positive visit outcome” not “validated”.
- Mark `pet adoptability` in §4.2 deferred / not implemented.

**Exit criteria:**

- [ ] G0 I3/I4 and visit vs readiness distinction documented
- [ ] BDD scenario text aligned with `visit_outcome`

---

### Phase 2 — Visit model simplification + J4 gate (backend)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/wave-c-j4-visit-gate-e877` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `single-backend-route` |

**Scope:**

- Migration `032`: rename `outcome` → `visit_outcome`; drop `validation_status`, `validated_at`, `validated_by`
- `adoptionVisits.js`: single `recordVisitOutcome` → sets `visit_outcome` + `status = completed`
- Remove `validateAdoptionVisit` and `POST …/validate` route
- `hasPositiveVisitForSession` / `assertVisitPathSatisfied` — gate on `completed` + `visit_outcome = positive`
- Call gate from `startAdoptionJourney` when `foster_in_view_to_adopt`
- **Expedite endpoint** (option B): atomic complete-visit-and-start (same calendar day)
- Jest: visit outcomes, gate block/allow, negative then positive visit, expedite action
- Update Flutter visit list field names in phase 4 (or stub compatibility in API map layer)

**Exit criteria:**

- [ ] Single `visit_outcome` column; validate route removed
- [ ] Journey blocked without positive visit; allowed after positive (including after prior negative)
- [ ] Expedite endpoint runs full gate chain atomically
- [ ] Jest green

---

### Phase 3 — G1 Flutter wiring (minimal)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/wave-c-g1-flutter-e877` |
| **spawn_allowed** | `true` (optional: checklist vs milestones subagents) |
| **exit_checklist** | `flutter-screen-split` |

**Scope:**

- Replace `FosteringSessionPreparationChecklist` placeholder with API-driven G1 session checklist
- Adoption journey detail: milestone checklist from templates API
- Register export: minimal download/share action
- Repository + remote: `patchSessionChecklistItem`, milestone patch, register export
- Widget tests; l10n EN/FR

**Exit criteria:**

- [ ] Session checklist toggles from org templates (foster readiness — separate from visit)
- [ ] Journey milestones visible
- [ ] Register export callable

---

### Phase 4 — J4 minimal visit UI

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/wave-c-j4-visit-ui-min-e877` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**Scope:**

- Record `visit_outcome` (positive / negative / no_show) on visit row — minimal UI
- **Expedite button** (option B): “Complete visit & start adoption today” → expedite endpoint
- Standard “Start adoption” disabled or error when visit gate unsatisfied
- E2E still seeds via API where faster

**Exit criteria:**

- [ ] Admin can set visit outcome from UI
- [ ] Expedite action visible and wired
- [ ] Gate errors surfaced on premature journey start

---

### Phase 5 — Fostering BDD Playwright

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/wave-c-fostering-e2e-e877` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**Scope:**

- `api.ts`: eligible targets, capacity, view-to-adopt session, visit helpers (`visit_outcome`), expedite, journey start, manual foster
- `fostering.platform.spec.ts` (3) + `foster.onboarding.spec.ts` (3)
- `manage-fosters.page.ts` (thin)
- `bdd-journey-matrix.md` fostering section
- WAF-safe: `prepareLiveApiAccess`, API-first asserts

**Exit criteria:**

- [ ] 6 scenarios mapped (134/186)
- [ ] Visit-path scenario uses positive `visit_outcome` + journey assert
- [ ] Local subset green

---

### Phase 6 — Integration merge to main

| Field | Value |
|-------|-------|
| **id** | `6` |
| **branch** | `cursor/fostering-platform-wave-c-e877-integration` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**Scope:**

- Rebase integration → `origin/main`
- `./scripts/pre-push.sh`
- Single PR → `main`; `/babysit-plus`; resolve #362

**Exit criteria:**

- [ ] One PR merged
- [ ] CI green

## Spawn (optional phase 3)

| Agent | Owns | Avoid |
|-------|------|-------|
| g1-session | session checklist + register export entry | journey screen |
| g1-journey | adoption milestones + expedite hook placement | session checklist |

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "start phase 2: checkout cursor/wave-c-j4-visit-gate-e877"
artifact_ref:
  branch: cursor/wave-c-g0-contract-e877
  plan_path: .agents/plans/fostering-platform-wave-c-e877.md
  plan_commit: 3fee5bed5ac9af1164a2899997e593114104f19a
  snapshot_path: .agents/plans/fostering-platform-wave-c-e877.snapshot.json
  snapshot_commit: 3fee5bed5ac9af1164a2899997e593114104f19a
open_prs: []
merge_commits: {}
debt_issue_refs: [362]
```

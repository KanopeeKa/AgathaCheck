---
title: Care Progression — Delivery Plan
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-09-09
tags: [pet_care, care_progression, delivery]
---

# Care Progression — Delivery Plan

**Canonical product behaviour:** [care-progression.md](../features/care-progression.md)  
**Predecessor programme:** [care-foundation-roadmap.md](./care-foundation-roadmap.md) (Phases A–E)  
**Entitlements (principles):** [care-entitlements.md](../features/care-entitlements.md)

**Status:** Draft for review — **no runtime implementation until approved.**

---

## 0. How to use this document

| Kind | Location |
|------|----------|
| Durable product rules | `../features/care-progression.md` |
| CIM / safeguards | `../features/care-intelligence.md` |
| This file | Time-bound CP-0–CP-7 mechanics — archive or trim after V1 ship; extract durable conclusions into the feature doc first |
| Future execute-plan | `.agents/plans/care-progression-<id>.md` — created when implementation is authorised |

---

## 1. Programme goal

Deliver Care Progression V1: **Established** maturity (weight monitoring first) and **Milestones**, built on clean weight occurrence ↔ observation evidence, with server-authoritative evaluation and centralised presentation arbitration.

**V1 proves the architecture** without seasonal progression, generic observation migration, multi-family long-horizon evaluation, or paywall runtime.

---

## 2. Prerequisites

Care Progression starts **only after** the Care Foundation / CIM programme completes **Phase E** (guardian safeguards) and merges to `main`.

```text
Care Foundation A–C  ✅ (on main)
Phase D            ✅ (on main, internal)
Phase E            ⏳ ship + merge
        ↓
CP-0 … CP-7        Care Progression V1
```

**During Phase E:** CP-0 may be **prepared conceptually** (this document) but **not implemented in parallel**.

**Phase E handoff requirement:** Phase E must implement a **minimal safeguard slot** in presentation arbitration (safeguard beats suggestion). CP-6 consolidates into full `care_presentation` without changing safeguard priority.

---

## 3. Frozen decisions (architecture review — 2026-09-09)

Unless code review reveals a genuine contradiction, treat these as fixed:

| # | Decision |
|---|----------|
| 1 | **Phase E first**, then Care Progression |
| 2 | User-facing marker **Established**; softer copy e.g. **“Part of {name}’s regular care”** |
| 3 | Rename old “established = recurring exists” terminology before progression ships |
| 4 | **Server-authoritative** progression only |
| 5 | Explicit **`care_family` on write** for recurring entries; `other` not null |
| 6 | Weight occurrence completion **requires** linked real weight observation |
| 7 | Accepting weight rhythm suggestion creates **rhythm only** — no invented observation |
| 8 | Standalone weight entries remain allowed (`health_occurrence_id` null) |
| 9 | **Ignore** legacy weak completion for V1 Establishment |
| 10 | **Skip** allowed on weight occurrences; skips are **neutral** (non-counting) |
| 11 | Milestones are **shared pet history**; presentation is **per-user** |
| 12 | Combined moment when `first_care_established` + family milestone coincide |
| 13 | Timeline in **late V1** (CP-7); first deferrable slice under pressure |
| 14 | `medication_course_completed` → **V1.1**, not initial ship |
| 15 | Shared observation **primitives**; **separate** CIM vs Progression thresholds |
| 16 | Progression does **not** consume review-relevance output |
| 17 | No negative maturity UI; ambiguous history → silence |
| 18 | Pausing/ending rhythm does not erase historical establishment |
| 19 | Domain map is **normative**; folder migration is **incremental** |
| 20 | Pre-production cleanup preferred; **checkpoint** before destructive actions |

---

## 4. Domain architecture (target)

Normative module map — implement incrementally, not as a big-bang refactor:

```text
care_core
  CareFamily, CareSource, capability registry, shared enums, policy version types

care_planning
  health_entries, health_occurrences, Care Status, recurrence (existing health_tracking + pet_profile services)

care_observations
  weight_entries, measurement provenance, observation quality primitives

care_progression
  establishment evaluator, milestones, dedupe_key, read APIs

care_intelligence
  suggestions, review relevance, safeguards (existing care_intelligence)

care_presentation
  PetCarePresentationPolicy (hoisted), contextual slots, throttle

care_entitlements
  principles only in V1 — see care-entitlements.md
```

### Dependency direction

```text
care_core
   ↑
planning       observations
   ↑              ↑
   └──── progression
   └──── intelligence (no dep from progression → intelligence)
             ↓
      presentation
```

### Incremental repo mapping (pragmatic)

| Target | V1 home (initial) | Migrate when |
|--------|-------------------|--------------|
| `care_core` | `server/lib/care/` + `flutter_app/lib/features/pet_care/core/` | CP-1 |
| `care_observations` | Extract from `careIntelligence/weightQualityClassifier.js`; `weight_entries` routes | CP-1–CP-2 |
| `care_progression` | `server/routes/careProgression/` + `flutter_app/lib/features/pet_care/progression/` | CP-3–CP-5 |
| `care_presentation` | Hoist from `care_intelligence/domain/services/pet_care_presentation_policy.dart` | CP-6 |
| `care_planning` | Keep in `health_tracking` / `pet_profile` | Ongoing |

---

## 5. Slice overview

```text
CP-0  Docs + naming + care_family write-path + data audit
CP-1  Shared care core/capabilities + server authority seams
CP-2  Weight occurrence ↔ observation transactional completion (+ FK)
CP-3  Weight establishment evaluator + persist transition
CP-4  Milestone persistence + idempotency + per-user presentation
CP-5  Care Rhythms Established marker
CP-6  Profile/dashboard presentation arbitration
CP-7  Timeline milestone integration

V1.1  medication_course_completed milestone
```

Each slice = one verifiable outcome (atomic PR policy). Merge to `main` when green.

---

## CP-0 — Architecture cleanup & write-path foundation

### Goal

Remove terminology collisions, fix `care_family` write path, audit data, confirm pre-production status — **no progression runtime**.

### Deliverables

| Item | Detail |
|------|--------|
| Feature doc | `care-progression.md` (this programme’s canonical spec) |
| Delivery plan | This document — approved after review |
| Entitlements principles | `care-entitlements.md` |
| Terminology glossary | Old → new mapping (see feature doc) |
| Rename | `hasEstablishedRhythm` → `hasActiveRecurringCare` (+ tests, docs, UI strings for “recurring care”) |
| Consolidate `CARE_FAMILIES` | Single canonical export in `server/lib/care/enums.js`; CIM imports subset |
| `care_family` write path | Recurring entries require explicit family on API; Flutter family-aware add flow for rhythms (at minimum weight + generic picker for recurring) |
| Data audit script | Report: null/inferred/`other` families, recurring without occurrences, preventive rows |
| Pre-production gate | `confirm_pre_production` checklist — if live, reassess cleanup before destructive reset |
| Roadmap pointer | Care Foundation roadmap § successor programme |

### Migrations

None for progression tables. Optional: dev/staging data cleanup SQL (pre-prod only).

### API changes

- `POST/PATCH health_entries`: reject recurring writes without valid `care_family` (400).
- Read path: keep inference fallback for legacy rows only.

### Tests

- API validation: recurring without `care_family` → 400.
- Rename regression: suggestion suppressor still uses `hasActiveRecurringCare`.
- Audit script runs in CI report-only mode (optional).

### Exit criteria

- [ ] Glossary and docs approved.
- [ ] No user-facing “established” meaning “recurring exists”.
- [ ] Recurring create path sends explicit `care_family` from Flutter.
- [ ] Audit report reviewed; cleanup plan documented.
- [ ] Pre-production checkpoint signed off.

### Out of scope

Progression tables, establishment logic, milestone UI.

---

## CP-1 — Shared care core & authority seams

### Goal

Introduce shared server modules and Flutter `pet_care/core` without behaviour change to guardians.

### Deliverables

| Item | Detail |
|------|--------|
| `server/lib/care/enums.js` | `CARE_FAMILIES`, `CARE_SOURCES`, wire validators |
| `server/lib/care/capabilities.js` | `CareFamilyCapabilityPolicy` — code-defined matrix |
| `server/lib/care/observations/primitives.js` | Valid weight, unit, timestamp helpers |
| Move (no logic change) | `weightQualityClassifier.js` → `server/lib/care/observations/weightQuality.js`; CIM re-imports |
| Flutter `pet_care/core/` | Capability mirror + contract test or shared enum sync |
| Stub route | `GET /api/pets/:petId/care-progression` → `{ establishment: [], milestones: [] }` (auth + capability check) |
| Move types (optional) | `weight_provenance.dart` toward `pet_care/core/` or `pet_care/observations/` |

### Migrations

None.

### Exit criteria

- [ ] Single `CARE_FAMILIES` source on server.
- [ ] CIM tests pass after weight quality move.
- [ ] Capability policy unit tests per family.
- [ ] Stub progression read endpoint returns 200 for authorised guardian.

---

## CP-2 — Weight occurrence ↔ observation completion

### Goal

Transactional completion: real weight entry + occurrence complete, idempotent, FK-linked.

### Deliverables

| Item | Detail |
|------|--------|
| Migration | `weight_entries.health_occurrence_id UUID NULL REFERENCES health_occurrences(id)`; partial unique index `WHERE health_occurrence_id IS NOT NULL` |
| Endpoint | `POST /api/pets/:petId/care-rhythms/:entryId/complete-weight-occurrence` (or equivalent under `health_entries`) |
| Behaviour | Validates `care_family = weight_monitoring`; creates `weight_entry`; completes occurrence; single transaction |
| Idempotency | Repeat request with same occurrence returns existing linked weight (200, no duplicate) |
| Block generic complete | Weight monitoring entries with pending occurrences cannot use generic mark-complete without weight payload |
| Flutter | Weight rhythm “mark done” → `AddWeightEntrySheet` bound to occurrence; not generic date-only sheet |
| Skip | Existing skip path unchanged; documented as non-counting for progression |

### Request body (illustrative)

```json
{
  "occurrence_id": "uuid",
  "weight": 18.2,
  "unit": "kg",
  "date": "2026-09-09",
  "measurement_source": "guardian",
  "notes": ""
}
```

### Response (illustrative)

```json
{
  "weight_entry": { "id": "...", "health_occurrence_id": "..." },
  "occurrence": { "id": "...", "status": "completed" },
  "next_due_date": "2026-10-09"
}
```

### Tests

- Happy path: weight + occurrence completed atomically.
- Idempotent retry.
- Wrong family → 400/422.
- Generic complete blocked for weight_monitoring with open occurrence.
- Skip does not create weight row.
- Agatha accept flow still creates rhythm only; occurrences materialised for first due.

### Exit criteria

- [ ] FK migration applied.
- [ ] E2E or integration test: due weight rhythm → record weight → occurrence completed.
- [ ] Standalone weight add still works (`health_occurrence_id` null).

---

## CP-3 — Weight establishment evaluator

### Goal

Server evaluates weight monitoring maturity; persists transition to Established only.

### Deliverables

| Item | Detail |
|------|--------|
| Migration | `care_establishment_states` (see schema below) |
| Policy | `server/lib/care/progression/weightEstablishmentPolicy.js` — cadence-relative, versioned |
| Evaluator | `evaluateWeightEstablishment(petId, healthEntryId, facts)` → result + reason codes |
| Triggers | CP-2 completion endpoint; optional internal `POST .../care-progression/re-evaluate` (admin/dev) |
| Read API | Extend `GET .../care-progression` with establishment DTOs |
| Flutter | Provider consumes server DTO only — no local evaluation |

### `care_establishment_states` (illustrative)

```sql
CREATE TABLE care_establishment_states (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  care_family VARCHAR(50) NOT NULL,
  health_entry_id UUID NOT NULL REFERENCES health_entries(id) ON DELETE CASCADE,
  established_at TIMESTAMPTZ NOT NULL,
  policy_version VARCHAR(20) NOT NULL,
  dedupe_key VARCHAR(100) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (pet_id, dedupe_key)
);
```

`dedupe_key` example: `weight_monitoring:{health_entry_id}`.

### Policy inputs

- Active recurring `weight_monitoring` entry (not ended/paused — lifecycle rules documented).
- Linked completed occurrences with valid weight FKs only.
- Cadence band from entry frequency/interval.
- Progression quality primitives (not CIM `QUALITY_THRESHOLDS` wholesale).

### Policy output

```text
{ maturity: null | 'established', reasonCodes: [], policyVersion: '1.0.0' }
```

Persist row **only** on first transition to `established`. Never downgrade on miss or weight delete (V1).

### Tests

- Golden vectors: eligible / not yet / insufficient evidence / ambiguous family → silence.
- Reactivation: skip occurrences do not count.
- Legacy mark-taken ignored.
- Policy version recorded on persist.

### Exit criteria

- [ ] Establishment persists on eligible weight rhythm.
- [ ] No UI marker yet (API/provider only acceptable).
- [ ] DATA_MAP delta drafted for establishment table.

---

## CP-4 — Milestone persistence & idempotency

### Goal

Durable milestones with server dedupe; per-user presentation state; combined-moment bundle rule.

### Deliverables

| Item | Detail |
|------|--------|
| Migrations | `care_milestones`, `care_milestone_presentations` (schemas below) |
| Service | `CareMilestoneService` — `computeDedupeKey()`, idempotent create |
| Milestones V1 | `weight_monitoring_established`, `first_care_established` |
| Trigger | On establishment transition: create family milestone; if first family ever, also `first_care_established` |
| Presentation query | `GET .../care-progression/pending-moments` — respects per-user shown state + 30-day throttle |
| Combined moment | Single DTO when both created same run; family anchor + secondary copy flag |

### `care_milestones` (illustrative)

```sql
CREATE TABLE care_milestones (
  id UUID PRIMARY KEY,
  pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
  milestone_type VARCHAR(50) NOT NULL,
  care_family VARCHAR(50),
  source_entity_id UUID,
  care_period_key VARCHAR(50),
  dedupe_key VARCHAR(100) NOT NULL,
  achieved_at TIMESTAMPTZ NOT NULL,
  policy_version VARCHAR(20) NOT NULL,
  bundle_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (pet_id, dedupe_key)
);
```

### `care_milestone_presentations` (per-user)

```sql
CREATE TABLE care_milestone_presentations (
  id UUID PRIMARY KEY,
  milestone_id UUID NOT NULL REFERENCES care_milestones(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shown_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (milestone_id, user_id)
);
```

Throttle: max one **prominent** moment per pet per user per 30 days (query layer).

### Dedupe keys (frozen)

| Milestone | `dedupe_key` |
|-----------|----------------|
| `weight_monitoring_established` | `weight_monitoring_established:{health_entry_id}` |
| `first_care_established` | `first_care_established` |

### Tests

- Re-eval job does not duplicate.
- Same-run bundle groups milestones.
- User A shown ≠ suppress User B.
- Throttle defers second moment within 30 days but persists both rows.

### Exit criteria

- [ ] Milestones created idempotently on establishment.
- [ ] Pending-moments API returns correct bundle.
- [ ] DATA_MAP updated for milestone tables.

---

## CP-5 — Care Rhythms Established marker

### Goal

Quiet inline **Established** marker on eligible rhythm rows (weight monitoring V1).

### Deliverables

| Item | Detail |
|------|--------|
| Flutter | `CareRhythmRow` shows muted “Established” when server DTO says so |
| Copy | Marker: “Established”; avoid combining with due line in one chip |
| l10n | EN + FR strings |
| Widget test | Established + due soon — due primary, marker secondary |

### Exit criteria

- [ ] Weight monitoring rhythm shows marker when established.
- [ ] No marker when API returns null maturity.
- [ ] No profile header marker (per spec).

---

## CP-6 — Presentation arbitration

### Goal

Central contextual card slot: safeguard > suggestion > milestone > prompt.

### Deliverables

| Item | Detail |
|------|--------|
| Hoist | `PetCarePresentationPolicy` → `pet_care/presentation/` |
| API | Compose profile/dashboard slot from server or client orchestration of server DTOs (prefer server `GET .../care-overview` if needed) |
| Milestone moment UI | Warm, restrained card; combined copy for first+care family |
| Throttle | Enforce 30-day presentation window per user per pet |
| Phase E compat | Safeguard slot preserved from Phase E — priority unchanged |
| Dashboard | Max one progression moment across pets |

### Exit criteria

- [ ] Safeguard beats milestone in widget tests.
- [ ] Suggestion beats milestone when no safeguard.
- [ ] Milestone marks `care_milestone_presentations` on dismiss/show.
- [ ] Dashboard respects single-slot rule.

---

## CP-7 — Timeline integration

### Goal

Persistent milestones visible in pet care history / timeline.

### Deliverables

| Item | Detail |
|------|--------|
| Timeline event type | `care_milestone` (or extend pet activity with stable schema) |
| UI | Milestone entries in history/timeline with descriptive copy |
| BDD | Optional scenario mapping (if product requests) |

### Exit criteria

- [ ] Achieved milestones appear in timeline for all authorised guardians.
- [ ] Presentation moment and timeline entry are distinct (moment ephemeral, timeline durable).

### Deferral note

First slice to push if schedule pressure — milestones still persist from CP-4.

---

## V1.1 — Medication course completed (post initial ship)

### Goal

Episode-keyed milestone using bounded series semantics.

### Deliverables

- `medication_course_completed` dedupe: `medication_course_completed:{health_entry_id}`
- Detector: series `status = completed` or `repeat_end_date` reached with completion evidence
- Milestone moment + timeline entry
- Capability flag already on `medication` family

### Prerequisite

Clear bounded-course semantics documented in `care_planning` (no progression ambiguity).

---

## 6. API summary (V1)

| Method | Path | Phase | Purpose |
|--------|------|-------|---------|
| `GET` | `/api/pets/:petId/care-progression` | CP-1+ | Establishment + milestones read model |
| `GET` | `/api/pets/:petId/care-progression/pending-moments` | CP-4 | Per-user presentation candidates |
| `POST` | `/api/pets/:petId/care-rhythms/:entryId/complete-weight-occurrence` | CP-2 | Transactional weight completion |
| `POST` | `/api/pets/:petId/care-progression/re-evaluate` | CP-3 | Internal/dev re-evaluation (auth gated) |

Exact paths may follow existing `health_entries` router conventions — finalise in CP-1 design note.

---

## 7. Testing strategy

| Layer | Coverage |
|-------|----------|
| Unit | Policies, dedupe keys, capability matrix, presentation throttle |
| Server integration | CP-2 transaction, CP-3/4 idempotency |
| Flutter widget | Rhythm marker, presentation slot priority |
| E2E (targeted) | Weight due → record → established path (late CP-5+) |
| Negative | No negative maturity UI; ambiguous data → no marker; skip non-counting |

Run `./scripts/pre-push-changed.sh` per PR. BDD mapping when CP-7 scenarios exist.

---

## 8. Regulatory & privacy

Before CP-4 merge to `main`:

- Update [DATA_MAP.md](/regulatory/DATA_MAP.md) for `care_establishment_states`, `care_milestones`, `care_milestone_presentations`, `weight_entries.health_occurrence_id`.

---

## 9. Explicit deferrals (not V1)

- Seasonal milestones, geography/climate engine
- Progress rings, care chapters, badge collections
- Generic `care_observations` store migration
- Device/partner integrations
- Paywall / entitlement runtime
- Long-horizon vaccination/wellness/parasite **evaluation**
- Progression consuming CIM review-relevance
- Guardian legacy classification/repair flows (pre-prod cleanup instead)
- Re-establishment epoch after multi-year gap
- Revoking establishment on weight delete
- `medication_course_completed` in initial V1 ship
- New Progress tab / progression feed
- Multi-family establishment markers in UI (weight only V1)

---

## 10. Future execute-plan (placeholder)

When implementation is authorised after Phase E merge:

| Field | Proposed value |
|-------|----------------|
| `plan_id` | `care-progression-v1` |
| `canonical spec` | `docs/domains/pet_care/features/care-progression.md` |
| `delivery plan` | this document |
| `base_branch` | `main` |
| `phases` | CP-0 … CP-7 mapped to execute-plan phases |
| `control_issue` | TBD — create when programme starts |

Autonomy grant is **not** part of this draft — request separately before CP-0 implementation.

---

## 11. Definition of done (programme V1)

Care Progression V1 is complete when:

1. CP-0 through CP-6 merged (CP-7 unless explicitly deferred with sign-off).
2. Weight monitoring can become Established via linked occurrence evidence only.
3. Milestones persist idempotently; moments respect per-user throttle and safeguard priority.
4. Care Rhythms show Established marker for weight.
5. Server authority invariant enforced (no client-side maturity).
6. Docs and DATA_MAP current.
7. No regression to Care Status, CIM suggestions, or Phase E safeguards.

---

## Appendix A — Terminology rename checklist (CP-0)

| Location | Action |
|----------|--------|
| `server/routes/careIntelligence/ruleEngine.js` | Rename function + comments |
| `server/test/careIntelligence/recommendations.test.js` | Update test names/descriptions |
| `flutter_app/.../pet_care_rhythms_screen.dart` | Doc comment |
| `flutter_app/.../care_source.dart` | Doc comment |
| `flutter_app/.../care_source_labels.dart` | Doc comment |
| `flutter_app/.../care_suggestion_card.dart` | Doc comment |
| `docs/domains/pet_care/changes/care-foundation-roadmap.md` | “recurring care” where meaning is existence not maturity |
| l10n | Audit “established” strings — split progression vs recurring |

---

## Appendix B — Data audit queries (CP-0)

Run against dev/staging before establishment enablement:

```sql
-- Recurring entries missing explicit care_family (post write-path fix, should trend to zero)
SELECT COUNT(*) FROM health_entries WHERE frequency != 'once' AND care_family IS NULL;

-- Recurring with care_family = other (semantic ambiguity)
SELECT care_family, type, COUNT(*) FROM health_entries
WHERE frequency != 'once' GROUP BY 1, 2;

-- Weight monitoring rhythms (target population)
SELECT COUNT(*) FROM health_entries
WHERE frequency != 'once' AND care_family = 'weight_monitoring';
```

Extend audit script with occurrence coverage and preventive row counts.

---

## Appendix C — Presentation copy templates (draft)

**Established marker (rhythm row):** `Established`

**Milestone moment (family):**  
Title: *A little milestone*  
Body: *{petName}’s regular weight monitoring is now established.*

**Combined (first + family):**  
Body: *{petName}’s regular weight monitoring is now established — the first care rhythm to become part of {possessive} routine.*

Localise in CP-5/CP-6.

---

*End of Care Progression Delivery Plan (draft for review)*

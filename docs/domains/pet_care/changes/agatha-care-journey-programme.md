---
title: Agatha care journey programme
owner: Product / Documentation
audience: both
domain: pet_care
status: proposed
status_since: 2026-10-10
folds_into:
  - docs/domains/pet_care/features/care-intelligence.md
  - docs/domains/pet_profile/features/pet-profile-decisions.md
related_plan: .agents/plans/agatha-care-journey.md
tags: [pet_care, pet_profile, care_intelligence, roadmap, execute-plan]
---

# Agatha care journey programme

Frozen programme for **`agatha-care-journey`** execute-plan. One integration branch, **atomic PRs PR-01 … PR-14**, progressive delivery. Features are **not** hard-blocked on each other except where `Depends` is stated — parallel **Care Schedule Management (CSM)** work continues on existing plans.

## Executive summary

AgathaTrack should help pet parents **know** (accurate profile facts), **understand** (quiet welfare and rhythm guidance), **plan** (independent care items and later coordination), **act** (Actions / occurrences), and **remember** (history that closes recommendation loops).

This programme:

1. Fixes **profile fact** persistence (chip / neuter / vaccination status) before advocacy cards.
2. Replaces inset completeness rows with **Agatha completeness cards** (shared chrome, profile actions — not rhythm Accept).
3. Introduces a **welfare suggestion** layer (distinct from Phase C rhythm `care_recommendations`).
4. Strengthens **recommendation ↔ history** feedback.
5. Adds **schedule presentation** grouping and **coordination copy** without merging care items.
6. Defers **visit entity** UI until PR-14 schema/API slice is approved.

**Execute-plan:** [`.agents/plans/agatha-care-journey.md`](../../../.agents/plans/agatha-care-journey.md)  
**UI (design deep):** [`agatha-care-journey-ui-design.md`](./agatha-care-journey-ui-design.md)  
**BDD / TDD / QA:** [`agatha-care-journey-bdd-qa.md`](./agatha-care-journey-bdd-qa.md)

## Product journey (north star)

```text
Profile facts → Agatha surfaces (completeness | welfare | rhythm | safeguard)
            → Care planning (HealthEntry / occurrences)
            → History → suppresses stale suggestions
```

| Verb | Primary owner in repo | This programme |
|------|----------------------|----------------|
| Know | Pet profile + API | PR-01–PR-05 |
| Understand | CIM + welfare layer | PR-06–PR-10 |
| Plan | CSM + care-item evolution | Parallel CSM; PR-12–PR-14 |
| Act | Actions / occurrences | Unchanged; guardrails in every PR |
| Remember | Health entries, weight, issues | PR-11 |

## Architectural boundaries (non-negotiable)

| Layer | User-facing | Engine | Must not |
|-------|-------------|--------|----------|
| **Profile completeness** | “Help Agatha know…” | Pet row + optional `profile_suggestions` | Create rhythms; alarmist clinical copy |
| **Welfare guidance** | “Suggested by Agatha” | Server rules + `suggestion_kind=welfare` | Override vet cadence; diagnosis / dose copy |
| **Rhythm suggestions** | “Suggested by Agatha” | `care_recommendations` / Phase C rule engine | Change Care Status before accept |
| **Safeguards** | Info chrome | Phase E weight path | Compete with operational care list |

References: [`care-intelligence.md`](../features/care-intelligence.md), [`care-foundation-roadmap.md`](./care-foundation-roadmap.md) negative tests, [`notifications-v2-spec.md`](../../notifications/features/notifications-v2-spec.md) FR-SG-6 / FR-SC-1.

### Visit invariants (document now; implement PR-14+)

- One `health_entry` = one care need; recurrence on the entry.
- Occurrences complete independently; **visit complete ≠ all children complete**.
- Shared calendar date does not merge items.
- Future `vet_visit` coordinates links only — no owned clinical history.

## Parallel track: Care Schedule Management

**Not renumbered in this programme.** Continue active execute-plans / merges for care-item evolution and CSM (`care-schedule-management.md`, `care-item-evolution.md`).

| Gate | Meaning |
|------|---------|
| **CSM-stable** | Agenda API grouping (Today / Due soon / Upcoming) trusted for PR-12+ |
| **No CSM block** | PR-01–PR-11 may ship while CSM tranches land |

## Waves (logical grouping, not ship batching)

| Wave | PRs | Outcome |
|------|-----|---------|
| **W1 — Know** | PR-01–PR-05 | Durable profile facts + Agatha completeness + slot policy |
| **W2 — Understand** | PR-06–PR-10 | Welfare framework + chip/neuter/vaccination guidance |
| **W3 — Connect** | PR-11 | Suggestions auto-complete from profile + history |
| **W4 — Coordinate** | PR-12–PR-13 | Same-day grouping + Agatha coordination copy |
| **W5 — Visits** | PR-14 | Visit schema/API design slice (no full appointment UX) |

---

## PR index

| PR | Title | Wave | Depends |
|----|-------|------|---------|
| [PR-01](#pr-01--profile-fact-model-server) | Profile fact model (server) | W1 | — |
| [PR-02](#pr-02--profile-facts-flutter--api-contract) | Profile facts Flutter + contract | W1 | PR-01 |
| [PR-03](#pr-03--inline-profile-capture) | Inline profile capture | W1 | PR-02 |
| [PR-04](#pr-04--agatha-completeness-cards) | Agatha completeness cards | W1 | PR-02, PR-03 |
| [PR-05](#pr-05--agatha-surface-policy) | Agatha surface policy | W1 | PR-04 |
| [PR-06](#pr-06--welfare-suggestion-framework) | Welfare suggestion framework | W2 | PR-01, PR-05 |
| [PR-07](#pr-07--welfare-microchip-guidance) | Welfare: microchip guidance | W2 | PR-06 |
| [PR-08](#pr-08--welfare-neuter-guidance) | Welfare: neuter guidance | W2 | PR-06 |
| [PR-09](#pr-09--vaccination-record-minimum) | Vaccination record minimum | W2 | PR-01 |
| [PR-10](#pr-10--welfare-vaccination-guidance) | Welfare: vaccination guidance | W2 | PR-06, PR-09 |
| [PR-11](#pr-11--suggestion-history-feedback) | Suggestion ↔ history feedback | W3 | PR-06+ |
| [PR-12](#pr-12--agenda-same-day-grouping) | Agenda same-day grouping | W4 | CSM-stable |
| [PR-13](#pr-13--coordination-suggestion-copy) | Coordination suggestion copy | W4 | PR-12 |
| [PR-14](#pr-14--vet-visit-schema-slice) | Vet visit schema slice | W5 | PR-12, product gate |

---

## PR-01 — Profile fact model (server)

**Objective:** Persist orthogonal **profile facts** so unknown / yes / no / not applicable are not inferred from empty strings.

**Scope**

- Add enums (wire + DB), e.g. `identification_status`, `neuter_status`, `vaccination_status_summary` (exact names in OpenAPI PR).
- Migration backfill: empty chip → `unknown`; neuter: date → `yes`, dismissed flags preserved.
- `PUT /api/pets/:id` partial update; capability auth unchanged.
- Deprecate relying on `chipId.isEmpty` alone for business logic (keep field for ID value).

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-PF-01 | Given a pet with neuter_status `no`, when profile is reloaded, then status remains `no` (not `unknown`). |
| AC-PF-02 | Given identification_status `yes` and chip_id set, when GET pet, then both are returned. |
| AC-PF-03 | Given view-only member, when PUT profile facts, then 403. |
| AC-PF-04 | Given invalid enum, when PUT, then 400 with public error body (no raw exception). |

**TDD:** `server/test/pets/profileFacts.test.js` (new) before route implementation.

**Docs:** Fold enum contract into pet-profile canonical on merge (Mode A); this doc stays `proposed` until W1 complete.

---

## PR-02 — Profile facts Flutter + API contract

**Objective:** Flutter `Pet` entity and forms use the same facts as the server; OpenAPI updated.

**Depends:** PR-01

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-PF-10 | Given API returns neuter_status `no`, when pet list loads, then form shows No selected. |
| AC-PF-11 | Given round-trip save, then server and client enums match. |

**TDD:** `pet_model_test.dart`, `pet_form_controller_test.dart` extended first.

---

## PR-03 — Inline profile capture

**Objective:** Answer profile questions **on profile** without full form navigation where possible (sheet or inline controls).

**Depends:** PR-02

**UX:** Segmented Yes / No / Not sure for identification and neuter (species N/A for neuter). Optional chip ID field when Yes.

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-IC-01 | Given missing neuter status, when user selects No on profile sheet, then pet persists `neuter_status=no` without date. |
| AC-IC-02 | Given co-parent without editProfile, when viewing prompt, then primary action disabled with forbidden tooltip. |

**BDD:** See `ACJ-IC-*` in bdd-qa doc.

---

## PR-04 — Agatha completeness cards

**Objective:** Replace `PetProfileCompletenessPrompt` inset list with `AgathaMessageCard` completeness cards.

**Depends:** PR-02, PR-03

**Actions (not rhythm Accept):**

| Action | Behaviour |
|--------|-----------|
| Primary | Open inline capture (PR-03) or edit deep link |
| Why? | Species identification copy; factual evidence |
| Not for my pet | Maps to `*_dismissed` or status N/A |
| Dismiss | Quiet hide per policy |

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-AC-01 | Given chip recorded, when profile loads, then completeness card absent. |
| AC-AC-02 | Given card rendered, then chrome matches `CareSuggestionCard` tokens (CIM-9). |
| AC-AC-03 | Given no edit capability, then primary action disabled. |
| AC-AC-04 | Given completeness card, then Care Status and Actions unchanged. |

**Negative:** Copy must not read as alarmist medical recommendation (roadmap §12).

---

## PR-05 — Agatha surface policy

**Objective:** Centralise **max prominent Agatha surfaces** on pet profile and dashboard.

**Depends:** PR-04

**Order (requirement):** Safeguard (info) → operational care → **at most one** of (rhythm suggestion | welfare suggestion) → completeness (if no conflict).

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-SP-01 | Given active safeguard, when profile loads, then rhythm and welfare suggestions hidden. |
| AC-SP-02 | Given pending rhythm + completeness, then policy shows one prominent suggestion per `PetCarePresentationPolicy` doc. |

**Docs:** Update `care-intelligence.md` presentation table + pet-profile decisions slot order.

---

## PR-06 — Welfare suggestion framework

**Objective:** Server-persisted welfare suggestions with **outcome types** (record / learn / plan / discuss / dismiss).

**Depends:** PR-01, PR-05

**Not in scope:** Extending Phase C `evaluateCareRecommendationCandidates` without `kind` column.

**Schema sketch:** `welfare_suggestions` or `care_suggestions` with `kind=welfare|rhythm` — decision in PR-06 OpenAPI PR.

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-WF-01 | Given dismiss on profile, when For you refreshed (when wired), then same row suppressed (FR-SG-6 direction). |
| AC-WF-02 | Given welfare card, when primary action record_profile_fact, then no HealthEntry created. |

---

## PR-07 — Welfare: microchip guidance

**Depends:** PR-06, profile facts

**Gating:** identification_status `unknown` or missing ID when `yes`; suppress when `no` / N/A / dismissed.

**Acceptance criteria:** AC-WF-10 — species-appropriate headline; no jurisdiction compliance claims.

---

## PR-08 — Welfare: neuter guidance

**Depends:** PR-06

**Gating:** neuter_status `unknown` only; suppress for `no`, date recorded, species without neutering, dismissed.

**Copy:** Discuss with vet; no push to create rhythm.

---

## PR-09 — Vaccination record minimum

**Depends:** PR-01

**Objective:** Structured minimum for “what vaccination history exists” before schedules (last dose date optional, status enum).

**Defer:** Automated national schedules, product catalogue.

---

## PR-10 — Welfare: vaccination guidance

**Depends:** PR-06, PR-09

**Gating:** Only when PR-09 data quality threshold met; else silence.

**May link:** S1-style missing recurring care (notifications spec) — single dedupe_key story.

---

## PR-11 — Suggestion ↔ history feedback

**Depends:** PR-06+

**Objective:** Auto-complete / suppress suggestions when profile facts or relevant health_entries change.

**Acceptance criteria**

| ID | Given / When / Then |
|----|---------------------|
| AC-FB-01 | Given microchip welfare active, when chip_id saved, then suggestion completes within one refresh cycle. |
| AC-FB-02 | Given visit marked complete (future), then not all linked occurrences auto-complete. |

---

## PR-12 — Agenda same-day grouping

**Depends:** CSM-stable

**Objective:** Phase A — visual group by pet + calendar date on Actions/agenda (read model only).

**Acceptance criteria:** AC-CO-01 — three items same date render as one group header; three independent rows remain.

---

## PR-13 — Coordination suggestion copy

**Depends:** PR-12

**Objective:** Phase B — Agatha message when ≥2 vet-setting items due in window; links only, no merge.

---

## PR-14 — Vet visit schema slice

**Depends:** PR-12, explicit product gate

**Objective:** API + migration for `vet_visits` link table to occurrences/entries; **no** guardian appointment manager UI.

**Gate:** D0.5-style sign-off recorded in decision log before UI PRs.

---

## Documentation plan

| When | Action |
|------|--------|
| Each behaviour PR | `/canonical-docs sync` Mode A before open |
| PR-05 | Presentation + pet-profile slot order |
| PR-06 | New subsection in care-intelligence OR `pet-profile-decisions` for welfare vs rhythm |
| PR-14 | DATA_MAP if new PII tables |
| Programme complete | Fold this file into canonical docs; delete or mark delivered |

## Deliberate deferrals

- Profile completion percentage
- Welfare dashboard
- Multi-country legal engine
- LLM medical copy
- Full vet practice scheduling
- Auto vaccination schedules without PR-09 quality
- Merging care items for convenience

## Decision log (programme)

| ID | Decision | Status | Date |
|----|----------|--------|------|
| ACJ-D-001 | Completeness uses Agatha chrome but not Phase C rhythm engine | Proposed | 2026-10-10 |
| ACJ-D-002 | Welfare and rhythm share presentation policy, not rule engine | Proposed | 2026-10-10 |
| ACJ-D-003 | CSM continues on existing plans; PR-12 waits CSM-stable | Proposed | 2026-10-10 |
| ACJ-D-004 | Visit UI deferred; invariants documented in PR-01 programme | Proposed | 2026-10-10 |

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

Frozen programme for **`agatha-care-journey`** execute-plan. **Atomic phases PR-01 … PR-14** merge to integration branch **`cursor/agatha-care-journey-integration-b994`**; **one release PR** integration → **`main`** with **`/babysit-uat`**. Parallel **CSM** continues on existing plans.

**Slot order (single source of truth):** [`agatha-care-journey-ui-design.md`](./agatha-care-journey-ui-design.md) §3 — programme links here; do not duplicate ordering prose.

**Execute-plan:** [`.agents/plans/agatha-care-journey.md`](../../../.agents/plans/agatha-care-journey.md)  
**UI:** [`agatha-care-journey-ui-design.md`](./agatha-care-journey-ui-design.md)  
**BDD / TDD / QA:** [`agatha-care-journey-bdd-qa.md`](./agatha-care-journey-bdd-qa.md)  
**Execute-plan autonomy (merge, UAT, subagents):** [`agatha-care-journey-execute-autonomy.md`](./agatha-care-journey-execute-autonomy.md)

## Executive summary

AgathaTrack helps pet parents **know**, **understand**, **plan**, **act**, and **remember**. This programme:

1. Persists **profile facts** (`identification_status`, `neuter_status`) with safe PUT semantics on the shared `pets` row.
2. Replaces inset completeness UI with **Agatha completeness cards** (profile actions, not rhythm Accept).
3. Adds **`welfare_suggestions`** (separate from `care_recommendations`).
4. Closes **suggestion ↔ history** loops.
5. Adds agenda **grouping** and **coordination copy** after **CSM-stable** (halt if gate undefined).
6. Defers visit **UI**; PR-14 is schema/API only.

## Delivery model (execute-plan full autonomy)

| Rule | Detail |
|------|--------|
| **Integration branch** | `cursor/agatha-care-journey-integration-b994` — phase PR base (`snapshot.base_branch`). |
| **Phase merges** | Each PR-* → **`/babysit-plus`** → squash into **integration** (not `main`). |
| **Release** | One PR integration → **`main`** → **`/babysit-uat`** + pre-UAT E2E; then `complete-plan`. |
| **Contract** | [execute-autonomy.md](./agatha-care-journey-execute-autonomy.md) |
| **Subagents** | **pr-09** ∥ **pr-02** after pr-01 when paths disjoint. |
| **Feature flags** | Per autonomy doc; defaults may flip on release PR. |
| **Migrations** | PR-01, 06, 09, 14: optional `human_pause` on #1835 before merge to integration. |
| **W1 value** | First guardian-visible on integration: **PR-03**, **PR-04**. |

### Per-PR verification pack (mandatory)

| PR | Acceptance criteria | TDD (first) | BDD / E2E | Documentation |
|----|---------------------|-------------|-----------|---------------|
| 01 | AC-PF-01…07 | `profileFacts.test.js` + sharing/org | stub feature file | OpenAPI, DATA_MAP, Planned→Live rows start |
| 02 | AC-PF-10,11 | `pet_model_test.dart` | — | pet-profile-decisions sync |
| 03 | AC-IC-01,02 | sheet widget test | ACJ-IC-* | — |
| 04 | AC-AC-01…04 | completeness widget | ACJ-AC-*, ACJ-GUARD-01 smoke-ci | care-intelligence presentation |
| 05 | AC-SP-01,02 | policy unit tests | ACJ-SP-01 smoke-ci | slot order canonical |
| 06 | AC-WF-01…03 | `welfareSuggestions.test.js` | — | welfare_suggestions in CIM doc |
| 07–08 | AC-WF-10,11 + fixtures | welfare/*.test.js | ACJ-WF-07 jest; ACJ-WF-08 smoke-ci | copy lint ARB |
| 09 | AC-VX-* | migration + API tests | — | DATA_MAP |
| 10 | AC-WF-11 | gating fixtures | — | copy review sign-off in PR |
| 11 | AC-FB-01 | completion job test | ACJ-FB-01 uat | — |
| 12 | AC-CO-01 | agenda jest | ACJ-CO-01 smoke-uat | CSM doc cross-link |
| 13 | AC-CO-02 | coordination jest | ACJ-CO-02 | — |
| 14 | AC-FB-02, AC-VV-01 | visit schema integration | — | DATA_MAP, governance log |

Full AC→test map: [bdd-qa](./agatha-care-journey-bdd-qa.md) § Traceability.

## Profile fact model (Q1 — canonical)

| Concept | Rule |
|---------|------|
| **Statuses** | `yes \| no \| unknown` on wire for identification and neuter. |
| **Species N/A** | Neutering not applicable = **derived from species** (`AppConstants.speciesWithoutNeutering`) — **not stored**. |
| **Dismissal** | “Not for my pet” = `chip_dismissed` / `neuter_dismissed` — **not** a status value. |
| **Provenance** | `identification_status_updated_at`, `neuter_status_updated_at`, `identification_status_source`, `neuter_status_source` (`backfill \| user`) so backfill `unknown` ≠ user “Not sure” policy. |
| **Vaccination** | **No** `vaccination_status_summary` on `pets` (B3). PR-09 owns records; summaries are **computed**. |

## Architectural boundaries

| Layer | Engine | Must not |
|-------|--------|----------|
| Profile completeness | Pet row + dismiss flags | Rhythms; alarmist copy |
| Welfare guidance | `welfare_suggestions` table | Touch `care_recommendations` NOT NULL rhythm columns |
| Rhythm suggestions | `care_recommendations` / Phase C | Change Care Status before accept |
| Safeguards | Phase E path | Teal Agatha chrome |

**Dedupe:** Shared `dedupe_key` **namespace** across welfare + rhythm for future For you union (FR-SG-6). Presentation only is shared (ACJ-D-002).

### Visit invariants

Documented **in this programme** (ACJ-D-004). PR-14 implements schema only.

## CSM-stable gate (B5)

Agent **must halt** (`governance_approval_required`) until decision log row **ACJ-D-006** is **Live** with:

| Criterion | Owner (fill at approval) |
|-----------|---------------------------|
| Named CSM PRs merged to `main` | _TBD_ |
| Agenda read contract frozen in OpenAPI (`pet-care-critical.json` or successor) | _TBD_ |
| No open P1 defects against agenda grouping | _TBD_ |

PR-12 **cannot** start without ACJ-D-006 Live. No “or earlier if Flutter only” escape.

**PR-11 CSM exposure (not gated):** reads `health_entries`, occurrence rows, pet profile facts; breaks if occurrence status vocabulary or pet PUT contract changes without coordination.

## Parallel track: CSM

PR-01–PR-11 proceed independently of CSM. PR-12–PR-13 blocked on ACJ-D-006. PR-14 depends on **product gate only** (not PR-12).

## Waves

| Wave | PRs | Outcome |
|------|-----|---------|
| W1 — Know | PR-01–05 | Facts, capture, Agatha completeness, extended policy |
| W2 — Understand | PR-06–10 | Welfare table + subjects |
| W3 — Connect | PR-11 | Auto-complete / suppress |
| W4 — Coordinate | PR-12–13 | Grouping + coordination copy |
| W5 — Visits | PR-14 | Visit schema slice |

## Success metrics (O12)

| Metric | Use |
|--------|-----|
| Completeness answer rate | % pets with identification/neuter status ≠ `unknown` after 30d |
| Dismiss rate per card kind | chip vs neuter vs welfare subject |
| Time to first answered fact | Median from pet create → first user-sourced status |
| Re-show rate after dismissal | Should drop with 30d cooldown (PR-05) |

---

## PR index

| PR | Title | Depends |
|----|-------|---------|
| PR-01 | Profile fact model (server + OpenAPI) | — |
| PR-02 | Profile facts Flutter | PR-01 |
| PR-03 | Inline capture (existing inset prompt) | PR-02 |
| PR-04 | Agatha completeness cards + **minimal** slot policy | PR-02, PR-03 |
| PR-05 | Extended Agatha surface policy (tiebreak, cooldown, dashboard) | PR-04 |
| PR-06 | `welfare_suggestions` framework | PR-01 |
| PR-07–08 | Welfare rules (data-driven fixtures) | PR-06 |
| PR-09 | Vaccination record minimum + DATA_MAP | PR-01 |
| PR-10 | Welfare vaccination (+ copy review) | PR-06, PR-09 |
| PR-11 | History feedback | PR-06+ |
| PR-12 | Same-day grouping | ACJ-D-006, PR-11 |
| PR-13 | Coordination copy | PR-12 |
| PR-14 | Vet visit schema | Product gate |

---

## PR-01 — Profile fact model (server + OpenAPI)

**Objective:** Persist `identification_status` and `neuter_status` on **`pets`** with **merge-safe PUT** semantics.

**Evidence:** `server/lib/pets/petCoreCommandService.js` today defaults omitted `chipId` to `''` and writes all columns — **contract change**, not “partial update” wording alone.

### PUT merge semantics (B1)

New status fields follow **`hasOwnProperty` / keep-existing** pattern used for weight reference (`:138-168`).

**Kept when omitted from request body** (old clients):

- `identification_status`, `neuter_status`
- `identification_status_source`, `neuter_status_source`
- `identification_status_updated_at`, `neuter_status_updated_at`
- `chip_dismissed`, `neuter_dismissed`

**Still required / replaced when omitted** (existing behaviour — document in PR, do not silently change without AC):

- `name`, `species`, and other fields the current handler always binds from body defaults.

**Old-client rule:** If request has **no** status fields but sends `chipId: ''`, **do not** reset status to `unknown` when stored status is already set (AC-PF-05).

### Status / value normalisation (pick: **normalise**)

| Input | Server action |
|-------|----------------|
| `identification_status=yes`, empty `chip_id` | **Allow** (“chipped, number unknown”) |
| `chip_id` non-empty, status `unknown` or `no` | **Normalise** to `yes` |
| `neutered_date` set, `neuter_status=no` | **Reject** 400 |
| `neuter_status=yes`, no date | **Allow** (date optional) |

### Scope beyond Pet Care API (B2)

- `server/routes/organizations/petsRouter.js` org write path
- `server/lib/orgPetShadow.js` — **default:** new statuses **not** copied to shadow / share preview / redacted payloads
- Tests: `petRedacted.test.js`, `sharing.test.js`, `sharedPetAccess.test.js`, `sharePreview.test.js`
- **`regulatory/DATA_MAP.md`** update for new profile fields (O7)

**Migration rollback:** Dropping columns loses statuses; backfill from `chip_id` / `neutered_date` only partially recoverable.

### Acceptance criteria

| ID | Given / When / Then |
|----|---------------------|
| AC-PF-01 | neuter_status `no` survives reload |
| AC-PF-02 | identification_status `yes` + chip_id returned on GET |
| AC-PF-03 | view-only PUT → 403 |
| AC-PF-04 | invalid enum → 400 `publicError` |
| AC-PF-05 | stored statuses unchanged when old client PUT omits status fields |
| AC-PF-06 | inconsistent status/value → defined normalise or 400 outcome |
| AC-PF-07 | when `chipId` omitted from PUT body, stored `chip_id` unchanged (symmetric with status keep-when-omitted) |

**TDD:** `server/test/pets/profileFacts.test.js`, org + sharing tests extended.

---

## PR-02 — Profile facts Flutter

**Depends:** PR-01 (OpenAPI already updated in PR-01)

**Acceptance:** AC-PF-10, AC-PF-11.

---

## PR-03 — Inline profile capture

**Depends:** PR-02

**Verifiable alone:** Sheet opened from **existing** `PetProfileCompletenessPrompt` (inset), not Agatha card.

**Acceptance:** AC-IC-01, AC-IC-02.

---

## PR-04 — Agatha completeness cards + minimal policy

**Depends:** PR-02, PR-03

**Includes minimal slot policy (O2):** no stacking safeguard + rhythm + completeness; completeness competes for slot — **not always shown** (UI doc §3).

**Actions:**

| Action | Behaviour |
|--------|-----------|
| Primary | PR-03 sheet |
| Why? | Factual + species copy |
| Not for my pet | `*_dismissed` only |
| Dismiss | Quiet hide + cooldown (full cooldown in PR-05) |

**Legacy removal (O1):** Delete unused `NeuterReminderCard`, `ChipReminderCard`, `neuter_reminder_controller.dart`, `chip_reminder_controller.dart` and dead tests.

**Acceptance:** AC-AC-01 … AC-AC-04; no HealthEntry on any action.

---

## PR-05 — Extended Agatha surface policy

**Depends:** PR-04

**Guidance tiebreak:** rhythm **>** welfare, then rule severity, then oldest `created_at`.

**Nag budget:** 30d cooldown per card kind after dismiss; cap re-shows (config in server or client policy doc).

**Docs:** Canonical sync presentation tables.

---

## PR-06 — Welfare suggestion framework

**Depends:** PR-01 (not PR-05)

**Storage (B4 / ACJ-D-005):** New table **`welfare_suggestions`** — `care_recommendations` **untouched**.

Columns include: `pet_id`, `subject_key`, `dedupe_key`, `status`, `primary_outcome`, `rationale_key`, `engine_version`, timestamps. No `suggested_frequency` NOT NULL hacks.

**Acceptance:** AC-WF-01, AC-WF-02, AC-WF-03 (dismiss suppresses dedupe_key per FR-FB-1 direction).

---

## PR-07 / PR-08 — Welfare subjects

**Depends:** PR-06

**Delivery (O4):** One PR per subject acceptable for first ship; rules as **data-driven fixtures** in `server/test/careIntelligence/welfare/` shared evaluator.

**PR-07 (microchip):** AC-WF-10; copy “check local rules” only — no compliance absolutes (O6).

**PR-08:** Delete persuasive legacy neuter copy paths (O1); welfare gating `neuter_status=unknown` only.

---

## PR-09 — Vaccination record minimum

**Depends:** PR-01

**DATA_MAP** update (O7). No summary column on `pets`.

---

## PR-10 — Welfare vaccination

**Depends:** PR-06, PR-09

**Exit:** Product/vet **copy review** sign-off in PR checklist (O5). Silence when data quality below threshold (AC-WF-11).

---

## PR-11 — Suggestion ↔ history feedback

**Depends:** PR-06+

**Reads:** `pets` status fields, `welfare_suggestions`, `health_entries`, occurrences (CSM churn risk).

**Acceptance:** AC-FB-01 only. **AC-FB-02 moved to PR-14** (visit completion).

---

## PR-12 — Same-day grouping

**Depends:** ACJ-D-006 Live, PR-11 merged

**Acceptance:** AC-CO-01

---

## PR-13 — Coordination copy

**Depends:** PR-12 — links only, no merge.

---

## PR-14 — Vet visit schema slice

**Depends:** Product gate (ACJ-D-007 when added); **not** PR-12

**Scope:** `vet_visits` + link table; **AC-FB-02** visit bulk-complete semantics tested here.

**DATA_MAP** + governance sign-off before UI PRs.

---

## Documentation plan

| When | Action |
|------|--------|
| Spec PR #1833 merge | `Planned` rows in canonical docs (see § Doc ownership) |
| Each behaviour PR | `/canonical-docs sync` Mode A |
| PR-01, PR-09, PR-14 | DATA_MAP |

## Deliberate deferrals

(Unchanged — completion %, welfare dashboard, jurisdiction engine, LLM advice, auto vax schedules, merged care items, full appointment UX.)

## Decision log (programme)

| ID | Decision | Status | Date |
|----|----------|--------|------|
| ACJ-D-001 | Completeness: Agatha chrome, not Phase C engine | Proposed | 2026-10-10 |
| ACJ-D-002 | Welfare + rhythm: shared presentation + dedupe namespace, separate storage | Proposed | 2026-10-10 |
| ACJ-D-003 | PR-12 blocked on CSM-stable row | Proposed | 2026-10-10 |
| ACJ-D-004 | Visit UI deferred; invariants in **this programme** | Proposed | 2026-10-10 |
| ACJ-D-005 | `welfare_suggestions` table; `care_recommendations` unchanged | Proposed | 2026-10-10 |
| ACJ-D-006 | CSM-stable gate definition (owner, PRs, OpenAPI, P1s) | Proposed | 2026-10-10 |

---

## Pre-approval checklist (§7 — before `approve-autonomous`)

- [ ] B1–B3 PR-01 contract in spec (this doc § PR-01)
- [ ] B4 `welfare_suggestions` + ACJ-D-005
- [ ] B5 ACJ-D-006 owner/criteria filled; PR-14 decoupled from PR-12
- [x] B6 delivery: phase PRs → integration; release PR → `main`; flags; optional migration `human_pause`; rollback notes
- [ ] Q2 slot order in UI doc; PR-04 minimal policy; tiebreak + cooldown in PR-05
- [ ] O1 legacy card deletion in PR-04 scope
- [ ] UI-Q-01..03 resolved in UI doc
- [ ] bdd-qa: `@smoke-ci` boundaries, traceability, copy lint
- [ ] DATA_MAP PR-01/09; metrics § Success metrics
- [x] Snapshot: `control_issue` #1835, `base_branch` integration, `autonomy: active`, `approved_until` +48h, `--fix-hash`
- [x] [Execute autonomy](./agatha-care-journey-execute-autonomy.md): integration branch `cursor/agatha-care-journey-integration-b994`; release `/babysit-uat`; spawn rules documented
- [ ] bdd-qa: full AC→test traceability; per-PR verification pack above agreed

## Doc ownership (spec PR)

On merge of #1833, add **Planned** rows to:

- `docs/domains/pet_profile/features/pet-profile-decisions.md` — fact model, PUT semantics, dismiss vs status
- `docs/domains/pet_care/features/care-intelligence.md` — welfare vs rhythm, `welfare_suggestions`, slot policy link

`changes/agatha-care-journey-*.md` remain delivery specs until programme complete.

---
title: Care Progression
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_progression
status: active
last_updated: 2026-10-08
related_prs: []
---

# Care Progression

Care Progression makes **meaningful care visible over time** without gamification. It recognises durable care continuity (**Established**) and meaningful care moments (**Milestones**).

## Summary / scope

- **Owns:** Server-authoritative **Established** maturity (weight monitoring first); milestone persistence (`care_milestones`, `care_establishments`, `care_milestone_presentations`); establishment and milestone read APIs; per-user milestone presentation and throttle; inline Established markers on Care Rhythms; quiet profile/dashboard progression moments; timeline milestone segments.
- **Does not own:** Care Status or overdue semantics ([care-schedule-management.md](./care-schedule-management.md)); occurrence commands and completion UX ([care-item-evolution.md](./care-item-evolution.md)); review relevance, suggestions, or safeguards ([care-intelligence.md](./care-intelligence.md)); weight storage and fulfilment wire rules ([weight-monitoring-model.md](../../weight_tracking/features/weight-monitoring-model.md)); paywall runtime ([care-entitlements.md](./care-entitlements.md)).
- **Depends on:** Recurring care and occurrences (`care_planning`); linked weight observations (`care_observations`); explicit `care_family` on recurring writes; central presentation arbitration (`care_presentation` / Phase E safeguard slot); capability registry (`care_core`).

**Philosophy:** Reward care, not attention — no XP, points, streaks, leaderboards, progress rings, or negative maturity UI. Absence of a marker is **neutral**.

**Programme mechanics (in delivery):** [care-progression-delivery-plan.md](../changes/care-progression-delivery-plan.md) (CP slices, APIs). **Predecessor:** [care-foundation-roadmap.md](../changes/care-foundation-roadmap.md) Phases A–E.

## Requirements

| ID | Rule | Status |
|----|------|--------|
| CARE-PROGRESSION-R-001 | No gamification: no XP, points, streaks, global scores, leaderboards, cross-pet comparison, or progress for merely opening the app | Live |
| CARE-PROGRESSION-R-002 | User-facing maturity uses **Established** only when confident; never show “not established”, grey uncertain states, or punitive progression signals | Live |
| CARE-PROGRESSION-R-003 | All progression truth is server-authoritative; client renders DTOs and submits user actions only | Live |
| CARE-PROGRESSION-R-004 | Client must not independently compute Establishment, create milestone identity, or recompute maturity locally | Live |
| CARE-PROGRESSION-R-005 | Care Progression must not alter deterministic Care Status because something is or is not Established | Live |
| CARE-PROGRESSION-R-006 | Recurring `health_entries` require explicit valid `care_family` on write; one-off entries prefer explicit family; uncategorised uses `other` not null | Live |
| CARE-PROGRESSION-R-007 | `CareFamily` is the semantic anchor; do not encode recurrence, status, or progression into family names | Live |
| CARE-PROGRESSION-R-008 | Family capabilities are code-defined policy via a central registry — no scattered `if (family == …)` across UI and routes | Live |
| CARE-PROGRESSION-R-009 | V1 establishment evaluation ships for **weight_monitoring** only; other families may be architecturally supported but eval deferred until data quality permits | Live |
| CARE-PROGRESSION-R-010 | Weight rhythm occurrence completion requires a real linked weight observation; skips do not count toward Establishment | Live |
| CARE-PROGRESSION-R-011 | Standalone weight entries (`health_occurrence_id` null) remain allowed; hub fulfilment may count pending weigh-ins per weight programme rules | Live |
| CARE-PROGRESSION-R-012 | Accepting an Agatha weight-rhythm suggestion creates the rhythm only — no invented observation | Live |
| CARE-PROGRESSION-R-013 | Shared observation quality **primitives** only; progression uses separate thresholds from CIM review-relevance (`weightEstablishmentPolicy`) | Live |
| CARE-PROGRESSION-R-014 | Progression must not consume Phase D review-relevance or safeguard evaluation outputs | Live |
| CARE-PROGRESSION-R-015 | Provenance axes (`CareSource`, `measurementSource`, `referenceAuthority`, `managementContext`) are orthogonal — see [care-intelligence.md](./care-intelligence.md) §Provenance model | Live |
| CARE-PROGRESSION-R-016 | Persist establishment only on historical transition in `care_establishments` with `UNIQUE(health_entry_id)` in V1; store `policy_version` | Live |
| CARE-PROGRESSION-R-017 | One late or missed occurrence does not revoke Established; pause/end rhythm does not erase historical establishment in V1 | Live |
| CARE-PROGRESSION-R-018 | Deleting occurrence-linked weight re-opens occurrence to `pending`; existing `care_establishments` row is not revoked | Live |
| CARE-PROGRESSION-R-019 | Ambiguous `care_family`, recurrence, or completion evidence yields **no marker** — prefer data cleanup over guardian-facing legacy repair | Live |
| CARE-PROGRESSION-R-020 | V1 milestones: `first_care_established` (pet-level once) and `weight_monitoring_established` (per pet and family); server `dedupe_key` idempotency | Live |
| CARE-PROGRESSION-R-021 | Milestone records are shared pet history; presentation is per-user via `care_milestone_presentations` | Live |
| CARE-PROGRESSION-R-022 | Combined `first_care_established` plus family milestone: persist both rows; one combined moment in UI; bundle acknowledgement inserts all presentation rows atomically | Live |
| CARE-PROGRESSION-R-023 | Presentation throttle: at most one prominent milestone moment per pet per guardian per ~30 days; safeguards always outrank milestones | Live |
| CARE-PROGRESSION-R-024 | Contextual card order: safeguard, then actionable suggestion, then milestone, then lower-priority prompt; Established is secondary to due/current on rhythms | Live |
| CARE-PROGRESSION-R-025 | Primary surfaces: Care Rhythms Established inline marker; profile quiet summary; dashboard at most one moment; timeline milestone entries | Live |
| CARE-PROGRESSION-R-026 | Retired terminology: “established” meaning recurring care exists → **recurring care** / `hasActiveRecurringCare()`; only progression copy uses **Established** for maturity | Live |
| CARE-PROGRESSION-R-027 | Pre-production audit: run `node scripts/care/audit_care_families.js` before establishment enablement in new environments; DB `NOT NULL` on `care_family` deferred until audit clean | Live |
| CARE-PROGRESSION-R-028 | `medication_course_completed` milestone keyed to `health_entry_id` | Planned |
| CARE-PROGRESSION-R-029 | Seasonal milestones, geography/climate modelling, generic `care_observations` table migration, consumption of CIM review-relevance output | Planned |
| CARE-PROGRESSION-R-030 | Care classification taxonomy: hide legacy `type` from users; `care_family` primary; add `care_setting`, planning intent, and stored importance on `health_entries` per [care-classification-taxonomy-spec.md](../changes/care-classification-taxonomy-spec.md) | Planned |
| CARE-PROGRESSION-R-031 | Entitlements runtime enforcement for progression surfaces | Planned |

## Conceptual model

```text
                         CARE FAMILY
                  “What area of care is this?”
                              │
              ┌───────────────┴────────────────┐
              │                                │
              ▼                                ▼
        CARE ACTIONS                     CARE OBSERVATIONS
              │                                │
              └───────────────┬────────────────┘
                              ▼
                         CARE RHYTHMS
                              ▼
                     CARE MATURITY (Established)
                              ▼
                         MILESTONES
```

| Layer | Question |
|-------|----------|
| Care events / observations | What happened or was measured? |
| Care Rhythms | What repeats? |
| Care Status | What needs attention now? |
| Care Progression | What has become established? What meaningful care happened? |
| Care Intelligence | What has changed? What context matters for review? |

## CareFamily and capabilities

`HealthEntryType` remains a coarse operational type. `CareFamily` values: `medication`, `vaccination`, `parasite_prevention`, `wellness_review`, `dental`, `weight_monitoring`, `grooming`, `nail_care`, `other`.

### V1 capability matrix (initial ship)

| Care family | Establishment (V1 eval) | Milestones (V1) | Observations |
|-------------|-------------------------|-----------------|--------------|
| Weight monitoring | **Yes** | **Yes** | Numeric weight |
| Medication | Deferred | V1.1 (`course_completed`) | No |
| Vaccination | Architecturally supported; eval deferred | Deferred | No |
| Parasite prevention | Architecturally supported; eval deferred | Deferred | No |
| Wellness review | Architecturally supported; eval deferred | Deferred | No |
| Dental | Architecturally supported; eval deferred | Deferred | No |
| Grooming / nail care | Deferred | Deferred | No |
| Other | No by default | No by default | No by default |

## Observations (weight-first)

Weight uses `weight_entries` with optional `health_occurrence_id`. A weight-rhythm occurrence is not completed without a real weight entry. Observation quality for progression uses shared primitives; adequacy thresholds live in `server/lib/care/progression/weightEstablishmentPolicy.js` (version `WEIGHT_ESTABLISHMENT_POLICY_VERSION`).

**CP-1 split:** extract neutral helpers to `care_observations`; keep CIM adequacy in `care_intelligence`; establishment thresholds stay in `care_progression`.

## Established care semantics

Family-specific, cadence-relative evaluation — no universal “3 completions = Established”. Eligibility uses active recurring care, valid linked evidence where required, minimum calendar span, and sufficient completed occurrences with valid evidence.

| Band | Example cadences | Policy intent |
|------|------------------|---------------|
| High frequency | weekly, biweekly | Enough occurrences plus several weeks |
| Medium | monthly-ish | Enough occurrences plus several months |
| Low / annual | yearly+ | Architecturally supported; evaluation deferred in V1 |

**Visible states:** no marker (neutral) or **Established** marker only. Internal evaluator states (`not_evaluable`, `insufficient_evidence`, `accumulating_evidence`, `established`) are diagnostics only.

Weight establishment counts only `health_occurrence.status = completed` with `weight_entries.health_occurrence_id` linked and progression quality primitives passing.

## Milestones

Milestones recognise meaningful care, not app activity. **Presented** means the prominent milestone card rendered successfully to that guardian; insert presentation row on render acknowledgement.

## Domain boundaries

```text
care_core           shared vocabulary, capabilities
care_planning       events, rhythms, occurrences, Care Status
care_observations   weight + quality primitives
care_progression    maturity, milestones
care_intelligence   suggestions, review relevance, safeguards
care_presentation   collision, slots, copy shaping
care_entitlements   access policy (future tiers)
```

Progression reads Planning and Observations; never CIM. Planning never depends on Progression or CIM.

## Regulatory

Map milestone and establishment persistence in [DATA_MAP.md](/regulatory/DATA_MAP.md) before ship. No raw clinical diagnosis in progression copy.

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| CP-1 — When authorised guardian GETs care-progression then Establishments and milestones DTOs return 200 | CARE-PROGRESSION-R-003 | test: server/test/careProgression/read.test.js |
| CP-3 — When weekly weight rhythm has enough linked completed evidence then Policy returns established with version | CARE-PROGRESSION-R-009 | test: server/test/care/progression/weightEstablishmentPolicy.test.js |
| CP-3 — When first eligible transition then Service persists care_establishments row | CARE-PROGRESSION-R-016 | test: server/test/care/progression/weightEstablishmentService.test.js |
| CP-4 — When first establishment on pet then Bundled milestones created idempotently | CARE-PROGRESSION-R-020 | test: server/test/care/progression/careMilestoneService.test.js |
| CP-4 — When pending moments queried then Throttle and presentation candidates respect per-user rows | CARE-PROGRESSION-R-023 | test: server/test/careProgression/moments.test.js |
| CP-3 — When internal re-evaluate posted then Establishment re-run is auth gated | CARE-PROGRESSION-R-003 | test: server/test/careProgression/reEvaluate.test.js |
| CP-0 — When integration gate fixtures run then hasActiveRecurringCare and establishment policy unchanged for baseline | CARE-PROGRESSION-R-026 | test: server/test/careSchedule/integrationGate.test.js |
| CP-2 — When hub weigh-in fulfils occurrence then Establishment path may record transition | CARE-PROGRESSION-R-011 | test: server/test/db/weightFulfilment.integration.test.js |
| CP-5 — When weight monitoring rhythm in list then establishedRhythmEntryIds includes entry id only for weight family | CARE-PROGRESSION-R-025 | test: flutter_app/test/features/pet_profile/presentation/widgets/care_establishment_helpers_test.dart |
| CP-1 — When capability contract runs then Server and Flutter capability matrices align | CARE-PROGRESSION-R-008 | test: flutter_app/test/features/pet_care/core/care_family_capability_contract_test.dart |
| CP-7 — When timeline segment is care milestone then Labels and icon use progression copy | CARE-PROGRESSION-R-025 | test: flutter_app/test/features/pet_profile/presentation/widgets/pet_timeline/pet_timeline_entry_tile_milestone_test.dart |
| CP-6 — When guardian sees milestone moment on profile or dashboard then Prominent card respects safeguard-first hierarchy | CARE-PROGRESSION-R-024 | none — #1770 |
| CP-5 — When rhythms list renders Established inline then Marker is secondary to due state | CARE-PROGRESSION-R-025 | none — #1770 |

Coverage gaps: [#1770](https://github.com/KanopeeKa/AgathaCheck/issues/1770) (progression presentation E2E: milestone moment, Established inline on rhythms).

## Still open

- `establishmentEpoch` for re-establishment after long gap (future).
- Honest multi-family evaluation when calendar history supports vaccination, dental, and annual rhythms.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| CARE-PROGRESSION-D-001 | Phase E safeguards merge before Care Progression runtime | Presentation slot and programme sequencing | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-002 | User-facing marker **Established**; softer copy e.g. “Part of {name}'s regular care” | Distinguish maturity from recurring care existence | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-003 | Rename hasEstablishedRhythm to hasActiveRecurringCare before progression ships | Terminology collision | Live | 2026-09-09 | CP-0 |
| CARE-PROGRESSION-D-004 | Server-authoritative progression only | Prevent client drift and gaming | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-005 | Explicit care_family on recurring write | Stable semantic anchor for rhythms | Live | 2026-09-09 | CP-0 |
| CARE-PROGRESSION-D-006 | Weight occurrence completion requires linked observation | Evidence-based establishment | Live | 2026-09-09 | CP-2 |
| CARE-PROGRESSION-D-007 | Accepting weight rhythm suggestion creates rhythm only | No fabricated observations | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-008 | Ignore legacy weak completion for V1 Establishment | Ambiguous history → silence | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-009 | Skip allowed on weight occurrences; skips neutral for establishment | Respects occurrence model | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-010 | Milestones shared pet history; presentation per-user | Multi-guardian households | Live | 2026-09-09 | CP-4 |
| CARE-PROGRESSION-D-011 | Combined moment when first_care_established and family milestone coincide | Avoid duplicate celebrations | Live | 2026-09-09 | CP-4 |
| CARE-PROGRESSION-D-012 | Timeline integration late V1 slice (CP-7) | Deferrable under pressure | Live | 2026-09-09 | CP-7 |
| CARE-PROGRESSION-D-013 | medication_course_completed deferred to V1.1 | Scope control for initial ship | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-014 | Split observation primitives from CIM quality policy (CP-1) | Separate progression thresholds | Live | 2026-09-09 | CP-1 |
| CARE-PROGRESSION-D-015 | Progression does not consume review-relevance output | Domain boundary | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-016 | No negative maturity UI; ambiguous history → silence | Calm product tone | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-017 | Pause/end rhythm does not erase historical establishment | Historical truth | Live | 2026-09-09 | CP prog |
| CARE-PROGRESSION-D-018 | care_establishments stores transition only; UNIQUE health_entry_id V1 | Audit-friendly persistence | Live | 2026-09-09 | CP-3 |
| CARE-PROGRESSION-D-019 | Weight delete re-opens occurrence; establishment not revoked | Operational correction vs history | Live | 2026-09-09 | CP-2 |
| CARE-PROGRESSION-D-020 | Milestone presented = card rendered; bundle ack atomic | Throttle and analytics semantics | Live | 2026-09-09 | CP-4 |
| CARE-PROGRESSION-D-021 | Pre-production checkpoint: no live progression users; audit before CP-3 enablement | Safe rollout (folded from cp0) | Live | 2026-09-09 | cp0 |
| CARE-PROGRESSION-D-022 | Safeguard beats suggestion beats milestone in presentation slot | Phase E handoff to CP-6 | Live | 2026-09-08 | Phase E |

CIM Phase D/E artefacts (provenance D0, evaluation D5a, second signal D4a, Phase E handoff D7): [care-intelligence.md](./care-intelligence.md) and [phase-d-review-relevance-plan.md](../changes/phase-d-review-relevance-plan.md) — not progression-owned.

## Related

| Kind | Link |
|------|------|
| Delivery slices | [care-progression-delivery-plan.md](../changes/care-progression-delivery-plan.md) |
| Foundation programme | [care-foundation-roadmap.md](../changes/care-foundation-roadmap.md) |
| Taxonomy (planned) | [care-classification-taxonomy-spec.md](../changes/care-classification-taxonomy-spec.md) |
| Intelligence | [care-intelligence.md](./care-intelligence.md) |
| Entitlements principles | [care-entitlements.md](./care-entitlements.md) |
| API | [api-reference.md](/docs/architecture/api-reference.md) §Care progression |
| Execute-plan | [.agents/plans/care-progression-v1.md](/.agents/plans/care-progression-v1.md) |

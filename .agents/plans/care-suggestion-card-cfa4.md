---
title: Care suggestion card redesign
owner: Product / Experience
audience: agent
status: proposed
last_updated: 2026-10-09
tags: [execute-plan, care-intelligence, ux]
---

# Care suggestion card redesign

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-suggestion-card-cfa4` |
| **title** | Compact Agatha recommendation cards + review-before-add flow |
| **author** | cloud-agent (Stage 1 analysis 2026-10-09) |
| **created** | 2026-10-09 |
| **base_branch** | `cursor/care-suggestion-card-integration-cfa4` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Redesign **Phase C** care rhythm suggestions (`CareSuggestionCard`, inbox `suggestionCareFamily`) to be compact, calm, and actionable: clear hierarchy, inline benefit, **Later / No thanks** (mapped to existing `dismiss` / `not_relevant`), **Why this matters** as a link (not a fourth decision), typographic **“Agatha recommends”** eyebrow (no new script font in v1).

**Add routine** opens the **health entry form** prefilled so the guardian can review and edit the title (and schedule fields) before final save — then the server **accept** path creates the rhythm with that name (additive `adjust` on `accept`).

Align **display and accepted routine names** by updating `SUGGESTION_CATALOG` and pending row backfill — do not rename existing `health_entries`.

Keep existing snackbar on success; **no** in-card success state.

**Out of scope:** CIM timed “Later” resurfacing on dashboard (permanent `dismissed` row today — track debt if product wants 30-day snooze); full S1/S2 wave-1 card redesign (compact variant only); handwritten font asset.

## Canonical docs

| Doc | Action |
|-----|--------|
| `docs/domains/pet_care/features/care-intelligence.md` | Presentation, eyebrow, action labels, accept-via-form behaviour |
| `docs/domains/notifications/features/notifications-v2-spec.md` | FR-SC-1 anatomy (inline actions, why link) |
| `docs/design/copy-tone.md` | N/A unless new voice examples added |

## Decisions (locked for implementation)

| Topic | Decision |
|-------|----------|
| Eyebrow typography | **“Agatha”** italic + **“recommends”** regular, same `agathaTeal` / `titleSmall` weight — no new font |
| Actions | **Add routine** (primary) · **Later** → `dismiss` · **No thanks** → `not_relevant` |
| Why | Text link under benefit → existing `SuggestionWhySheet` |
| Accept | Navigate to `HealthEntryFormScreen` with prefill; submit → `POST respond` `accept` with `adjust` (name, frequency, etc.) |
| Copy | l10n display titles + short benefits keyed by `suggestion_key`; server `suggested_name` aligned for accept/snackbar |
| Notifications | `suggestionCareFamily` shares content module; S1/S2 keep separate compact layout |

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-09T01:08:28Z |
| **approved_until** | 2026-10-11T01:08:28Z |
| **control_issue** | [#1827](https://github.com/KanopeeKa/AgathaCheck/issues/1827) |
| **content_hash** | see snapshot |
| **autonomy** | `active` (granted via issue comment) |

**Grant keyword:** `approve-autonomous care-suggestion-card-cfa4`

**Pre-approval:** Create integration branch `cursor/care-suggestion-card-cfa4-integration` from `main` and commit plan artifacts there.

---

## Phase 1 — Server knowledge names and accept-with-adjust

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-suggestion-catalog-cfa4` |
| **exit_checklist** | `single-backend-route` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
server/routes/careIntelligence/**
server/test/careIntelligence/**
```

**forbidden_paths:**

```
flutter_app/**
.github/workflows/**
db/**
```

**Scope:**

- Update `SUGGESTION_CATALOG` `suggested_name` to guardian-friendly names (monthly weight check, annual dental check-in, annual wellness checkup).
- On `syncPendingRecommendations`, refresh `suggested_name` (and rationale if needed) on **pending** rows from catalog for matching `suggestion_key` + `knowledge_version`.
- `buildAcceptedHealthEntry`: honour `adjust.name` when present.
- `POST …/respond` with `action: accept`: pass `req.body.adjust` into `createRhythmFromRecommendation` (same shape as future adjust; status remains `accepted`).
- Jest coverage for name override and catalog values.

**Exit criteria:**

- [ ] Three catalog entries use new `suggested_name` strings
- [ ] Accept with `adjust.name` creates `health_entries.name` matching adjust
- [ ] `recommendations.test.js` (and focused unit tests) green
- [ ] `./scripts/pre-push-changed.sh` green

---

## Phase 2 — Flutter cards, copy, review-before-add

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-suggestion-ui-cfa4` |
| **exit_checklist** | `flutter-screen-split` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/care_intelligence/**
flutter_app/lib/core/widgets/agatha_message_card.dart
flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart
flutter_app/lib/features/health_tracking/presentation/controllers/health_entry_form_controller.dart
flutter_app/lib/features/health_tracking/presentation/controllers/health_entry_form_state.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_contextual_slot_section.dart
flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_profile_care_suggestion_section.dart
flutter_app/lib/l10n/**
flutter_app/test/features/care_intelligence/**
flutter_app/test/features/health_tracking/presentation/controllers/health_entry_form*
flutter_app/lib/core/router/**
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Extend `care_suggestion_copy.dart`: `displayTitle`, `shortBenefit`, reuse cadence + rationale mapping.
- ARB (EN/FR): `careSuggestionEyebrowAgatha` / `careSuggestionEyebrowRecommends` (or single pattern), `careSuggestionLater`, `careSuggestionNoThanks`, `careSuggestionWhyLink`, per-key display titles and short benefits (3 keys).
- Shared widgets: eyebrow row, optional `CareSuggestionCardBody` (hierarchy + benefit + why link + cadence).
- **`CareSuggestionCard`:** new layout; remove inline `respond(accept)` on primary tap.
- **Add routine:** `go_router` push to health entry **add** route with extras/query: `petId`, `careRecommendationId`, prefill `initialCareFamily`, initial routine name (display title), frequency fields from recommendation.
- **Form submit (add-from-suggestion only):** call `careIntelligenceRepository.respond(accept, adjust: { name, frequency, frequency_interval, … })` instead of standalone health entry POST; handle forbidden/errors with existing copy.
- **Later / No thanks:** unchanged API actions via `CareSuggestionRespondActions`.
- Semantics: group label includes eyebrow + title; distinct labels for Later vs No thanks.
- Widget tests: hierarchy, actions, why link opens sheet, accept navigates (mock router), forbidden state.

**Exit criteria:**

- [ ] Dashboard and profile cards match approved hierarchy (no × dismiss, no Why button)
- [ ] Add routine opens form with editable title prefilled to display title
- [ ] Successful form submit accepts recommendation and shows existing snackbar
- [ ] `flutter test` care_intelligence + affected form controller tests green
- [ ] `/canonical-docs sync` for `care-intelligence.md`

---

## Phase 3 — Notifications, E2E, spec alignment

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-suggestion-inbox-e2e-cfa4` |
| **exit_checklist** | `bdd-journey` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
flutter_app/lib/features/notifications/presentation/widgets/notification_suggestion_card.dart
flutter_app/test/features/notifications/presentation/widgets/notification_suggestion_card_test.dart
e2e/playwright/tests/care-suggestion.spec.ts
e2e/playwright/pages/care-suggestion.page.ts
flutter_app/test/bdd/features/care_suggestion.feature
docs/domains/notifications/features/notifications-v2-spec.md
docs/domains/pet_care/features/care-intelligence.md
```

**forbidden_paths:**

```
server/**
.github/workflows/**
db/**
```

**allowed_exceptions:** `tests`, `docs`

**Scope:**

- `NotificationSuggestionCard`: for `suggestionCareFamily`, reuse shared body + actions; localized benefit (not raw `rationale_key`); compact spacing/truncation; **Add routine** → same form navigation as dashboard (pet context from notification).
- S1/S2: retain slimmer card (title/message/disclaimer); optional eyebrow only — no CIM copy mapping.
- Update `SuggestionWhySheet` to use **display title** in summary line.
- E2E: card labels (Agatha recommends / FR); **Add routine** → form visible → submit → suggestion gone + rhythm on agenda; Later/No thanks still map to respond/feedback.
- BDD scenario text if button labels change.

**Exit criteria:**

- [ ] `notification_suggestion_card_test.dart` passes
- [ ] `care-suggestion.spec.ts` green locally (shard 8 area)
- [ ] BDD header/scenario alignment
- [ ] Notifications FR-SC-1 row updated for new anatomy
- [ ] Final PR: integration → `main` via `/babysit-uat`

---

## Debt / follow-up (do not block merge)

| Item | Suggestion |
|------|------------|
| CIM `dismissed` has no time-based resurfacing on dashboard | GitHub debt issue: implement snooze or reset-to-pending aligned with notification 30-day window |
| `buildSuggestionCopy` server message still rationale key for upsert | Optional server follow-up; Flutter fixes display for care-family in this plan |

---

## Sanity check (pre-approval)

| Check | Result |
|-------|--------|
| Phase paths disjoint | Yes (server / flutter / e2e+notifications) |
| Multi-phase integration branch | Required (`base_branch` set) |
| Scope < 48h autonomous window | Yes (medium UI + small API) |
| API break | No — additive `adjust` on `accept` |
| Migrations | None |

**Recommendation:** `proceed` (not high-risk)

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 2
last_completed_phase: null
halt_reason: null
next_action: "continue phase 2 on branch cursor/care-suggestion-ui-cfa4"
artifact_ref:
  branch: cursor/care-suggestion-ui-cfa4
  plan_path: .agents/plans/care-suggestion-card-cfa4.md
  plan_commit: 91c079f8b1ed51a630809037e0bdcce4a59a3408
  snapshot_path: .agents/plans/care-suggestion-card-cfa4.snapshot.json
  snapshot_commit: 91c079f8b1ed51a630809037e0bdcce4a59a3408
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1830"]
merge_commits: {}
debt_issue_refs: []
```

---
title: Away Plan Care Review UX
plan_id: away-plan-care-review-ux
---

# Away Plan Care Review UX

| Field | Value |
|-------|-------|
| **plan_id** | `away-plan-care-review-ux` |
| **title** | Away plan care review queue (create silence + plan cards + bulk V1) |
| **base_branch** | `cursor/away-plan-care-review-ux-integration-a227` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Stop enumerating care occurrences before an absence is saved; after save, show a per-pet **care-item review queue** with in-trip date counts, **Review dates**, and bulk **Keep with carer**—aligned with frozen decisions **CARE-CONTEXT-D-004 … D-009** in the delivery plan.

**Delivery plan:** `docs/domains/pet_care/changes/away-plan-care-review-delivery-plan.md`
**Canonical docs (acr-5):** `docs/domains/pet_care/features/care-context.md`
**Related:** `care-item-evolution.md` (Review date / occurrence review), `away-plan-detail-v2` (planned_care_items)

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | *(pending — run `approve-autonomous away-plan-care-review-ux` on control issue after DOC-0)* |
| **approved_until** | |
| **control_issue** | |
| **autonomy** | `pending` |

## Phases

**acr-1 before acr-3. acr-2 parallel after acr-doc-0. acr-5 last.**

### Phase acr-doc-0 — Bootstrap

| Field | Value |
|-------|-------|
| **id** | `acr-doc-0` |
| **branch** | `cursor/away-plan-care-review-doc0-a227` |
| **spawn_allowed** | `false` |

**allowed_paths:**

```
docs/domains/pet_care/changes/away-plan-care-review-delivery-plan.md
docs/domains/pet_care/features/care-context.md
.agents/plans/away-plan-care-review-ux.*
```

**forbidden_paths:**

```
flutter_app/**
server/**
.github/workflows/**
```

**Exit criteria:**

- [ ] CARE-CONTEXT-D-004 … D-009 marked frozen in delivery plan
- [ ] Delivery plan `status: in-delivery`
- [ ] Control issue with labels `execute-plan`, `plan:away-plan-care-review-ux`
- [ ] Snapshot validates; user approval recorded

### Phase acr-1 — Server review metrics

| Field | Value |
|-------|-------|
| **id** | `acr-1` |
| **branch** | `cursor/away-plan-care-review-server-a227` |

**allowed_paths:**

```
server/lib/care/carePeriodCoverage.js
server/lib/care/awayPlan/**
server/lib/care/absence/**
server/routes/careContext/carePeriodCoverageRouter.js
server/routes/careContext/**/away*
server/test/careContext/**
server/test/care/absence/**
docs/architecture/api-reference.md
```

**Exit criteria:**

- [ ] Care-item-level review count matches D-005 (not `items[]` pending length)
- [ ] Review queue enrichment (or documented fields on existing rows) satisfies D-006
- [ ] Jest coverage for in-window vs pre-window counts and resolved exclusion
- [ ] api-reference updated if response shape changes

### Phase acr-2 — Create flow (no enumeration)

| Field | Value |
|-------|-------|
| **id** | `acr-2` |
| **branch** | `cursor/away-plan-care-review-create-a227` |

**allowed_paths:**

```
flutter_app/lib/features/pet_care/context/presentation/screens/planned_absence_flow_screen.dart
flutter_app/lib/features/pet_care/context/presentation/widgets/planned_absence_preview_step.dart
flutter_app/lib/features/pet_care/context/presentation/widgets/care_period_pet_preview_section.dart
flutter_app/lib/l10n/app_en.arb
flutter_app/lib/l10n/app_fr.arb
flutter_app/test/features/pet_care/context/care_period_pet_preview_section_test.dart
flutter_app/test/features/pet_care/context/planned_absence_*_test.dart
```

**Exit criteria:**

- [ ] No occurrence rows rendered on create before save
- [ ] Reassurance copy per D-004; no `careContextCoverageHasItemsToReview` occurrence count on create
- [ ] Widget tests updated

### Phase acr-3 — Plan review queue UI

| Field | Value |
|-------|-------|
| **id** | `acr-3` |
| **branch** | `cursor/away-plan-care-review-plan-ui-a227` |

**allowed_paths:**

```
flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_pet_care_section.dart
flutter_app/lib/features/pet_care/context/presentation/widgets/away_plan_care_review_**
flutter_app/lib/features/pet_care/context/presentation/care_period_coverage_copy.dart
flutter_app/lib/l10n/**
flutter_app/test/features/pet_care/context/away_plan_pet_care_section_test.dart
flutter_app/test/features/pet_care/context/away_plan_care_review_**
```

**Exit criteria:**

- [ ] Review cards: title, impacted date count, Review dates, checkbox in bulk mode (D-006, D-008)
- [ ] Schedule list collapsed when queue non-empty (D-009)
- [ ] Per-pet summary uses care-item count copy (D-005)
- [ ] Semantics identifiers for E2E
- [ ] Widget tests

### Phase acr-4 — Review dates navigation

| Field | Value |
|-------|-------|
| **id** | `acr-4` |
| **branch** | `cursor/away-plan-care-review-nav-a227` |

**allowed_paths:**

```
flutter_app/lib/core/router/**
flutter_app/lib/features/pet_care/context/presentation/**
flutter_app/lib/features/experience/presentation/care_item/**
flutter_app/test/features/pet_care/context/**
e2e/playwright/pages/away-planning.page.ts
```

**Exit criteria:**

- [ ] Review dates opens care item with absence review entry per D-007
- [ ] Widget or navigation test; page object method for Playwright

### Phase acr-5 — Canonical docs and BDD

| Field | Value |
|-------|-------|
| **id** | `acr-5` |
| **branch** | `cursor/away-plan-care-review-docs-a227` |

**allowed_paths:**

```
docs/domains/pet_care/features/care-context.md
docs/domains/pet_care/changes/away-plan-care-review-delivery-plan.md
docs/architecture/api-reference.md
flutter_app/test/bdd/features/away_plan_care_review.feature
e2e/playwright/tests/away.plan.care.review.spec.ts
flutter_app/test/bdd/features/away_planning.feature
```

**Exit criteria:**

- [ ] `care-context.md`: R-009/R-017 amended; D-004…D-009 in decision log; new requirements rows if added
- [ ] BDD + Playwright green on integration branch
- [ ] Delivery plan folded/deleted per canonical-docs skill
- [ ] Release PR integration → `main` via `/babysit-uat`

## Verification (every phase)

```bash
./scripts/pre-push-changed.sh
```

Flutter phases: `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos` and targeted `flutter test`.

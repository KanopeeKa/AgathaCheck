---
title: Agatha care journey — BDD, TDD, and QA matrix
owner: Product / Documentation
audience: both
domain: pet_care
status: proposed
status_since: 2026-10-10
parent: agatha-care-journey-programme.md
tags: [qa, bdd, testing, e2e]
---

# Agatha care journey — BDD, TDD, and QA matrix

**Programme:** [`agatha-care-journey-programme.md`](./agatha-care-journey-programme.md)

## Strategy

| Layer | When | Tooling |
|-------|------|---------|
| **BDD** | New guardian-visible behaviour | Gherkin in `e2e/bdd/features/pet_care/` → Playwright |
| **TDD** | Server rules, enums, policy | Jest / Flutter unit first |
| **Widget** | Agatha cards, sheets | `flutter_test` |
| **Integration** | API + DB migrations | `server/test/db/*`, pets CRUD |
| **A11y** | New cards | `@smoke-a11y` axe on touched routes (UAT tier) |
| **Regression** | CIM negative routes | Existing `server/test/careIntelligence/*` unchanged |

**BDD → TDD workflow per PR:**

1. Add scenario stubs (or full scenarios) with tags `@acj` `@pr-0N`.
2. Implement failing unit/API tests mapped to AC-* IDs.
3. Implement feature; wire Playwright step defs.
4. Run `node e2e/scripts/check_bdd_coverage.js --report-only` (gate unchanged).

---

## Scenario catalogue (BDD)

File proposal: `e2e/bdd/features/pet_care/agatha_care_journey.feature` (create in PR-04).

### Profile facts (PR-01–PR-03)

```gherkin
@acj @pr-01 @backend
Scenario: ACJ-PF-01 — Neuter status no survives reload
  Given a pet parent owns a dog with neuter status "no"
  When they open the pet profile
  Then the neuter status shows "No"

@acj @pr-03 @smoke-ci
Scenario: ACJ-IC-01 — Record neuter no from profile sheet
  Given a pet with unknown neuter status
  And the pet parent can edit the profile
  When they open the completeness sheet and choose neuter "No"
  Then the neuter completeness prompt is not shown

@acj @pr-03 @authz
Scenario: ACJ-IC-02 — View-only cannot record profile facts
  Given a co-parent with view-only access to a pet
  When they view the pet profile
  Then the completeness primary action is disabled
```

### Agatha completeness cards (PR-04–PR-05)

```gherkin
@acj @pr-04 @smoke-ci
Scenario: ACJ-AC-01 — Chip recorded hides completeness card
  Given a pet with identification status "yes" and chip id "ABC"
  When the pet parent opens the pet profile
  Then no profile completeness agatha card is visible

@acj @pr-04
Scenario: ACJ-AC-02 — Completeness card uses Agatha chrome
  Given a pet with missing identification status
  When the pet parent opens the pet profile
  Then they see an agatha message card for profile completeness

@acj @pr-05
Scenario: ACJ-SP-01 — Safeguard hides rhythm suggestion
  Given an active weight safeguard for the pet
  And a pending rhythm suggestion exists
  When the pet parent opens the pet profile
  Then the rhythm suggestion card is not shown
```

### Welfare (PR-07–PR-08)

```gherkin
@acj @pr-07
Scenario: ACJ-WF-07 — Microchip welfare suppressed when status no
  Given a pet with identification status "no"
  When welfare suggestions are evaluated
  Then no microchip welfare card is shown

@acj @pr-08 @copy
Scenario: ACJ-WF-08 — Neuter welfare does not offer add routine
  Given a pet eligible for neuter welfare guidance
  When the pet parent opens the welfare card
  Then they do not see a button to add a recurring care rhythm
```

### Feedback (PR-11)

```gherkin
@acj @pr-11
Scenario: ACJ-FB-01 — Recording chip clears welfare suggestion
  Given an active microchip welfare suggestion
  When the pet parent saves chip id on the profile
  Then the microchip welfare suggestion is no longer shown
```

### Coordination (PR-12–PR-13)

```gherkin
@acj @pr-12 @smoke-ci
Scenario: ACJ-CO-01 — Same day items share a date header
  Given two vet-setting care items due on the same calendar day
  When the pet parent opens Actions for that pet
  Then both items appear under one date group header
```

---

## TDD matrix (by PR)

| PR | Jest (server) | Flutter unit/widget | Playwright |
|----|---------------|---------------------|------------|
| PR-01 | `profileFacts.test.js` | — | — |
| PR-02 | field mapping | `pet_model_test.dart` | — |
| PR-03 | — | sheet widget test | ACJ-IC-* |
| PR-04 | — | `agatha_completeness_card_test.dart` | ACJ-AC-* |
| PR-05 | — | `pet_care_presentation_policy_test.dart` extend | ACJ-SP-* |
| PR-06 | `welfareSuggestions.test.js` | datasource test | — |
| PR-07–10 | rule fixtures per subject | card copy tests | ACJ-WF-* |
| PR-11 | completion job test | provider invalidate | ACJ-FB-01 |
| PR-12 | agenda grouping API | agenda widget | ACJ-CO-01 |
| PR-13 | coordination evaluator | banner widget | — |
| PR-14 | migration integration | — | — |

---

## QA views

### Risk tier (Router)

| PR range | Typical tier | Protocols |
|----------|--------------|-----------|
| PR-01–02 | R2 | api-contract, authorization, database-and-migrations |
| PR-03–05 | R1–R2 | flutter-mobile, accessibility, documentation |
| PR-06–11 | R2 | security, api-contract, documentation |
| PR-12–14 | R2–R3 | testing, release-verification |

### Manual / computer-use (implementation PRs)

- PR-04: Profile with missing chip — card actions, Why sheet, dismiss.
- PR-03: Sheet save and reload.
- PR-12: Actions agenda grouping on web viewport.

Artifacts: `/opt/cursor/artifacts/` per testing policy.

### CI gates (every PR)

```bash
./scripts/pre-push-changed.sh
node scripts/check_file_size.js
node e2e/scripts/check_bdd_coverage.js --report-only
```

### Negative test suite (must remain green)

- Rhythm suggestion does not alter Care Status before accept (`recommendations.test.js`)
- Missing chip/neuter not alarmist (widget copy assert + programme review checklist)
- Unsupported species CIM unchanged

### Pre-UAT

New `@acj` scenarios tagged `@smoke-ci` where noted join PR CI subset when steps exist.

---

## Traceability

| Programme AC | BDD ID | Test file (planned) |
|--------------|--------|---------------------|
| AC-PF-01 | ACJ-PF-01 | profileFacts.test.js |
| AC-AC-01 | ACJ-AC-01 | agatha_completeness_card_test.dart |
| AC-SP-01 | ACJ-SP-01 | care_recommendations_provider_test.dart |
| AC-FB-01 | ACJ-FB-01 | welfareSuggestions.test.js |

---

## Debt / follow-ups

- E2E coverage gap #1770 — extend with ACJ scenarios when cards ship.
- For you parity (FR-SG-6) — separate micro-PR after PR-06 if inbox lags profile.

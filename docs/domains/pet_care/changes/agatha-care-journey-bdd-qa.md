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

**Programme:** [`agatha-care-journey-programme.md`](./agatha-care-journey-programme.md) · **Autonomy:** [`agatha-care-journey-execute-autonomy.md`](./agatha-care-journey-execute-autonomy.md)

## Strategy

| Layer | Tooling |
|-------|---------|
| Guardian flows | Gherkin → Playwright |
| API / rules | Jest first (BDD `@backend` = Jest only) |
| Widget | `flutter_test` |
| Boundaries in CI | `@smoke-ci` on **authz, policy, no-rhythm** — not happy paths |

**Feature file:** `e2e/bdd/features/pet_care/agatha_care_journey.feature` — **created in PR-01** (stub) or **PR-03** at latest; extend per PR.

---

## `@smoke-ci` policy (rework)

**Include (boundaries):**

- ACJ-SP-01 — safeguard hides rhythm  
- ACJ-IC-02 — view-only disabled primary  
- ACJ-WF-08 — welfare has no “add rhythm”  
- **ACJ-GUARD-01** (new) — completeness/welfare actions create **no** `HealthEntry`; Care Status unchanged  

**Exclude from `@smoke-ci` (pre-UAT / `@smoke-uat`):**

- ACJ-IC-01, ACJ-AC-01 (happy paths)  
- ACJ-CO-01 (PR-12, CSM-gated)  
- ACJ-PF-01, ACJ-WF-07 — **Jest only**, not Playwright  

---

## Scenario catalogue

### PR-01 — Jest (`profileFacts.test.js`)

- ACJ-PF-01 → AC-PF-01  
- **ACJ-PF-05** — old client PUT without status fields preserves statuses  
- **ACJ-PF-06** — normalisation / 400 for inconsistent pairs  

### PR-03 — Playwright

```gherkin
@acj @pr-03 @smoke-uat
Scenario: ACJ-IC-01 — Record neuter no from sheet on inset prompt
  ...

@acj @pr-03 @smoke-ci @authz
Scenario: ACJ-IC-02 — View-only cannot record profile facts
  ...
```

### PR-04 — Playwright + widget

```gherkin
@acj @pr-04 @smoke-uat
Scenario: ACJ-AC-01 — Chip recorded hides completeness card

@acj @pr-04
Scenario: ACJ-AC-02 — Agatha chrome

@acj @pr-04 @smoke-ci
Scenario: ACJ-GUARD-01 — Completeness actions do not create care rhythms
```

### PR-05 — Playwright

```gherkin
@acj @pr-05 @smoke-ci
Scenario: ACJ-SP-01 — Safeguard hides rhythm suggestion
```

### PR-06 — Jest

- ACJ-WF-06 — dismiss suppresses `dedupe_key` resurfacing (AC-WF-03)

### PR-07–08 — Jest + Playwright

- ACJ-WF-07 — **Jest** welfare evaluator when status `no`  
- ACJ-WF-08 — **@smoke-ci** Playwright no rhythm button  

### PR-09 — Jest integration

- ACJ-VX-01 — vaccination record minimum persisted  

### PR-10 — Jest

- ACJ-WF-11 — silence when data quality below threshold  

### PR-11 — Jest + Playwright

- ACJ-FB-01 — chip save clears welfare suggestion  

### PR-13 — Playwright

- ACJ-CO-02 — coordination banner links only (no merged item)  

### PR-12 — `@smoke-uat` only

- ACJ-CO-01 — same-day date header  

### PR-14 — Jest contract

- ACJ-VV-01 — visit link API schema  
- ACJ-FB-02 — visit complete does not auto-complete all occurrences (moved from PR-11)  

---

## Copy lint (requirement)

Script or CI step (PR-04): scan ARB keys listed in programme PR-04/07/08/10 for forbidden substrings (case-insensitive): `diagnose`, `dosage`, `required by law`, `cure`, `cancer`, `increase lifespan`.

Fail PR if new keys introduce them; existing legacy keys removed with O1 deletions.

---

## Full AC → test traceability (freeze before autonomy)

| AC | TDD / automated | BDD | Docs gate |
|----|-----------------|-----|-----------|
| AC-PF-01 | profileFacts.test.js | — | OpenAPI |
| AC-PF-02 | profileFacts.test.js | — | OpenAPI |
| AC-PF-03 | profileFacts.test.js, capability matrix | — | — |
| AC-PF-04 | profileFacts.test.js | — | — |
| AC-PF-05 | profileFacts.test.js | — | — |
| AC-PF-06 | profileFacts.test.js | — | — |
| AC-PF-07 | profileFacts.test.js | — | DATA_MAP PR-01 |
| AC-PF-10 | pet_model_test.dart | — | — |
| AC-PF-11 | pet_form_controller_test.dart | — | pet-profile-decisions |
| AC-IC-01 | sheet_widget_test.dart | ACJ-IC-01 `@smoke-uat` | — |
| AC-IC-02 | widget + capability test | ACJ-IC-02 `@smoke-ci` | — |
| AC-AC-01 | agatha_completeness_card_test.dart | ACJ-AC-01 `@smoke-uat` | — |
| AC-AC-02 | widget test | ACJ-AC-02 | — |
| AC-AC-03 | widget test | — | — |
| AC-AC-04 | widget + care status fixture | ACJ-GUARD-01 `@smoke-ci` | care-intelligence |
| AC-SP-01 | presentation_policy_test.dart | ACJ-SP-01 `@smoke-ci` | — |
| AC-SP-02 | presentation_policy_test.dart | — | care-intelligence |
| AC-WF-01 | welfareSuggestions.test.js | — | — |
| AC-WF-02 | welfareSuggestions.test.js | — | — |
| AC-WF-03 | welfareSuggestions.test.js | — | — |
| AC-WF-10 | welfare/fixtures microchip | ACJ-WF-07 Jest | copy lint |
| AC-WF-11 | welfare/fixtures vaccination | — | copy review PR-10 |
| AC-VX-01 | vaccinationRecord.test.js | — | DATA_MAP PR-09 |
| AC-FB-01 | welfare completion.test.js | ACJ-FB-01 `@smoke-uat` | — |
| AC-FB-02 | visitSchema.test.js | — | DATA_MAP PR-14 |
| AC-CO-01 | agendaGrouping.test.js | ACJ-CO-01 `@smoke-uat` | CSM cross-link |
| AC-CO-02 | coordinationCopy.test.js | ACJ-CO-02 | — |
| AC-VV-01 | visitSchema.test.js | — | governance log |

**Execute-plan:** PR-14 merge must pass **pre-UAT E2E** (`/babysit-uat`); not required for PR-01…13.

---

## QA Router tiers

| PRs | Tier | Protocols |
|-----|------|-----------|
| PR-01 | R2 | migrations, api-contract, authorization, DATA_MAP |
| PR-04–05 | R1–R2 | flutter-mobile, accessibility |
| PR-06 | R2 | security, api-contract |
| PR-12–14 | R2–R3 | release-verification |

---

## Regression (always green)

- `server/test/careIntelligence/recommendations.test.js` — rhythm / Care Status  
- CIM species gate tests unchanged  

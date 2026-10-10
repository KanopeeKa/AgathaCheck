---
title: Agatha care journey (execute-plan)
owner: Product / Agent
audience: agent
status: proposed
last_updated: 2026-10-10
tags: [pet_care, pet_profile, care_intelligence, roadmap]
---

# agatha-care-journey

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `agatha-care-journey` |
| **title** | Agatha care journey — Know → Remember |
| **base_branch** | `cursor/agatha-care-journey-integration-b994` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **programme_ref** | `docs/domains/pet_care/changes/agatha-care-journey-programme.md` |

## Goal

Deliver profile facts, Agatha completeness and welfare guidance, history feedback, and schedule coordination in **fourteen atomic PRs (PR-01 … PR-14)** without blocking parallel Care Schedule Management work. Single integration branch → one final PR to `main`.

**Read first (handoff):**

1. [`agatha-care-journey-programme.md`](../docs/domains/pet_care/changes/agatha-care-journey-programme.md) — objectives & AC per PR  
2. [`agatha-care-journey-ui-design.md`](../docs/domains/pet_care/changes/agatha-care-journey-ui-design.md) — UI rules  
3. [`agatha-care-journey-bdd-qa.md`](../docs/domains/pet_care/changes/agatha-care-journey-bdd-qa.md) — BDD/TDD/QA  

**Before gate:** Replace `control_issue: 1` and refresh `approved_at` / `approved_until` / `content_hash` via `node scripts/validate_execute_plan_snapshot.js --fix-hash`.

**Autonomy:** `halted` until `approve-autonomous agatha-care-journey`.

## Canonical docs (`docs_targets`)

| PR range | Canonical updates |
|----------|-------------------|
| PR-01–05 | `pet-profile-decisions.md`, presentation in `care-intelligence.md` |
| PR-06–11 | `care-intelligence.md`, notifications cross-links |
| PR-12–14 | `care-schedule-management.md`, `care-item-evolution.md` (grouping + visit invariants) |

## Working rules

- **Atomic PRs:** one PR-* per phase unless strengthen splits (update snapshot).
- **BDD → TDD:** add scenario or AC stub before implementation (bdd-qa doc).
- **Pre-PR:** critical self-review + canonical-docs sync on behaviour PRs.
- **Babysit:** `composer-2.5` only.
- **CSM parallel:** do not stop this plan for unrelated CSM merges; PR-12 waits **CSM-stable** (programme gate).

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: awaiting approve-autonomous
next_action: "Human review programme specs; bootstrap control issue; approve-autonomous agatha-care-journey"
artifact_ref:
  branch: cursor/agatha-care-journey-specs-b994
  plan_path: .agents/plans/agatha-care-journey.md
  snapshot_path: .agents/plans/agatha-care-journey.snapshot.json
open_prs: []
```

---

## Phase map

| Phase id | PR | Branch suffix (example) |
|----------|-----|-------------------------|
| `pr-01` | PR-01 | `cursor/acj-pr-01-profile-facts-server-b994` |
| `pr-02` | PR-02 | `cursor/acj-pr-02-profile-facts-flutter-b994` |
| … | … | … |
| `pr-14` | PR-14 | `cursor/acj-pr-14-visit-schema-b994` |

---

### Phase `pr-01` — PR-01 Profile fact model (server)

| Field | Value |
|-------|-------|
| **exit_checklist** | `default` + migrations |
| **router_risk** | R2 |
| **protocols** | `database-and-migrations`, `api-contract`, `authorization`, `documentation` |

**allowed_paths:** `db/migrations/*profile*`, `server/routes/**/pets*`, `server/test/pets/**`, `docs/architecture/openapi/**`

**Exit criteria:** AC-PF-01 … AC-PF-04; Jest green.

---

### Phase `pr-02` — PR-02 Profile facts Flutter + contract

**Depends:** merge `pr-01`

**allowed_paths:** `flutter_app/lib/features/pet_profile/**`, `flutter_app/test/features/pet_profile/**`, OpenAPI

**Exit criteria:** AC-PF-10, AC-PF-11.

---

### Phase `pr-03` — PR-03 Inline profile capture

**Depends:** merge `pr-02`

**allowed_paths:** `flutter_app/lib/features/experience/presentation/pet_profile/**`, tests, `e2e/bdd/features/pet_care/agatha_care_journey.feature` (stub)

**Exit criteria:** AC-IC-01, AC-IC-02; widget tests.

---

### Phase `pr-04` — PR-04 Agatha completeness cards

**Depends:** merge `pr-03`

**allowed_paths:** `care_intelligence/**` (shell widgets), `experience/**/pet_profile/**`, remove legacy inset usage

**Exit criteria:** AC-AC-01 … AC-AC-04; CIM-9 widget parity.

---

### Phase `pr-05` — PR-05 Agatha surface policy

**Depends:** merge `pr-04`

**allowed_paths:** `pet_care_presentation_policy.dart`, providers, tests, `care-intelligence.md`

**Exit criteria:** AC-SP-01, AC-SP-02.

---

### Phase `pr-06` — PR-06 Welfare suggestion framework

**Depends:** merge `pr-05`

**allowed_paths:** `server/routes/careIntelligence/**`, `server/lib/**/welfare*`, migrations, Flutter data layer

**Exit criteria:** AC-WF-01, AC-WF-02.

---

### Phase `pr-07` — PR-07 Welfare microchip

**Depends:** merge `pr-06`

**Exit criteria:** AC-WF-10; ACJ-WF-07.

---

### Phase `pr-08` — PR-08 Welfare neuter

**Depends:** merge `pr-06`

**Exit criteria:** ACJ-WF-08.

---

### Phase `pr-09` — PR-09 Vaccination record minimum

**Depends:** merge `pr-01` (may parallel `pr-07` after `pr-06` if paths disjoint — prefer sequential for same pet API)

**Exit criteria:** programme PR-09 AC.

---

### Phase `pr-10` — PR-10 Welfare vaccination

**Depends:** merge `pr-09`, `pr-06`

---

### Phase `pr-11` — PR-11 History feedback loop

**Depends:** merge `pr-06`

**Exit criteria:** AC-FB-01, AC-FB-02.

---

### Phase `pr-12` — PR-12 Same-day grouping

**Depends:** **CSM-stable** + merge `pr-11` (or earlier if only Flutter agenda)

**Exit criteria:** AC-CO-01.

---

### Phase `pr-13` — PR-13 Coordination copy

**Depends:** merge `pr-12`

---

### Phase `pr-14` — PR-14 Vet visit schema slice

**Depends:** merge `pr-12`; **halt** without product sign-off on decision log

**allowed_paths:** migrations, server routes, OpenAPI — **no** appointment UI

---

## Final merge

When `pr-14` (or accepted subset) is merged to integration:

1. `./scripts/pre-push.sh` on integration branch  
2. `/babysit-uat` on PR integration → `main`  
3. Fold programme `changes/` docs per canonical-docs skill  
4. Set snapshot `autonomy: completed`

## Spawn

`spawn_allowed: false` for all phases (sequential atomic PRs).

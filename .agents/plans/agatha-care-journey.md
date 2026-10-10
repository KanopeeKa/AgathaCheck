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
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **programme_ref** | `docs/domains/pet_care/changes/agatha-care-journey-programme.md` |

## Goal

Fourteen atomic PRs (PR-01 … PR-14), **each merging to `main`**. User-visible pieces behind **feature flags**. Migration phases require **manual merge checkpoint**.

**Autonomy:** `halted` until programme § Pre-approval checklist complete and `approve-autonomous agatha-care-journey`.

**Halt triggers:**

- PR-12 start without **ACJ-D-006** Live (`governance_approval_required`)
- PR-14 UI work without product gate

## Pre-approval (mandatory)

See programme doc § **Pre-approval checklist**. Do not run gate until all boxes checked and snapshot has real `control_issue` + valid approval window.

## Working rules

- BDD feature file from PR-01 stub; extend per bdd-qa doc.
- PR-12: agent **must not** self-declare CSM-stable.
- Migration phases: `merge_method: manual` in snapshot — human merges after review.

## Phase summary

| Phase | PR | Manual merge | Notes |
|-------|-----|--------------|-------|
| pr-01 | PR-01 | yes | OpenAPI + pets + org + sharing tests |
| pr-02 | PR-02 | no | Flutter |
| pr-03 | PR-03 | no | Sheet on inset prompt |
| pr-04 | PR-04 | no | Agatha cards + minimal policy + O1 deletes |
| pr-05 | PR-05 | no | Extended policy |
| pr-06 | PR-06 | yes | `welfare_suggestions` migration |
| pr-07–08 | PR-07/08 | no | Welfare fixtures |
| pr-09 | PR-09 | yes | Vaccination + DATA_MAP |
| pr-10 | PR-10 | no | Copy review gate |
| pr-11 | PR-11 | no | Feedback loop |
| pr-12 | PR-12 | no | **Requires ACJ-D-006** |
| pr-13 | PR-13 | no | |
| pr-14 | PR-14 | yes | Visit schema |

### Phase `pr-01` — allowed_paths (authoritative)

```
db/migrations/**
server/lib/pets/**
server/routes/pets/**
server/routes/organizations/petsRouter.js
server/lib/orgPetShadow.js
server/test/pets/**
server/test/organizations/petRedacted.test.js
server/test/sharing.test.js
server/test/sharedPetAccess.test.js
server/test/sharePreview.test.js
docs/architecture/openapi/**
regulatory/DATA_MAP.md
e2e/bdd/features/pet_care/agatha_care_journey.feature
```

**Exit:** AC-PF-01 … AC-PF-06

### Phase `pr-06` — depends merge `pr-01` only

**Exit:** AC-WF-01 … AC-WF-03; `welfare_suggestions` table live.

### Phase `pr-12` — depends ACJ-D-006 + merge `pr-11`

No alternate path if CSM not stable.

### Phase `pr-14` — depends product gate; **not** `pr-12`

## Completion

When accepted PRs are merged to `main`, fold `changes/agatha-care-journey-*.md`, set `autonomy: completed`. No integration-branch mega-PR.

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
| **autonomy_contract** | `docs/domains/pet_care/changes/agatha-care-journey-execute-autonomy.md` |

## Goal

Fourteen phases (**pr-01 … pr-14**), each **PR → `main`**. **No integration branch.** Full autonomy includes **`/babysit-uat`** on **pr-14** (pre-UAT E2E) before `complete-plan`.

**Read first:** programme · ui-design · bdd-qa · **execute-autonomy contract**.

## Autonomy (confirmed)

| Item | Policy |
|------|--------|
| Integration mega-PR | **Forbidden** |
| Per-phase merge | `main` via `/babysit-plus` |
| Final phase | `/babysit-uat` + pre-UAT watch on pr-14 merge SHA |
| Subagents | `spawn_allowed` on **pr-09** (parallel with pr-02 after pr-01) — ownership on control issue |
| Migration merges | `merge_method: manual` — halt `human_pause` after CI green |
| Model | `composer-2.5` for all babysit |

## Pre-approval

Programme § Pre-approval checklist + autonomy contract. Snapshot: real `control_issue`, valid approval window, `--fix-hash`.

## Per-phase exit (summary)

| Phase | Babysit | exit_checklist |
|-------|---------|----------------|
| pr-01,06,09,14 | plus / **uat on 14 only** | default + single-backend-route + governance |
| pr-04,12,13 | plus | + bdd-journey where noted in autonomy doc |
| pr-02,03,04,05,07,08,10,11 | plus | default + flutter-screen-split (+ backend where applicable) |

**TDD → BDD → Docs:** mandatory order per autonomy contract § Phase hygiene.

## Halt

- PR-12 without ACJ-D-006 Live
- PR-14 UI without product gate
- CSM-stable self-declaration (forbidden)

## Completion

All phases `merged` on `main`; pr-14 pre-UAT green; fold `changes/` docs; `autonomy: completed`.

See snapshot for `allowed_paths`, `spawn_allowed`, `merge_method`.

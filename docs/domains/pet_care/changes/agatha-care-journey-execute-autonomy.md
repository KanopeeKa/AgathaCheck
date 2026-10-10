---
title: Agatha care journey — execute-plan autonomy contract
owner: Product / Documentation
audience: agent
domain: pet_care
status: proposed
status_since: 2026-10-10
parent: agatha-care-journey-programme.md
related_plan: .agents/plans/agatha-care-journey.md
tags: [execute-plan, autonomy, uat]
---

# Execute-plan autonomy contract

Governs **`agatha-care-journey`** when `approve-autonomous` is granted. Pair with [programme](./agatha-care-journey-programme.md) and [bdd-qa](./agatha-care-journey-bdd-qa.md).

## Delivery shape (confirmed)

| Rule | Value |
|------|--------|
| **Integration branch** | **None.** No `cursor/agatha-care-journey-integration-*`, no single mega-PR integration → `main`. |
| **Per phase** | One PR → **`main`**; value ships incrementally (flags where needed). |
| **Orchestrator** | `/execute-plan agatha-care-journey` — run-until-blocked; `composer-2.5` for all babysit steps. |
| **Subagents** | **Allowed** for disjoint phases (see § Parallelism); brief via `phase-implementer.md`. |
| **UAT** | **Included** in autonomy — final phase uses **`/babysit-uat`** (pre-UAT E2E on `main`); remedial via **`/e2e-debug`** same session. |

## Phase hygiene (every PR)

| Step | Requirement |
|------|----------------|
| 1 | **TDD:** failing tests for this phase’s AC-* **before** production code (bdd-qa traceability). |
| 2 | **BDD:** extend `agatha_care_journey.feature` when guardian-visible; wire Playwright when steps exist. |
| 3 | **Docs:** `/canonical-docs sync` Mode A before PR open if behaviour changes; PR body `## Docs`. |
| 4 | **Pre-PR** | Critical self-review (pr-hygiene). |
| 5 | **Verify** | `./scripts/pre-push-changed.sh`; migration phases also `./scripts/pre-push.sh` before merge request. |
| 6 | **Babysit** | See § Babysit matrix below. |

## Babysit / UAT matrix

| Phase | PR | Merge skill | Pre-UAT E2E watch |
|-------|-----|-------------|-------------------|
| pr-01 … pr-13 | PR-01 … PR-13 | **`/babysit-plus`** | No (CI on PR + main trunk) |
| **pr-14** | PR-14 | **`/babysit-uat`** | **Yes** — gate before `complete-plan` |
| Remedial | any | `/e2e-debug` → **`/babysit-uat`** on remedial PR | Yes |

**Not in scope for agent:** polling `promote-uat` / `deploy-uat` (CI owns promotion per `uat-deploy-tiers.md`).

**Migration phases (PR-01, PR-06, PR-09, PR-14):** snapshot `merge_method: manual` — orchestrator runs babysit+ through CI green, then **halts** with `human_pause` until merge button / `resume-plan` after human squash-merge (data migration review).

## Parallelism (subagents)

Publish ownership in control issue before spawning.

| Window | Phases | Disjoint? | Spawn |
|--------|--------|-----------|-------|
| After pr-01 merge | **pr-02** (Flutter) ∥ **pr-09** (vax schema) | Yes — server vax vs flutter pet_profile | `spawn_allowed: true` on pr-09 |
| After pr-06 merge | pr-07 then pr-08 | Same welfare evaluator paths — **sequential** | spawn false |
| pr-03 → pr-04 | Sequential | Shared pet profile UI | spawn false |

**Rule:** max one active PR per overlapping `allowed_paths`; integration merges = rebase onto `origin/main` between phases.

## Exit checklist profiles (snapshot)

| Phase | `exit_checklist` |
|-------|------------------|
| pr-01, pr-06, pr-09, pr-14 | `default` + `single-backend-route` + `governance` (migrations) |
| pr-02, pr-03, pr-05 | `default` + `flutter-screen-split` |
| pr-04 | `default` + `flutter-screen-split` + `bdd-journey` |
| pr-07–08, pr-10–11 | `default` + `single-backend-route` + `flutter-screen-split` |
| pr-12–13 | `default` + `bdd-journey` |
| pr-14 | `default` + `single-backend-route` + `governance` |

## Feature flags (defaults off until wave sign-off)

| Flag key | PR | Surface |
|----------|-----|---------|
| `acj_profile_facts_ui` | PR-02 | Form enums |
| `acj_inline_profile_capture` | PR-03 | Sheet |
| `acj_completeness_cards` | PR-04 | Agatha completeness |
| `acj_welfare_suggestions` | PR-06+ | Welfare cards |
| `acj_agenda_date_groups` | PR-12 | Actions grouping |
| `acj_coordination_copy` | PR-13 | Coordination banner |

Orchestrator enables flag in same PR that ships the surface (or documents server-side gating).

## `complete-plan` criteria

- All phases `merged` on `main`
- **pr-14** merge SHA passed **pre-UAT E2E** watch
- Programme `changes/` folded per canonical-docs skill
- Snapshot `autonomy: completed`

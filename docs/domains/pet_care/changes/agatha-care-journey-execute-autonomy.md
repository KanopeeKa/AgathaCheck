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

Governs **`agatha-care-journey`** when `approve-autonomous` is granted. Aligns with [execute-plan skill](/.cursor/skills/execute-plan/SKILL.md) and [execute-plan-schema.md](/docs/agent-efficiency/execute-plan-schema.md).

## Delivery shape (full autonomy — confirmed)

| Rule | Value |
|------|--------|
| **Integration branch** | `cursor/agatha-care-journey-integration-b994` — **all phase PRs target this branch**, not `main`. |
| **Per phase** | `pr-01` … `pr-14` → `/babysit-plus` → squash-merge into **integration**. |
| **Release to main** | After all phases `merged` on integration: **one PR** integration → `main` → **`/babysit-uat`** (pre-UAT E2E on that merge SHA). |
| **Orchestrator** | `/execute-plan agatha-care-journey` — run-until-blocked; `composer-2.5` for babysit. |
| **Subagents** | Allowed when `spawn_allowed` (e.g. **pr-09** ∥ **pr-02** after pr-01). |
| **UAT** | Included — **release PR** to `main` is the `/babysit-uat` gate; remedial via `/e2e-debug` same session. |

**Do not** open phase PRs against `main`. **Do not** merge programme slices to `main` until the release PR.

## Phase hygiene (every phase)

| Step | Requirement |
|------|----------------|
| 1 | **TDD** — failing tests for phase AC-* first ([bdd-qa](./agatha-care-journey-bdd-qa.md)). |
| 2 | **BDD** — extend `agatha_care_journey.feature` when guardian-visible. |
| 3 | **Docs** — `/canonical-docs sync` Mode A before PR open when behaviour changes. |
| 4 | **Pre-PR** — critical self-review. |
| 5 | **Verify** — `./scripts/pre-push-changed.sh` (full `./scripts/pre-push.sh` before release PR). |
| 6 | **Babysit** — `/babysit-plus` → merge to **integration**. |

## Babysit / UAT matrix

| Step | Target | Skill | Pre-UAT watch |
|------|--------|-------|----------------|
| pr-01 … pr-14 | `cursor/agatha-care-journey-integration-b994` | `/babysit-plus` | No |
| **Release PR** | `main` | **`/babysit-uat`** | **Yes** |
| Pre-UAT failure | remedial PR → `main` | `/e2e-debug` → `/babysit-uat` | Yes |

**Not in scope:** polling `promote-uat` / `deploy-uat`.

**Migration phases (PR-01, PR-06, PR-09, PR-14):** after CI green, orchestrator may **`halt --reason human_pause`** for human migration review on control issue **#1835**; comment `resume-plan agatha-care-journey` to continue merge to integration.

## Parallelism

Rebase phase branches on `origin/cursor/agatha-care-journey-integration-b994` between phases.

| Window | Spawn |
|--------|-------|
| After pr-01 → pr-02 ∥ pr-09 | `spawn_allowed: true` on pr-09 |
| pr-07 → pr-08 | sequential |

## Exit checklists

Per snapshot `exit_checklist` profiles (see programme verification pack).

## Feature flags

Unchanged — enable with surface PRs on integration; release PR may flip defaults on `main`.

## `complete-plan`

- All 14 phases `merged` on integration  
- Release PR merged to `main` with **pre-UAT green**  
- Fold `changes/` docs  
- `autonomy: completed`

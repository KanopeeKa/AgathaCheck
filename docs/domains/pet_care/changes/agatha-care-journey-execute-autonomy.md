---
title: Agatha care journey — execute-plan autonomy contract
owner: Product / Documentation
audience: agent
status: proposed
last_updated: 2026-10-10
status_since: 2026-10-10
tags: [execute-plan, autonomy, uat]
folds_into: docs/domains/pet_care/features/care-intelligence.md
---

# Execute-plan autonomy contract

Governs **`agatha-care-journey`** under `approve-autonomous` on **#1835**. **Binding orchestrator text:** `.agents/plans/agatha-care-journey.md` §Orchestrator contract (wins over generic agent “summarize progress” behavior).

## Full autonomy grant (what was approved)

One standing grant covers **entire** delivery:

- Phases **pr-01 … pr-14** → integration `cursor/agatha-care-journey-integration-b994`
- **Release PR** integration → **`main`** → **`/babysit-uat`**
- Orchestrator **run-until-blocked** — no per-phase or per-turn permission in user chat

## Delivery shape

| Rule | Value |
|------|--------|
| **Integration branch** | `cursor/agatha-care-journey-integration-b994` — phase PRs target this, **not** `main`. |
| **Per phase** | Implement → PR → **/babysit-plus** → squash-merge into integration → **next phase same session**. |
| **Release** | One PR integration → `main` → `/babysit-uat` → `complete-plan`. |
| **Babysit model** | `composer-2.5` for babysit steps. |
| **Subagents** | When `spawn_allowed` (e.g. pr-09 ∥ pr-02 after pr-01). |

## Run-until-blocked (default — the only operating mode)

| Valid stop | Action after |
|------------|----------------|
| Phase PR **merged** to integration | Start next `pending` phase **immediately** (no user chat checkpoint) |
| All phases merged | Open release PR → `/babysit-uat` |
| `complete-plan` | Close control issue |
| §Halt / escalation / `session_limit` | Post on #1835; chat = blocker alert only |

| **Not** a stop | Required behavior |
|----------------|-------------------|
| Preflight / gate exit 0 | Begin current phase work |
| PR opened | Babysit+ / CI watch |
| CI pending | Keep watching; fix and push |
| Milestone posted on #1835 | Continue tools in same session |
| Cloud turn ended | Next `/execute-plan` resumes `next_action` |

### Anti-patterns (do not do these)

- Ending the turn with a progress summary after PR #N or “CI is running”
- Asking the human to confirm continuation for the next phase
- Leaving an open phase PR unmerged while starting narrative about the following phase

## Migrations (PR-01, 06, 09, 14)

| Default | Exception (opt-in only) |
|---------|-------------------------|
| Merge to integration when CI green | Orchestrator runs `halt --reason human_pause` on #1835 **before** merge; human comments `resume-plan agatha-care-journey` |

**Wording trap:** programme tables may say “human_pause” beside migrations — that describes an **allowed halt**, not a **required** human gate. Unless `halt` was written to the snapshot, **merge automatically**.

## Phase hygiene (every phase)

| Step | Requirement |
|------|----------------|
| 1 | TDD first ([bdd-qa](./agatha-care-journey-bdd-qa.md)) |
| 2 | BDD when guardian-visible |
| 3 | `/canonical-docs sync` before PR when behaviour changes |
| 4 | Pre-PR critical self-review |
| 5 | `./scripts/pre-push-changed.sh` |
| 6 | `/babysit-plus` → merge to integration |

## Babysit / UAT matrix

| Step | Target | Skill | Pre-UAT watch |
|------|--------|-------|----------------|
| pr-01 … pr-14 | integration branch | `/babysit-plus` | No |
| Release PR | `main` | `/babysit-uat` | Yes |
| Pre-UAT failure | remedial → `main` | `/e2e-debug` → `/babysit-uat` | Yes |

Do **not** poll `promote-uat` / `deploy-uat`.

## Parallelism

After pr-01 merged: pr-02 and pr-09 may run in parallel when `spawn_allowed` on pr-09. Rebase on `origin/cursor/agatha-care-journey-integration-b994` between phases.

## `complete-plan`

All 14 phases merged on integration; release PR merged to `main` with pre-UAT green; fold `changes/` docs; `autonomy: completed`.

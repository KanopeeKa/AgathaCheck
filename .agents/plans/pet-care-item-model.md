---
title: Pet Care Item Model & Profile Surface — Roadmap
owner: Product / Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, care_item, pet_profile, roadmap]
---

# pet-care-item-model (roadmap)

> **plan_kind:** `roadmap` — this plan orchestrates seven child plans. It does not itself change
> runtime code beyond plan/doc artifacts.
>
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `pet-care-item-model` |
| **plan_kind** | `roadmap` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |
| **programme_ref** | `docs/domains/pet_care/changes/care-item-model-delivery-plan.md` |

## Goal

Refactor the Pet Profile care experience so the profile reads as a concise picture of the pet's
current care situation: one user-facing **Care Item** concept, one temporally-grouped
**`{Pet}'s care`** section, derived attention states, and quieter treatment for weight, health
issues, and timeline. Domain/UI logic consolidation plus UX/UI presentation, delivered as atomic
PRs.

---

## READ THIS FIRST (handoff to the implementing model)

This plan was **authored by one model and is to be executed by another**. Everything you need is
written down; nothing is carried in chat context.

### Before your first phase

1. **Read the specification end to end:**
   `docs/domains/pet_care/changes/care-item-model-delivery-plan.md`. It contains the settled
   decisions, the canonical naming table, the component contracts, and — importantly — §13
   *explicitly rejected*. Check §13 before adding anything that is not in a child plan.
   **§4.0 in particular records verified file-level facts** (the real D38 table, the real `.arb`
   values, and the fact that `allCare` is one key serving two different scopes). Several plausible
   naming choices are ruled out by it. Do not skip it.
2. **Do not re-litigate settled decisions.** They came out of an analysis-and-challenge cycle with
   the product owner. If you believe one is wrong, halt and say so on the control issue; do not
   quietly implement the alternative.
3. **`control_issue` is a placeholder (`1`) in every snapshot in this roadmap.** Before running any
   gate, bootstrap the real issue and update the snapshot:
   ```bash
   node scripts/execute_plan_runtime.js init-control-issue <child_plan_id>
   # then set control_issue in the snapshot and re-hash:
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/<child_plan_id>.snapshot.json
   ```
4. **`approved_at` / `approved_until` are placeholders.** They must be refreshed at actual approval
   time; `approved_until` is a 48h window from approval, and gate fails once it passes. Re-hash
   after editing.
5. **`autonomy` is `halted` in every child snapshot.** The product owner flips the active child to
   `active` when approving it. The content hash freezes **at approval**, so editing these fields
   beforehand is expected and correct.

### Working rules

- **Default to one child plan at a time** — land it (all phases merged) before bootstrapping the
  next. The one sanctioned exception is running A, B, and C concurrently; see §Parallelism.
- **Child A and Child B are prerequisites for all UI work.** Do not start Child D before both are
  merged — see §3 and §5 of the spec for why.
- **Atomic PRs:** one verifiable outcome per PR (`.cursor/rules/atomic-pr.mdc`).
- **Model policy:** `composer-2.5` for PR babysitting (`.cursor/rules/pr-hygiene.mdc`).
- **Pre-PR critical self-review is mandatory** on every PR (`.cursor/rules/pr-hygiene.mdc`).
- **Commit messages:** `phase(N/M): …`.
- When a phase retires a row, title, or string, **fix the BDD/Playwright selectors in that same
  phase** — never defer to a later cleanup phase.

---

## Child plans

Execute in order. Each has its own plan file and snapshot under `.agents/plans/`.

| # | plan_id | Outcome | Depends on |
|---|---------|---------|-----------|
| A | `care-status-consolidation` | One care-status/temporal-grouping derivation consumed by profile, All care, and dashboard; shared seed fixture | — |
| B | `care-presentation-primitives` | The four semantic-role widgets + sparkline + shared tokens; care-status contrast fix | — |
| C | `care-family-taxonomy` | Remove bad `care_family` inference; deterministic backfill | A |
| C2 | `care-family-required` | `care_family` required on create; suggest-and-confirm on edit | C + **governance sign-off (O2)** |
| D | `pet-profile-care-surface` | `{Pet}'s care` section, then Pet Profile recomposition (attention / action / insight / destination) | A, B |
| E | `care-management-surfaces` | All care destination + Care Item detail + retire Care Rhythms screen | B, D |
| F | `care-copy-and-terminology` | Naming/D38 amendment, occurrence-copy semantic migration, l10n retirement, nav highlighting fix | D, E |

### Why this order

- **A before everything UI:** grouping Care Items temporally on the profile requires the profile,
  the list, and the dashboard to agree. Four competing derivations (spec §3) would make
  "needs attention" on the profile contradict "overdue" in All care.
- **B before D and E:** the four visual roles must exist as shared primitives before screens consume
  them, or each screen hand-rolls its own and the treatments drift.
- **C and C2 independent of the UI phases:** correctness of `care_family` matters because Child D
  surfaces family-derived states, but neither plan needs the UI and the UI does not need
  enforcement. They must not be bundled with presentation work.
- **C2 separate from C:** requiring `care_family` on create is a **breaking API change**. It gets its
  own plan and its own approval so it can be deferred or refused without blocking the roadmap.
  Backfill (C) must merge before enforcement (C2) or existing clients break immediately.
- **F last:** copy and terminology changes are cheap to land but break E2E selectors; doing them
  after the surfaces settle avoids fixing the same selectors twice.

### Parallelism

A, B, and C are mutually independent and may run concurrently (`/spawn-sprint-agents`) if the
product owner wants the roadmap compressed. D onwards is strictly sequential. If A, B, and C are
parallelised they must use an integration branch per `.cursor/rules/merge-policy.mdc`.

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder** — 48h from approval) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue`) |
| **autonomy** | `halted` — awaiting `approve-autonomous pet-care-item-model` |

No standing grant yet. The product owner approves either the roadmap as a standing grant or each
child plan individually.

## Phases

### Phase `orchestrate` — child plan bootstrap and tracking

| Field | Value |
|-------|-------|
| **id** | `orchestrate` |
| **branch** | `cursor/care-item-model-orchestrate-c9c6` |
| **exit_checklist** | `governance` |
| **merge_mode** | `auto` |

**allowed_paths:** `.agents/plans/pet-care-item-model.*`, `.agents/plans/care-status-consolidation.*`,
`.agents/plans/care-presentation-primitives.*`, `.agents/plans/care-family-taxonomy.*`,
`.agents/plans/care-family-required.*`, `.agents/plans/pet-profile-care-surface.*`,
`.agents/plans/care-management-surfaces.*`, `.agents/plans/care-copy-and-terminology.*`,
`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`

**allowed_exceptions:** `docs`

This phase exists so the roadmap can update its own child-plan statuses and refresh child snapshots
as each slice lands. It must not touch `flutter_app/**` or `server/**`.

## Runtime state

```yaml
autonomy: halted
current_phase: orchestrate
last_completed_phase: null
halt_reason: halted
next_action: "bootstrap and gate child plan care-family-taxonomy"
artifact_ref:
  branch: main
  plan_path: .agents/plans/pet-care-item-model.md
  plan_commit: 3e736c1daa1275888988b2a47eb4128689b3d56b
  snapshot_path: .agents/plans/pet-care-item-model.snapshot.json
  snapshot_commit: 3e736c1daa1275888988b2a47eb4128689b3d56b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Escalation triggers (halt, do not proceed)

| Trigger | Child |
|---|---|
| Breaking API contract without governance sign-off (`care_family` required) | C2 |
| Open item **O4** (FR title for the pet-scoped `All care` destination) undecided | F |
| Open item **O3** (tablet weight-tile placement) needs a product call | D |
| A settled decision in the spec appears wrong | any |
| A canonical doc (`terminology.md` D38, `care-progression.md`) would need weakening | F |
| File-size gate can only be met by allowlisting a new file | B, D, E |
| BDD coverage would regress | D, E, F |

## Decisions the product owner still owes (see spec §14)

| # | Decision |
|---|---|
| O2 | Approve, defer, or refuse the breaking `care_family` required-field change (`care-family-required`) |
| O4 | FR title for the pet-scoped `All care` destination — recommended `Tous les soins de {petName}` |
| O1 | Skim the additive D38 amendment diff when Child F opens |
| O3 | Tablet weight-tile placement — decidable from a screenshot during Child D |

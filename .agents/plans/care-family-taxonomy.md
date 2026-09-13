---
title: Care family taxonomy correctness (Child C)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, care_family, api_contract, migration, plan]
---

# care-family-taxonomy

> **Child C of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§7** before starting.
> **Depends on:** Child A (shared seed fixture).

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-family-taxonomy` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Stop guessing `care_family`: remove the inference and backfill deterministically where the mapping
is unambiguous, so "unknown" is honestly unknown instead of confidently wrong.

**Enforcement is deliberately not in this plan.** Making `care_family` required on create is a
breaking API change and lives in [`care-family-required`](./care-family-required.md) so it can be
approved — or refused — on its own merits.

## Why

`inferCareFamilyFromType` in `server/routes/healthEntries/shared.js` guesses `care_family` from the
coarse `type` field (`medication` / `preventive` / `vet_visit` / `other`). The guess is frequently
wrong. Progression (`care_establishments`, `weightEstablishmentPolicy.js`) and Care Intelligence
both key off `care_family`, and Child D's UI will surface family icons and family-scoped states.
Building family-aware UI on a bad inference propagates the error into the interface, where the carer
sees it and loses trust.

**The decision is not "infer better". It is "stop inferring".** A better heuristic is explicitly
rejected (spec §13).

## Ordering constraint

**Backfill and tolerate-missing ship before enforcement.** If the required-field enforcement in
`care-family-required` landed first, existing clients would break immediately. This plan must merge
completely before that one starts.

## Non-goals

- No enforcement of a required `care_family` — separate plan (see Goal).
- No presentation work. Family icons and family-scoped UI are Child D.
- No change to what `supportsEstablishment` returns (`server/lib/care/capabilities.js` — today
  weight_monitoring only). Widening establishment is a separate product decision.

---

## Phase 1 — Remove inference, tolerate missing family

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-family-remove-inference-c9c6` |
| **exit_checklist** | `single-backend-route` |
| **merge_mode** | `auto` |

**Scope**

- Delete `inferCareFamilyFromType` and its call sites in `server/routes/healthEntries/**`.
- `care_family` becomes nullable/absent-tolerant end to end: reads, writes, progression evaluation,
  and intelligence must all handle an uncategorised item without throwing and without inventing a
  family.
- Uncategorised items remain fully functional: listable, completable, editable. They simply do not
  participate in family-specific progression or intelligence.

**Exit criteria**

- [ ] `rg inferCareFamilyFromType server` returns nothing.
- [ ] Jest tests: create/read/update/complete an item with no `care_family`; progression evaluation
      skips it cleanly; intelligence arbitration ignores it.
- [ ] No raw exception text in any 5xx body.
- [ ] Calendar dates still `YYYY-MM-DD` on the wire.
- [ ] API contract note added to the PR body: what a client now sees when `care_family` is absent.

**allowed_paths**

```
server/routes/healthEntries/**
server/lib/care/**
server/test/healthEntries/**
server/test/care/**
server/test/careProgression/**
server/test/careIntelligence/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Phase 2 — Deterministic backfill migration

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-family-backfill-c9c6` |
| **exit_checklist** | `single-backend-route` |
| **merge_mode** | `auto` |

**Scope**

Migration that sets `care_family` **only** where the mapping is unambiguous. Everything else is left
explicitly uncategorised.

Before writing the migration, enumerate the actual distinct `(type, name, frequency)` shapes present
in the data and decide per shape. Record the mapping table in the PR body. **If a shape is
arguable, leave it uncategorised** — that is the whole point of the phase.

**Exit criteria**

- [ ] Forward migration under `db/` + registered per `server/scripts/migrate.js`; `up` runs clean on
      a fresh DB and on the Child A seed.
- [ ] Migration is idempotent and re-runnable.
- [ ] Rollback path documented (even if the rollback is "leave values in place").
- [ ] No `gen_random_uuid()` in SQL — UUIDs in code (`AGENTS.md`).
- [ ] PR body contains the mapping table and the count of rows deliberately left uncategorised.
- [ ] `db/schema/canonical.sql` updated if the schema shape changes.

**allowed_paths**

```
db/migrations/**
db/schema/canonical.sql
server/scripts/migrate.js
server/test/migrations/**
```

**allowed_exceptions:** `tests`, `docs`

> **Migration escalation check:** this alters production data shape. Confirm on the control issue
> before merge.

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-family-taxonomy`) |
| **autonomy** | `halted` — awaiting approval |

## Runtime state

```yaml
autonomy: halted
current_phase: null
last_completed_phase: null
halt_reason: "awaiting approval"
next_action: "bootstrap control issue, refresh approval window, set autonomy active"
artifact_ref:
  branch: cursor/care-item-model-plans-c9c6
  plan_path: .agents/plans/care-family-taxonomy.md
  plan_commit: null
  snapshot_path: .agents/plans/care-family-taxonomy.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

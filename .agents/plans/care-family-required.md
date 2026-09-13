---
title: Care family required on create (Child C2)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-13
tags: [pet_care, care_family, api_contract, breaking_change, plan]
---

# care-family-required

> **Child C2 of** [`pet-care-item-model`](./pet-care-item-model.md)
> **Specification:** [`docs/domains/pet_care/changes/care-item-model-delivery-plan.md`](../../docs/domains/pet_care/changes/care-item-model-delivery-plan.md) — read **§7** before starting.
> **Depends on:** [`care-family-taxonomy`](./care-family-taxonomy.md) fully merged.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-family-required` |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Make `care_family` required when creating a Care Item, and handle pre-existing uncategorised items
on edit with a **suggest-and-confirm** treatment rather than a forced choice.

## Why this is a separate plan

Making `care_family` required on create is a **breaking API contract change** for older clients.
Per `docs/agent-efficiency/phase-exit-checklists.md` §Escalation that is a stop-and-ask condition,
so it gets its own plan and its own approval rather than riding along inside the taxonomy cleanup.
It can be approved, deferred, or refused without blocking anything else in the roadmap.

## Blocking preconditions — verify all three before starting

1. **`care-family-taxonomy` is fully merged.** Backfill and tolerate-missing must ship first; if
   enforcement lands before the backfill, existing clients break immediately.
2. **Governance sign-off for the breaking change is recorded on the control issue** (spec open item
   **O2**). No sign-off, no start.
3. **A client-version story exists**: state in the PR body what an older client sees when it posts
   without `care_family`, and why that response is acceptable.

## Non-goals

- No presentation work beyond the form itself.
- No change to `supportsEstablishment`.
- No retroactive rejection of existing uncategorised items — they stay valid and usable.

---

## Phase 1 — Server: required on create

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/care-family-required-server-c9c6` |
| **exit_checklist** | `single-backend-route` |
| **merge_mode** | `auto` |

**Scope**

- `care_family` required on create at the API boundary.
- Missing value returns a **validation error with a usable message** — a 4xx, not a 5xx, and no raw
  exception text in the body.
- Update is **not** made required: existing uncategorised items must remain editable and saveable
  without forcing a family (that is phase 2's suggest-and-confirm).

**Exit criteria**

- [ ] Jest test: create without `care_family` → 4xx validation error with a usable message.
- [ ] Jest test: update an existing uncategorised item **without** supplying a family → succeeds.
- [ ] No raw exception text in any 5xx body.
- [ ] Calendar dates still `YYYY-MM-DD` on the wire.
- [ ] API contract change documented; the governance sign-off comment linked in the PR body.

**allowed_paths**

```
server/routes/healthEntries/**
server/test/healthEntries/**
docs/domains/pet_care/**
```

**allowed_exceptions:** `tests`, `docs`

---

## Phase 2 — Client: required on add, suggest-and-confirm on edit

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-family-required-client-c9c6` |
| **exit_checklist** | `flutter-screen-split` |
| **merge_mode** | `auto` |

**Scope**

- `health_entry_form_screen.dart`: family becomes a first-class **required** field on add, with
  inline validation matching the server's rule.
- **On edit of an uncategorised item: suggest and confirm, never force.** Pre-select the most likely
  family, present it *as a suggestion*, and let the carer accept, change, or ignore it. Saving
  without accepting must still succeed.

A forced modal on an unrelated edit is hostile and is explicitly rejected (spec §13). Do not
implement one.

**Exit criteria**

- [ ] Widget test: add flow blocks submit until a family is chosen, with an inline message.
- [ ] Widget test: editing an uncategorised item shows a **dismissible** suggestion and saving
      without accepting it succeeds.
- [ ] Widget test: editing an already-categorised item shows no suggestion at all.
- [ ] `flutter analyze --no-fatal-warnings --no-fatal-infos` clean.
- [ ] Semantic label on the family control; `Key` for E2E.
- [ ] `node scripts/check_file_size.js` passes — `health_entry_form_screen.dart` is already large, so
      split it if needed. The `file-split` exception is granted for exactly this; do not allowlist.
- [ ] Screenshots of the add-flow validation and the edit-flow suggestion.

**allowed_paths**

```
flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form_screen.dart
flutter_app/lib/features/health_tracking/presentation/screens/health_entry_form/**
flutter_app/lib/features/health_tracking/presentation/widgets/**
flutter_app/lib/l10n/**
flutter_app/test/features/health_tracking/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-13T12:40:00Z` (**placeholder** — refresh at approval) |
| **approved_until** | `2026-09-15T12:40:00Z` (**placeholder**) |
| **control_issue** | `1` (**placeholder** — run `init-control-issue care-family-required`) |
| **autonomy** | `halted` — awaiting approval **and** O2 governance sign-off |

## Runtime state

```yaml
autonomy: halted
current_phase: 2
last_completed_phase: 1
halt_reason: halted
next_action: "start phase 2: checkout cursor/care-family-required-client-c9c6"
artifact_ref:
  branch: main
  plan_path: .agents/plans/care-family-required.md
  plan_commit: f9dd24c01340dc6330b664d60f5277c1d63aa880
  snapshot_path: .agents/plans/care-family-required.snapshot.json
  snapshot_commit: f9dd24c01340dc6330b664d60f5277c1d63aa880
open_prs: []
merge_commits: {"1":"f9dd24c01340dc6330b664d60f5277c1d63aa880"}
debt_issue_refs: []
```

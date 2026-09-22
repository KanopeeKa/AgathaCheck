---
title: Away Planning — Decision log
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-22
tags: [pet_care, care_context, decisions]
---

# Away Planning — Decision log

Frozen product and engineering decisions for **Away Planning V1**. Canonical behaviour: [care-context.md](../features/care-context.md). Delivery sequencing: [away-planning-delivery-plan.md](./away-planning-delivery-plan.md).

**Context:** AgathaTrack is **not in production**; no real user data exists. Verified against `main` through `fcc8a804` (2026-09-15). Care Schedule Management V1 merged in [#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193).

**Confirmed 2026-09-15** after plan review ([#1196](https://github.com/KanopeeKa/AgathaCheck/pull/1196)). All decisions below are **Frozen**.

---

## D-AWAY-001 — Away Planning does not introduce a second "status" (2026-09-15)

**Status:** Frozen

"Recorded" / "Prepared" / "ready" is never a column. `planned_absences.status` keeps exactly two meanings: `active` and `cancelled`.

Facts about carers and coverage are computed **server-side** at read time so the tile, hub, plan page, and PDF cannot disagree.

---

## D-AWAY-002 — Readiness is two facts, not one verdict (2026-09-15)

**Status:** Frozen

**Rejected:** a single "Recorded"/"Prepared" verdict or any ranking that collapses carer and coverage into one score.

Surface **two independent facts**, using existing vocabulary only:

| Fact | Source |
|------|--------|
| **Carer coverage** | Per pet: `planned_absence_pets.carer_kind` set or unset. At absence level: all pets have a carer / some do / none do. |
| **Care coverage** | `evaluateCarePeriodCoverage()` → `coverage_state` (and `reassurance_available` only as the existing "may we speak?" flag). |

`CarePeriodCoveragePolicy` (`server/lib/care/carePeriodCoverage.js`) is the **only** implementation of care coverage. Away Planning adds no new coverage vocabulary.

**Copy rule:** reassurance sentences key off `coverage_state`. `nothing_scheduled` must **never** render as "Everything looks covered for these dates" — that claims coverage of nothing.

**Presentation (no cross-axis ranking):**

- **Plan page and hub** — room for both facts; show both with no ranking. **Amended 2026-09-22 by [D-AWD-001](/docs/domains/pet_care/changes/away-plan-detail-v2-decisions.md#d-awd-001--plan-page-readiness-becomes-attention-only-supersedes-part-of-d-away-002):** on the **plan page's `AwayPlanHeaderSection` only**, each line now renders only when it's actionable (not all carers assigned / items to review or indeterminate). Not touched: the handover PDF (unconditional, both lines), and the hub's list entries (`planned_absence_entry_tile.dart`), which as shipped already resolve through `AwayPlanningTileCopy` — the same fixed-priority mechanism as the dashboard tile below, not a "both facts" treatment. That's a pre-existing V1 implementation detail this amendment doesn't change or attempt to reconcile.
- **Dashboard tile** — space-constrained; use a **fixed actionability priority**, not a strength comparison across axes:
  1. If any pet lacks a carer → surface that (only fact the guardian alone can resolve; concerns people).
  2. Else → surface the coverage sentence for the current `coverage_state`.

**Tests:** assert a **triple** per matrix cell — carer fact, coverage fact, tile copy selected — not one enum (3 carer states × 5 coverage states = 15 cases).

---

## D-AWAY-003 — Carer is per pet per absence, on the existing join table (2026-09-15)

**Status:** Frozen

```text
planned_absence_pets (additions)
  carer_kind      TEXT   NULL   -- 'shared_user' | 'note_only' | NULL (unset)
  carer_user_id   UUID   NULL   -- FK users(id) ON DELETE SET NULL
  carer_name      TEXT   NULL   -- note_only only
  carer_note      TEXT   NULL   -- note_only only
```

Per-pet, not per-care-item. "Luna → Sarah, Milo → Tom" is in scope; per-item assignment is Pet Sitting and out of scope.

**Migration notes:** first CHECK constraints on this table (`planned_absences` has none on `status`/`provenance` today — deliberate tightening). `carer_user_id` uses `ON DELETE SET NULL`; read path treats `carer_kind = 'shared_user' AND carer_user_id IS NULL` as **"carer removed"**, never blank/crash.

---

## D-AWAY-004 — A `note_only` carer never implies access (2026-09-15)

**Status:** Frozen

`note_only` is name + note only. No `pet_access`, share link, notification, or app access.

| Kind | Display |
|------|---------|
| `shared_user` | `Sarah · Shared access` |
| `note_only` | `Tom · Neighbour · No AgathaTrack access` |

No inline "invite" affordance on `note_only` assignment.

---

## D-AWAY-005 — `shared_user` carer + `carer-candidates` endpoint (2026-09-15)

**Status:** Frozen

`carer_user_id` must reference a user with `pet_access` on **that pet** in `PET_ACCESS_ROLES` (`carer`, `co_parent`). Validate at write time; `403` otherwise. `foster` excluded.

**Do not** relax `GET /api/pets/:id/access` (`userOwnsPet` guard).

**Add** `GET /api/pets/:id/carer-candidates` scoped to `userCanManagePet`, so collaborators who can declare an absence can assign carers. Response shape is minimal:

```json
[{ "user_id": "…", "display_name": "Sarah M." }]
```

No email, photo, bio, or category. Exposes collaborator user ids only for pets the caller already manages — intentional, bounded widening.

---

## D-AWAY-006 — Collapsed routine rows inherit least-certain constituent (2026-09-15)

**Status:** Frozen (grouping key superseded — certainty rule unchanged)

When N daily occurrences collapse to one routine row, certainty = **minimum** among constituents. Any `conditional_on_future_completion` → collapsed row shows `~` and expected copy. Implemented **server-side** beside the projector; plan page and PDF render only.

**Amended 2026-09-22 by [D-AWD-002](/docs/domains/pet_care/changes/away-plan-detail-v2-decisions.md#d-awd-002--care-events-are-grouped-by-health-entry-not-by-time-slot-across-all-frequencies-supersedes-d-away-006s-grouping-key):** the grouping key changes from `health_entry_id + scheduled_time` (daily-only) to `health_entry_id` alone, extended to every repeating frequency. The **least-certain-wins** rule on this page stays exactly as written — it now applies to the wider grouping, not to a new one.

---

## D-AWAY-007 — Indeterminate care is visible, not merely flagged (2026-09-15)

**Status:** Frozen

`projectEntryForPeriod` may return **no items** for `from_completion` entries with pending occurrences while recording `uncertainties[]`. Plan page and PDF must render enriched uncertainties as **named rows**, not omit care silently. Requires AW-3 enrichment (`name`, `type`, `care_family` on each uncertainty).

**Extended 2026-09-22 by [D-AWD-003](/docs/domains/pet_care/changes/away-plan-detail-v2-decisions.md#d-awd-003--completion-chain-indeterminate-items-get-an-interval-description-not-just-a-reason-code-extends-d-away-007):** named rows now also carry a recurrence interval when the underlying entry has one (`recurring_chain` kind, D-AWD-002), instead of only a reason code. Still not omitted silently; still enriched with `name`/`type`/`care_family`.

---

## D-AWAY-008 — Handover note is verbatim and terminates there (2026-09-15)

**Status:** Frozen

Free-text handover note goes to PDF **verbatim**. Never parsed, never fed to CIM, never promoted to structured pet facts. Boundary **asserted in a test**, not only comments.

---

## D-AWAY-009 — "Changed since download" ships in two parts (2026-09-15)

**Status:** Frozen

**Part 1 (AW-9):** Handover download/print works. Record `last_handover_downloaded_at` on the absence (one additive column). **Surface nothing** — no "changed" notice, no comparison logic.

**Part 2 (deferred, own ticket):** Real change detection when CSM ledger makes a projection fingerprint cheap. **Rejected:** crude `updated_at`-only comparison — cannot honestly detect carer writes, note edits, or schedule changes.

Seed may include downloaded-then-edited absences because the timestamp column exists; Part 2 adds the notice only.

---

## D-AWAY-010 — Saving never requires a complete plan (2026-09-15)

**Status:** Frozen

Dates + pets is a valid save. Carer, handover note, and download are optional. No completion percentage, checklist mechanic, or gate.

---

## D-AWAY-011 — §3.8 forward-compat column dropped; document `explainGap` instead (2026-09-15)

**Status:** Frozen

**Removed from scope:** adding a `source_ref`-style pointer from projection calls to absences.

**Reason:** `explainGap` already exists (`server/lib/care/schedule/explainGap.js`, CSM-13). It is keyed by `health_entry_id` + optional date window and returns ledger facts — no absence pointer. `planned_absences.source_ref` already means "what external thing declared this absence"; overloading it would corrupt a live field.

**Ships instead:** documented `explainGap` window contract in [care-context.md](../features/care-context.md). Reverse lookup (which absence overlapped a schedule event) is answerable from `planned_absences` by `(user_id, date window)` with no new column.

---

## D-AWAY-012 — "Care team" → carers; vets → "Veterinary team" (2026-09-15)

**Status:** Frozen

Rename vet surfaces before any carer UI (AW-1). `terminology.md` already defines **care team** as collective carers.

| Surface | EN after | FR after |
|---------|----------|----------|
| Vet section / detail | Veterinary team | Équipe vétérinaire |
| Carer concept (Away Planning) | Care team | Équipe de soins |

`org_context_collection_filter.dart` personal-scope chip gets a **new key** (`collectionFilterPersonal` / "Personal" / "Personnel") — **not** `myVets`. Amend pet-profile D34 when the dashboard gains a fourth section (AW-6).

AW-1 must update BDD scenario title, `@bdd` header, Playwright spec, and three page objects **in lockstep** (exact title match gate).

---

## D-AWAY-013 — `publicError` argument-order footgun (2026-09-15)

**Status:** Frozen (debt tracking)

`publicError(err, prodMessage, devMessage)` returns a string. Calling `publicError(res, err, msg)` passes `res` as `err` and sends no response — hung socket (live defect fixed in AW-EMERGENCY).

**Repo-wide grep (2026-09-15):** exactly two occurrences, both in `careContext` read routers — fixed in AW-EMERGENCY.

**Debt (P2):** add `sendPublicError(res, err, msg)` wrapper or ESLint rule banning `publicError(res` — see [debt.md](/docs/debt/debt.md).

---

## D-AWAY-014a — Per-pet handover PDF content & privacy (2026-09-22)

**Status:** Frozen

Per-pet handover PDF includes trip context (dates, all pet **names**), absence `handover_note` (trip-wide section), this pet's carer row only in "Who's caring", this pet's schedule and `pet_note`, and per-pet (not absence-wide) coverage summaries. Other pets' carer identities are not disclosed.

Spec: [away-planning-per-pet-handover-spec.md](./away-planning-per-pet-handover-spec.md).

---

## D-AWAY-014b — Download timestamp is full-plan only (2026-09-22)

**Status:** Frozen

`last_handover_downloaded_at` is updated only by the full-plan handover download (`AwayPlanHandoverController.downloadHandover`). Per-pet export does not bump it. D-AWAY-009 Part 2 change detection, when it ships, applies to full-plan download semantics only.

---

## Related

- [away-planning-delivery-plan.md](./away-planning-delivery-plan.md)
- [away-planning-per-pet-handover-spec.md](./away-planning-per-pet-handover-spec.md) — AW-11 implementation
- [away-plan-detail-v2-decisions.md](./away-plan-detail-v2-decisions.md) — amends D-AWAY-002/006, extends D-AWAY-007; rebased onto AW-11
- [care-schedule-management-decisions.md](./care-schedule-management-decisions.md) — D-CSM-008 (no reschedule on plan page)
- [terminology.md](/docs/design/terminology.md)

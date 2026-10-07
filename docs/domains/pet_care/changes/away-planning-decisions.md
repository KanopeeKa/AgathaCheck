---
title: Away Planning — Decision log
owner: Product / Agent
audience: both
status: active
last_updated: 2026-09-22
tags: [pet_care, care_context, decisions]
---

# Away Planning — Decision log

Frozen product and engineering decisions for **Away Planning V1**. **Care Context** (projection, coverage, readiness presentation, planned-care list, `explainGap`, absence invariants): canonical [care-context.md](../features/care-context.md) decision log — D-AWAY-001, D-AWAY-002, D-AWAY-006, D-AWAY-007, D-AWAY-010, D-AWAY-011, D-AWD-*, D-CC-ABS-001, D-CC-SCOPE-001. **This file** retains carer, handover, terminology, and debt rows for Wave 1.3b. Delivery sequencing: [away-planning-delivery-plan.md](./away-planning-delivery-plan.md).

**Context:** AgathaTrack is **not in production**; no real user data exists. Verified against `main` through `fcc8a804` (2026-09-15). Care Schedule Management V1 merged in [#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193).

**Confirmed 2026-09-15** after plan review ([#1196](https://github.com/KanopeeKa/AgathaCheck/pull/1196)). All decisions below are **Frozen**.

---

## D-AWAY-001 — Away Planning does not introduce a second "status" (2026-09-15)

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-001).

---

## D-AWAY-002 — Readiness is two facts, not one verdict (2026-09-15)

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-002, D-AWD-001 amendment). Dashboard tile fixed-priority copy remains as implemented in `AwayPlanningTileCopy`.

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

Per-pet, not per-care-item. "Luna → Sarah, Milo → Tom" is in scope.

**Amendment (2026-09-27, agreed, effective with Care Item evolution Phase E):** per **absence**, each **affected care item** may have an **absence resolution** (decision, optional looked-after-by, optional note). That is not a permanent carer on the care item and not Pet Sitting rostering. Canonical behaviour: [care-item-evolution.md](../features/care-item-evolution.md) § Absences. The pet-level carer on `planned_absence_pets` remains the suggested "who" for resolutions.

**Historical (2026-09-15):** per-item assignment was listed as Pet Sitting and out of scope; that sentence applied before absence resolutions.

**Planned amendment (agreed, not in effect):** when People phase 2 ships, the model allows a primary carer plus backup carers and date ranges, and carers become directory contacts. Until then, this decision stands as written. See [amends-away-planning.md](/docs/domains/people/changes/amends-away-planning.md).

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

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-006, D-AWD-002 grouping).

---

## D-AWAY-007 — Indeterminate care is visible, not merely flagged (2026-09-15)

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-007, D-AWD-003). Open-occurrence display amendments: [away-care-planning-decisions.md](./away-care-planning-decisions.md) (D-ACP-001).

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

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-010 → CARE-CONTEXT-R-022).

---

## D-AWAY-011 — §3.8 forward-compat column dropped; document `explainGap` instead (2026-09-15)

**Retired here** — canonical row in [care-context.md](../features/care-context.md#decision-log) (D-AWAY-011 → CARE-CONTEXT-R-014).

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
- [care-context.md](../features/care-context.md) — D-AWD-* and context D-AWAY rows (Wave 1.3a consolidate)
- [care-schedule-management-decisions.md](./care-schedule-management-decisions.md) — D-CSM-008 (no reschedule on plan page)
- [terminology.md](/docs/design/terminology.md)

---
title: Away Planning — Decision log
owner: Product / Agent
audience: both
status: draft
last_updated: 2026-09-15
tags: [pet_care, care_context, decisions]
---

# Away Planning — Decision log

Product and engineering decisions for **Away Planning V1**, the hub / plan-page / carer / handover tranche of `care_context`. Canonical behaviour lives in [care-context.md](../features/care-context.md). Delivery sequencing: [away-planning-delivery-plan.md](./away-planning-delivery-plan.md).

**Every decision below is `Proposed`, not `Frozen`.** They are the open questions surfaced by verifying the Away Planning V1 brief against `main` at `11fc85b3`. Nothing in the delivery plan may start until the decisions it depends on are marked `Frozen` by a human.

**Context:** AgathaTrack is **not in production**; no real user data exists. Care Schedule Management V1 (CSM) merged to `main` in [#1193](https://github.com/KanopeeKa/AgathaCheck/pull/1193), which changes several premises the brief was written against.

---

## D-AWAY-001 — Away Planning does not introduce a second "status" (2026-09-15)

**Status:** Proposed

"Recorded" / "Prepared" / "ready" is a **read-time derived value**, never a column. `planned_absences.status` keeps exactly two meanings: `active` and `cancelled`.

The derived value is computed server-side (not in Flutter) so that the plan page, the dashboard tile, and the PDF cannot disagree.

---

## D-AWAY-002 — Readiness composes carer presence with coverage; it does not re-implement coverage (2026-09-15)

**Status:** Proposed

Readiness is a **pair**, surfaced as two independent facts rather than one collapsed score:

| Fact | Source |
|------|--------|
| Is someone looking after each pet? | `planned_absence_pets.carer_kind` presence per pet |
| Can we make a claim about the care in the window? | `evaluateCarePeriodCoverage()` — `coverage_state` + `reassurance_available` |

`CarePeriodCoveragePolicy` (`server/lib/care/carePeriodCoverage.js`) stays the single implementation of the second fact. Away Planning adds **no new coverage vocabulary**.

**Open problem this decision must resolve before freezing:** `reassurance_available` is `true` for four of five coverage states, including `nothing_scheduled`. It is a "may we speak?" flag, not a "covered" flag. Reassurance copy therefore keys off `coverage_state`, and `nothing_scheduled` must **not** render as "Everything looks covered for these dates" — for a pet with no tracked care that sentence claims coverage of nothing.

---

## D-AWAY-003 — Carer is per pet per absence, on the existing join table (2026-09-15)

**Status:** Proposed

```text
planned_absence_pets (additions)
  carer_kind      TEXT   NULL   -- 'shared_user' | 'note_only' | NULL (unset)
  carer_user_id   UUID   NULL   -- FK users(id) ON DELETE SET NULL
  carer_name      TEXT   NULL   -- note_only only
  carer_note      TEXT   NULL   -- note_only only
```

Per-pet, not per-care-item. "Luna → Sarah, Milo → Tom" is in scope; "medication → Sarah, grooming → Jane" is Pet Sitting and is out of scope.

**Constraints to encode in the migration:**

- `CHECK (carer_kind IN ('shared_user','note_only'))` when not null — `planned_absences` currently has **no** CHECK on `status` or `provenance`, so this is a deliberate tightening, not a house style.
- `CHECK` that `carer_kind = 'shared_user'` implies `carer_user_id IS NOT NULL` and `carer_name IS NULL`, and `carer_kind = 'note_only'` implies `carer_name IS NOT NULL` and `carer_user_id IS NULL`.
- `carer_user_id` uses `ON DELETE SET NULL` **plus** a partial index, and the read path must treat `carer_kind = 'shared_user' AND carer_user_id IS NULL` as "carer removed" rather than crashing.

---

## D-AWAY-004 — A `note_only` carer never implies access (2026-09-15)

**Status:** Proposed

A `note_only` carer is a name and a note. It grants nothing: no `pet_access` row, no share link, no notification, no read path into the app.

Display must distinguish the two kinds at every surface — plan page, pet Care Team display, PDF:

| Kind | Display |
|------|---------|
| `shared_user` | `Sarah · Shared access` |
| `note_only` | `Tom · Neighbour · No AgathaTrack access` |

Assigning a `note_only` carer must never offer an "invite" affordance inline; that is a `pet_access` action with its own authorization path.

---

## D-AWAY-005 — A `shared_user` carer must already hold access to that pet (2026-09-15)

**Status:** Proposed

`carer_user_id` must reference a user with a `pet_access` row for that specific pet in `COLLABORATOR_ROLES` (`shared`, `guardian`). Validation is per pet, at write time, and rejects with `403` otherwise. Selecting a carer must not be a way to discover or address users.

**Open problem this decision must resolve before freezing:** the only endpoint that lists collaborators, `GET /api/pets/:id/access` (`server/routes/pets/accessRouter.js`), is guarded by `userOwnsPet`. But `userCanManagePet` — the guard on absence writes — also admits collaborators. So a *collaborator* can declare an absence for a pet whose collaborator list they cannot read, and the carer picker would be empty for them. One of three must be chosen:

1. Restrict carer assignment to pet **owners** (simplest; a collaborator-declarer sees a disabled picker with an explanation).
2. Add a narrow `GET /api/pets/:id/carer-candidates` scoped to `userCanManagePet`, returning display name only (no email, no user id enumeration beyond that pet's existing collaborators).
3. Relax the `/access` guard — **rejected**: it widens an authorization boundary for a convenience.

Option 1 is recommended for V1; option 2 is the follow-up if the restriction proves wrong in UAT.

---

## D-AWAY-006 — Collapsed routine rows inherit the least-certain constituent (2026-09-15)

**Status:** Proposed

When the plan page collapses N daily occurrences into one routine row, that row's certainty is the **minimum** certainty among what it collapses:

```text
any constituent certainty == conditional_on_future_completion
  => collapsed row renders as conditional ("~", "Expected based on the current schedule")
```

Collapsing must never upgrade certainty. The collapse function is **server-side**, beside the projector, so the plan page and the PDF cannot diverge.

---

## D-AWAY-007 — Indeterminate care must be visible, not merely flagged (2026-09-15)

**Status:** Proposed

`projectEntryForPeriod` returns **no items** for a `from_completion` entry that has any pending occurrence; it records the fact in `uncertainties[]` and returns early (`server/lib/care/schedule/projectSchedule.js`). A pending occurrence *before* the window therefore produces an entry that contributes zero in-window items while raising `projection_status: partially_indeterminate`.

Consequence: a plan page or PDF rendered from `items` alone **silently omits care that is likely to happen while the guardian is away**. For a document whose entire purpose is handover, that is the worst available failure.

Away Planning therefore renders `uncertainties[]` as first-class rows ("Worming — we can't predict the date yet; it depends on the next dose"), in the UI and in the PDF.

**Blocking dependency:** `uncertainties[]` carries only `{ health_entry_id, reason }` — no name, no `care_family`. It must be enriched (additively) before the plan page can name an uncertain item. See AW-3 in the delivery plan.

---

## D-AWAY-008 — The handover note is verbatim and terminates there (2026-09-15)

**Status:** Proposed

The free-text handover note is carried to the PDF **verbatim**. It is never parsed, never fed to Care Intelligence, never promoted into structured pet facts, and never used to derive care. This boundary is asserted in a test, not only in a comment, so a later CIM tranche cannot quietly cross it.

---

## D-AWAY-009 — "Changed since download" is a comparison, not a snapshot system (2026-09-15)

**Status:** Proposed

Record the last download as a timestamp per absence. Surface the notice when the absence's `updated_at` is later than that timestamp. No document versioning, no stored PDF, no diff.

**Open problem this decision must resolve before freezing:** `updated_at` on `planned_absences` is bumped only by `PATCH /:id` and `/cancel`. A carer or handover-note change on `planned_absence_pets` does not touch it, and neither does a *schedule* change — yet a rescheduled vaccination is exactly the kind of change a carer needs to know about. V1 must pick a scope and say so in copy:

1. Absence-shape changes only (dates, pets, carers, note) — achievable by bumping `planned_absences.updated_at` from carer writes too. Copy: "Your plan details have changed since the last download."
2. Absence shape **and** projected care — requires comparing a cheap projection fingerprint at read time. Copy can then honestly say "Your care plan has changed".

Option 1 is recommended for V1. Option 2 is where CSM's ledger makes it cheap later, and it is the honest version of the brief's wording.

---

## D-AWAY-010 — Saving an absence never requires a complete plan (2026-09-15)

**Status:** Proposed

Dates + pets is a valid, savable absence. Carer, handover note, and download are all optional and always reachable later from the plan page. No gate, no required-field wall, no completion percentage, no checklist mechanic anywhere in this feature.

---

## D-AWAY-011 — The forward-compatibility hook is a reverse index, not a new column (2026-09-15)

**Status:** Proposed

The brief (§3.8) asks for a `source_ref`-style pointer from the projection call back to the absence, on the assumption that CSM's `explainGap` does not exist yet. **It does** — `server/lib/care/schedule/explainGap.js` merged with CSM V1, keyed by `health_entry_id` with an optional date window.

The useful hook is therefore the opposite direction from the brief's: given a schedule event, which absence was in effect? That is answerable today from `planned_absences` by `(user_id, date window)` with no new column. `planned_absences.source_ref` already exists and means "what external thing declared this absence" — overloading it to mean "what projection asked about it" would corrupt a live field.

V1 ships: a documented, tested query helper (`absencesOverlapping(pool, userId, fromIso, toIso)`) and the `explainGap` window contract written down in [care-context.md](../features/care-context.md). No schema change. See §G of the delivery plan for why the brief's version is rejected.

---

## D-AWAY-012 — "Care team" is freed for carers; vets become "Veterinary team" (2026-09-15)

**Status:** Proposed

`docs/design/terminology.md` already defines **care team** as "collective carers for one pet", while the Pet Care dashboard uses "Care team" as the label for **vet clinics**. Away Planning surfaces real carers, so the collision becomes user-visible and must be resolved first, in its own PR.

| Surface | EN before | EN after | FR after |
|---------|-----------|----------|----------|
| Vet section / detail | Care team | Veterinary team | Équipe vétérinaire |
| Carer concept (Away Planning) | — | Care team | Équipe de soins |

**Open problem this decision must resolve before freezing:** the rename is not a value swap. `l.myVets` ("Care team") is also the label of the **personal-scope filter chip** in `lib/core/widgets/collection_filter/org_context_collection_filter.dart`, where it sits beside `l.all` and per-organisation choices. Relabelling that chip "Veterinary team" is wrong — it distinguishes *personal vs organisation*, not *vets vs carers*. That call site needs its own key (for example `collectionFilterPersonal` → "Personal" / "Personnel") as part of the rename PR.

---

## Related

- [away-planning-delivery-plan.md](./away-planning-delivery-plan.md) — phase sequencing
- [care-context.md](../features/care-context.md) — canonical Care Context behaviour
- [care-schedule-management-decisions.md](./care-schedule-management-decisions.md) — D-CSM-001, D-CSM-002, D-CSM-008
- [terminology.md](/docs/design/terminology.md) — `care team` glossary entry

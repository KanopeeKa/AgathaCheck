---
title: Away Planning — Carer model
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: away_planning_carer
status: active
last_updated: 2026-10-07
---

# Away Planning — Carer model

**Product programme:** Care Through Change · **Capability:** per-pet carer assignment, handover notes and PDF export for planned absences.

## Summary / scope

- **Owns:** `planned_absence_pets` carer columns (`carer_kind`, `carer_user_id`, `carer_name`, `carer_note`, `pet_note`); carer write validation and `GET /api/pets/:id/carer-candidates`; carer coverage fact on readiness; Who's caring UI; full-plan and per-pet handover PDF client pipeline; `last_handover_downloaded_at` on full-plan download only.
- **Does not own:** absence dates, pets join, projection, coverage policy, or plan list presentation ([care-context.md](./care-context.md)); per-item absence resolutions ([care-item-evolution.md](./care-item-evolution.md)); People directory, guest access, or absence-scoped invites ([people-care-team.md](../../people/features/people-care-team.md)).
- **Depends on:** existing `pet_access` for `shared_user` carers; care-context save rules (dates + pets sufficient; carers optional — CARE-CONTEXT-R-022).

User-facing collective label: **care team** (EN) / **équipe de soins** (FR) per [terminology.md](/docs/design/terminology.md). Vet surfaces use **Veterinary team** / **Équipe vétérinaire** (D-AWAY-012).

## Vocabulary

| Term | Meaning |
|------|---------|
| Carer (per pet) | One assignment row on `planned_absence_pets` for a given absence + pet |
| `shared_user` | Collaborator who already has `pet_access` (`carer` or `co_parent`); assignment does not grant access |
| `note_only` | Name + optional `carer_note` about the person; no app access, share link, or notification |
| `pet_note` | Free text about caring for this pet (any `carer_kind`); distinct from `carer_note` and absence `handover_note` |
| `handover_note` | Whole-trip notes on `planned_absences` (Care Context field); rendered verbatim in PDFs |
| Carer coverage | Readiness fact: `none_have_carers`, `some_have_carers`, or `all_have_carers` (paired with care coverage in Care Context) |

## Storage

```text
planned_absence_pets
  planned_absence_id   UUID   FK planned_absences(id)
  pet_id               UUID   FK pets(id)
  carer_kind           TEXT   NULL   -- 'shared_user' | 'note_only' | NULL (unset)
  carer_user_id        UUID   NULL   FK users(id) ON DELETE SET NULL
  carer_name           TEXT   NULL   -- note_only only
  carer_note           TEXT   NULL   -- note_only only, about the person
  pet_note             TEXT   NULL   -- migration 071; any carer_kind, about the pet
```

Constraints (migration `063`): `shared_user` requires `carer_user_id` and forbids `carer_name` / `carer_note`; `note_only` requires `carer_name` and forbids `carer_user_id`. `pet_note` is orthogonal — no `carer_kind` dependency.

Absence-level `handover_note` and `last_handover_downloaded_at` live on `planned_absences` (migrations `064` / AW-9).

## Carer kinds

| Kind | Write fields | Display (EN) | Access |
|------|--------------|--------------|--------|
| Unset | — | No carer assigned | — |
| `shared_user` | `carer_user_id` | `{name} · Shared access` | Existing `pet_access` only |
| `note_only` | `carer_name`, optional `carer_note` | `{name} · No AgathaTrack access` | None — no inline invite |
| Removed collaborator | `shared_user` with null `carer_user_id` | Carer removed | Read path never blank/crash |

## Requirements

| ID | Rule | Status |
|----|------|--------|
| AWAY-PLANNING-CARER-R-001 | One carer per pet per absence on `planned_absence_pets`; not per care item; pet-level carer is the suggested who for item resolutions (D-AWAY-003) | Live |
| AWAY-PLANNING-CARER-R-002 | `note_only` is name + note only; never implies `pet_access`, share link, notification, or app access; no inline invite on assignment (D-AWAY-004) | Live |
| AWAY-PLANNING-CARER-R-003 | `shared_user`: `carer_user_id` must be a `carer-candidates` user for that pet (`carer` or `co_parent`; `foster` excluded); invalid → `403`; do not relax `GET /api/pets/:id/access` (`userOwnsPet`) (D-AWAY-005) | Live |
| AWAY-PLANNING-CARER-R-004 | `GET /api/pets/:id/carer-candidates` scoped to `userCanManagePet`; minimal `[{ user_id, display_name }]` only (D-AWAY-005) | Live |
| AWAY-PLANNING-CARER-R-005 | `PATCH` accepts `pet_carers[]`; each `pet_id` on the absence; carer writes bump `planned_absences.updated_at` | Live |
| AWAY-PLANNING-CARER-R-006 | `carer_kind` and `pet_note` are independent per entry — each field written only when its key is present; `pet_note: null` clears without carer change (AW-11) | Live |
| AWAY-PLANNING-CARER-R-007 | `handover_note` and `pet_note` stored and rendered verbatim; never parsed, promoted to structured facts, or fed to CIM; boundary asserted in tests (D-AWAY-008) | Live |
| AWAY-PLANNING-CARER-R-008 | Full-plan handover download records `last_handover_downloaded_at`; no changed-since-download UI in V1 (D-AWAY-009 Part 1); honest change detection deferred (Part 2) | Live |
| AWAY-PLANNING-CARER-R-009 | Per-pet handover PDF: trip dates and all pet names for context; trip-wide `handover_note`; this pet's carer row only in Who's caring; this pet's schedule and `pet_note`; pet-scoped coverage summaries; other pets' carer identities not disclosed (D-AWAY-014a → AWAY-PLANNING-CARER-D-014) | Live |
| AWAY-PLANNING-CARER-R-010 | Per-pet export does not update `last_handover_downloaded_at`; Part 2 change detection applies to full-plan download only (D-AWAY-014b → AWAY-PLANNING-CARER-D-015) | Live |
| AWAY-PLANNING-CARER-R-011 | Carer coverage fact at read time: `none_have_carers`, `some_have_carers`, `all_have_carers`; `shared_user` with null `carer_user_id` counts as unset; dashboard tile prioritises carer gap first (with care-context readiness) | Live |
| AWAY-PLANNING-CARER-R-012 | Plan page Who's caring section: per-pet label; edit dialog for carer + `pet_note`; per-pet PDF download independent of carer kind | Live |
| AWAY-PLANNING-CARER-R-013 | Vet surfaces renamed to Veterinary team before carer UI; personal-scope collection filter uses `collectionFilterPersonal` not `myVets` (D-AWAY-012) | Live |
| AWAY-PLANNING-CARER-R-014 | People phase 2: primary + backup carers, directory contacts, optional date ranges within absence; `carer_coverage` gains `unavailable`; migration rules in [people-care-team.md](../../people/features/people-care-team.md) § Away Planning integration | Planned |
| AWAY-PLANNING-CARER-R-015 | People phase 2+: carer as contact; `shared_user`-like behaviour when linked account has `pet_access`; absence-scoped app access via explicit invite (unchanged principle: assignment never grants access) | Planned |

## API summary

| Endpoint | Role |
|----------|------|
| `PATCH /api/planned-absences/:id` | `pet_carers[]` carer + `pet_note` patches |
| `GET /api/pets/:id/carer-candidates` | Assignable collaborators for one pet |
| `GET /api/planned-absences/:id/readiness` | `carer_coverage` + `care_coverage` + `tile_copy` |
| `POST /api/planned-absences/:id/record-handover-download` | Sets `last_handover_downloaded_at` (full plan) |

Wire details: [api-reference.md](/docs/architecture/api-reference.md).

## UI surfaces

| Surface | Behaviour |
|---------|-----------|
| Plan page (`/pc/away/:id`) | Who's caring — per-pet carer label; dialog for carer + `pet_note`; per-pet PDF button |
| Create (`/pc/away/new`) | Carers optional on save; navigates to plan after save |
| Dashboard tile | Carer-gap priority via readiness `tile_copy` (Care Context owns tile states) |

Implementation detail for per-pet PDF sections: [away-planning-per-pet-handover-spec.md](../changes/away-planning-per-pet-handover-spec.md) (shipped AW-11).

## Out of scope (V1)

Per-care-item permanent carer assignment (Pet Sitting). Public share links from `note_only`. Inline invite from `note_only`. Mandatory carers before save. OS print dialog (`Printing.layoutPdf`) — reuse share/download path. Per-pet download change tracking.

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| APC-1 — When PATCH assigns shared_user then updated_at bumps and carer returned | AWAY-PLANNING-CARER-R-003, AWAY-PLANNING-CARER-R-005 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH assigns shared_user carer and bumps updated_at |
| APC-2 — When PATCH assigns note_only then No access fields implied | AWAY-PLANNING-CARER-R-002 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH assigns note_only carer without access implication |
| APC-3 — When shared_user not a candidate then 403 | AWAY-PLANNING-CARER-R-003 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH returns 403 when shared_user is not a carer candidate |
| APC-4 — When pet_note-only PATCH then Carer columns untouched | AWAY-PLANNING-CARER-R-006 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH with pet_note only updates pet_note and leaves carer untouched |
| APC-5 — When carer-only PATCH then pet_note preserved | AWAY-PLANNING-CARER-R-006 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH with carer_kind only updates carer and leaves pet_note untouched |
| APC-6 — When pet_note cleared with null then Carer unchanged | AWAY-PLANNING-CARER-R-006 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH pet_note: null clears the note without touching carer |
| APC-7 — When pet_note set then Stored verbatim on wire | AWAY-PLANNING-CARER-R-007 | test: server/test/careContext/plannedAbsenceCarers.test.js#PATCH pet_note is stored and returned verbatim (D-AWAY-008) |
| APC-8 — When shared_user user deleted then carer_removed on read | AWAY-PLANNING-CARER-R-011 | test: server/test/careContext/plannedAbsenceCarers.test.js#GET absence marks shared_user with null user_id as carer_removed |
| APC-9 — When carer-candidates for manageable pet then Minimal list | AWAY-PLANNING-CARER-R-004 | test: server/test/pets/carerCandidates.test.js#returns minimal collaborator list for manageable pets |
| APC-10 — When readiness matrix then carer_coverage states match | AWAY-PLANNING-CARER-R-011 | test: server/test/careContext/awayPlanReadiness.test.js |
| APC-11 — When record-handover-download then Timestamp set | AWAY-PLANNING-CARER-R-008 | test: server/test/careContext/plannedAbsenceHandover.test.js#POST record-handover-download sets last_handover_downloaded_at |
| APC-12 — When handover note in PDF helper then Verbatim bytes | AWAY-PLANNING-CARER-R-007 | test: flutter_app/test/features/pet_care/context/away_plan_handover_service_test.dart#handover note is passed to PDF verbatim (D-AWAY-008) |
| APC-13 — When per-pet PDF generated then pet_note and trip note sections | AWAY-PLANNING-CARER-R-009 | test: flutter_app/test/features/pet_care/context/away_plan_handover_service_test.dart#pet note is passed to PDF verbatim (D-AWAY-008) |
| APC-14 — When plan page opened then Who's caring visible | AWAY-PLANNING-CARER-R-012 | bdd: away_planning.feature#Away plan page shows who is caring for each pet |
| APC-15 — When shared carer assigned in UI then Name on plan row | AWAY-PLANNING-CARER-R-012 | none — #1770 |
| APC-16 — When contact carer assigned in UI then Name on plan row | AWAY-PLANNING-CARER-R-012 | none — #1770 |
| APC-17 — When handover downloaded then Emergency contacts and vets listed | AWAY-PLANNING-CARER-R-009 | none — #1770 |

Coverage gaps: [#1770](https://github.com/KanopeeKa/AgathaCheck/issues/1770) (shared/contact carer E2E, handover emergency contacts and vets on PDF).

## Still open

- D-AWAY-009 Part 2: projection-fingerprint change detection for full-plan handover.
- D-AWAY-013: `sendPublicError` wrapper or ESLint ban on `publicError(res` — see [debt.md](/docs/debt/debt.md).
- D-AWAY-012 residual copy migrations outside Away surfaces.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| D-AWAY-003 | Carer per pet per absence on join table | Distinct from per-item resolutions; ON DELETE SET NULL → carer removed | Live | 2026-09-15 | AW-4 |
| D-AWAY-004 | `note_only` never implies access | PDF is the channel for note-only carers until People invite | Live | 2026-09-15 | AW-4 |
| D-AWAY-005 | `shared_user` + `carer-candidates` endpoint | Validate `pet_access`; bounded id exposure for managers | Live | 2026-09-15 | AW-4 |
| D-AWAY-008 | Handover notes verbatim | No parsing or CIM promotion; tests for `handover_note` and `pet_note` | Live | 2026-09-15 | AW-9 |
| D-AWAY-009 | Changed-since-download in two parts | Part 1 timestamp only; Part 2 needs honest fingerprint | Live | 2026-09-15 | AW-9 |
| D-AWAY-012 | Care team vs Veterinary team labels | Rename vets before carer UI; BDD/E2E lockstep | Live | 2026-09-15 | AW-1 |
| D-AWAY-013 | `publicError` argument-order footgun | Fixed in AW-EMERGENCY; repo wrapper deferred | Live | 2026-09-15 | AW-EMERGENCY |
| AWAY-PLANNING-CARER-D-014 | Per-pet handover PDF content and privacy | Former D-AWAY-014a; one pet's carer in Who's caring | Live | 2026-09-22 | #1266 |
| AWAY-PLANNING-CARER-D-015 | Download timestamp full-plan only | Former D-AWAY-014b | Live | 2026-09-22 | #1266 |
| AWAY-PLANNING-CARER-D-016 | People phase 2 amends D-AWAY-002/003/005 presentation | Primary+backup model, `unavailable` carer fact, contact-backed carers; UI one carer until later | Live | 2026-10-08 | documentation-migration |

## Related

| Kind | Link |
|------|------|
| Absence facts and plan presentation | [care-context.md](./care-context.md) |
| Care Item absence resolutions | [care-item-evolution.md](./care-item-evolution.md) |
| People Care Team spec | [people-care-team.md](../../people/features/people-care-team.md) |
| AW-11 implementation spec | [away-planning-per-pet-handover-spec.md](../changes/away-planning-per-pet-handover-spec.md) |
| Delivery sequencing (historical) | [away-planning-delivery-plan.md](../changes/away-planning-delivery-plan.md) |
| API | [api-reference.md](/docs/architecture/api-reference.md) |

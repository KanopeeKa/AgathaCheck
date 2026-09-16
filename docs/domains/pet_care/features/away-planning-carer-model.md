---
title: Away Planning — Carer model
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_context
status: active
related_prs: []
related_bdd: [away_planning.feature]
---

# Away Planning — Carer model

Per-pet carer assignment for planned absences. Canonical product behaviour: [care-context.md](./care-context.md). Frozen decisions: [away-planning-decisions.md](../changes/away-planning-decisions.md) (D-AWAY-003 through D-AWAY-005).

## Scope

- **In scope:** one carer per pet per absence; `shared_user` (collaborator with existing pet access) or `note_only` (name + note, no access).
- **Out of scope:** per-care-item assignment, Pet Sitting workflows, public share links, inline invite from `note_only`.

User-facing label: **care team** (EN) / **équipe de soins** (FR) per [terminology.md](/docs/design/terminology.md).

## Storage

Carer facts live on the existing join table — not a separate carers table:

```text
planned_absence_pets
  planned_absence_id   UUID   FK planned_absences(id)
  pet_id               UUID   FK pets(id)
  carer_kind           TEXT   NULL   -- 'shared_user' | 'note_only' | NULL (unset)
  carer_user_id        UUID   NULL   FK users(id) ON DELETE SET NULL
  carer_name           TEXT   NULL   -- note_only only
  carer_note           TEXT   NULL   -- note_only only
```

Constraints (migration `063`):

- `carer_kind` ∈ {`shared_user`, `note_only`, NULL}.
- `shared_user` requires `carer_user_id`; forbids `carer_name` / `carer_note`.
- `note_only` requires `carer_name`; forbids `carer_user_id`.

## Carer kinds

| Kind | Write fields | Display (EN) | Access |
|------|--------------|--------------|--------|
| Unset | — | No carer assigned | — |
| `shared_user` | `carer_user_id` | `{name} · Shared access` | Existing `pet_access` only — assignment does not grant access |
| `note_only` | `carer_name`, optional `carer_note` | `{name} · No AgathaTrack access` | None — no share link, notification, or app access |
| Removed collaborator | `carer_kind = shared_user`, `carer_user_id` null | Carer removed | Read path treats deleted user as removed, never blank |

## Write validation

- `PATCH /api/planned-absences/:id` accepts `pet_carers: [{ pet_id, carer_kind, … }]`.
- Each `pet_id` must already be on the absence.
- `shared_user`: `carer_user_id` must reference a user with `pet_access` on **that pet** in `COLLABORATOR_ROLES` (`shared`, `guardian`). `foster` excluded. Returns `403` when invalid.
- Carer writes bump `planned_absences.updated_at`.
- Dates + pets alone are a valid save — carers are optional (D-AWAY-010).

## Carer candidates

`GET /api/pets/:id/carer-candidates` — scoped to `userCanManagePet` (same as absence declaration).

```json
[{ "user_id": "…", "display_name": "Sarah M." }]
```

Minimal response: no email, photo, or bio. Does not change `GET /api/pets/:id/access` (`userOwnsPet` guard unchanged).

## Readiness — carer coverage fact

Server derives carer coverage at read time (D-AWAY-002). Never a stored status column.

| `carer_coverage.state` | Meaning |
|------------------------|---------|
| `none_have_carers` | No pet has a carer |
| `some_have_carers` | At least one, not all |
| `all_have_carers` | Every pet on the absence has a carer |

Returned on `GET /api/planned-absences/:id/readiness` with `care_coverage` and `tile_copy`. Dashboard tile uses fixed actionability priority: carer gap first, else coverage sentence.

## UI surfaces

| Surface | Behaviour |
|---------|-----------|
| Dashboard tile | Stateful when an upcoming absence exists; degrades to prompt on load error |
| Hub (`/pc/away`) | Lists upcoming/past absences; FAB to `/pc/away/new` |
| Plan page (`/pc/away/:id`) | "Who's caring" section — per-pet carer label from `pet_carers` |
| Wizard (`/pc/away/new`) | Dates → pets → preview; save navigates to plan page |

## Related

- [api-reference.md](/docs/architecture/api-reference.md) — planned absences, carer-candidates, readiness
- [away-planning-delivery-plan.md](../changes/away-planning-delivery-plan.md)
- [away-planning-decisions.md](../changes/away-planning-decisions.md)

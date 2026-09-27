---
title: People — planned amendments to Away Planning decisions
owner: Product / Documentation
audience: both
status: accepted
last_updated: 2026-09-27
tags: [people, pet_care, away-planning, decisions]
---

# People — planned amendments to Away Planning decisions

**Status:** agreed on 2026-09-27. **Not in effect yet.** The frozen decisions in [away-planning-decisions.md](/docs/domains/pet_care/changes/away-planning-decisions.md) stay authoritative until the People phase named below ships. Canonical spec: [people-care-team.md](/docs/domains/people/features/people-care-team.md).

## Summary

| Frozen decision | Planned change | In effect from |
|-----------------|----------------|----------------|
| D-AWAY-002: readiness is two derived facts | **Extended, not replaced.** The per-pet carer fact gains an `unavailable` value, and the absence-level `carer_coverage` counts it as uncovered. There is still no stored status or single verdict (spec D18) | People phase 2 |
| D-AWAY-003: one carer per pet per absence | **Amended.** The model allows a primary carer, optional backup or additional carers, and optional date ranges within the absence. The v1 UI still shows one carer per pet | People phase 2 (model); UI later |
| D-AWAY-004: a `note_only` carer never implies access | **Unchanged in principle.** Assigning a carer never grants access. App access for an absence is a separate, explicit invite (spec D19, D8) | Phase 4, for the invite |
| D-AWAY-005: `shared_user` carers must already have `pet_access` | **Generalised.** A carer is a contact. A contact whose linked account already has access to the pet behaves like today's `shared_user` | People phase 2 |
| Per-pet handover (D-AWAY-014a): the PDF is the channel for carers without app access | **Unchanged until phase 4.** A contact with no linked account behaves exactly like today's `note_only`, so the PDF is its only channel (spec D28). The PDF gains emergency contacts, vets and documents attached to the absence | Phase 2 (content); phase 4 (invite) |

## Migrating existing carer rows

These rules apply when phase 2 ships:

- **`note_only` rows.** Each distinct `carer_name`, with its `carer_note` if there is one, becomes a contact. It goes in the personal directory of the person who created the absence. `carer_note` becomes that contact's private note, and the absence row points to the contact. Two rows with the same name and the same creator become one contact. No attempt is made to merge beyond that (spec: contact dedupe is out of scope for v1).
- **`shared_user` rows.** A contact linked to `carer_user_id` is created or reused in the creator's personal directory.
- **Rows marked removed** (`shared_user` with a null `carer_user_id`) are shown as "carer no longer available". They are not migrated to a contact.
- **`pet_note` and `handover_note` are untouched.** They describe the pet and the trip, not the person.
- Historical absences keep a name snapshot, so past plans still read correctly.

## Terminology

The Away Planning UI keeps **care team / équipe de soins** for the carers on an absence, as `terminology.md` defines it. The People page never uses that term. See [vocabulary.md](/docs/domains/people/features/vocabulary.md).

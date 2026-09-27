---
title: People domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-27
tags: [domain, people, households]
---

# People

A unified People directory, households, and absence-scoped carer access. The functional spec was agreed on 2026-09-27. **Nothing is implemented yet.**

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| Functional spec (decisions D1–D28) | [features/people-care-team.md](features/people-care-team.md) |
| Vocabulary (EN/FR) | [features/vocabulary.md](features/vocabulary.md) |
| Planned amendments to Away Planning | [changes/amends-away-planning.md](changes/amends-away-planning.md) |

## Domains this changes

| Domain | What changes |
|--------|--------------|
| [Sharing](/docs/domains/sharing/README.md) | Household membership becomes a new source of access. User-facing access labels change (wire values don't). Household Full access can't share long-term. The owner and co-parents still can (D26) |
| [Pet Care — Away Planning](/docs/domains/pet_care/features/away-planning-carer-model.md) | Carers are picked from the directory, replacing `note_only`. Access can be granted for an absence. D-AWAY-003 is amended |
| [Vets](/docs/domains/vet/README.md) | `vets` migrates into contacts (identity plus a primary-vet relationship) |
| [Notifications](/docs/domains/notifications/README.md) | Reminders go to the named person, or to the owner and Full access members (D21, D25). Adds an "all events" setting |
| [Auth](/docs/domains/auth/README.md) | Account deletion is guarded for pets other people rely on. GDPR export is extended. The account gets a timezone (D24) and an 18+ attestation (D14) |

## Code map (current code the spec builds on)

| Concern | Path |
|---------|------|
| Pet access roles | `server/lib/petAccess.js`, `server/routes/sharing/` |
| Vets | `server/routes/vets.js` |
| Absence carers | `server/routes/careContext/plannedAbsencesRouter.js` |
| Occurrence completion | `server/routes/healthEntries/completionRouter.js` |
| Account deletion and export | `server/routes/auth/profileRouter.js`, `server/lib/gdprUserExport.js` |

---
title: Health tracking specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-08
tags: [domain,health_tracking,specs]
domain: health_tracking
feature_id: health-tracking
---

# Health tracking

Medication and treatment entries, health issues, completion semantics, and reminders (`health_tracking.feature`, `health.tracking.spec.ts`).

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| **HT-1** | Pet carers manage health entries (one-time and recurring) with dosage, schedule, and notes. | delivered |
| **HT-2** | Due/overdue entries surface on Pet Care dashboard and `/pc/events` (D17). | delivered |
| **HT-3** | Completion uses occurrence model and CSM APIs — not legacy entry-only `mark-taken` advance. | delivered |
| **HT-4** | Health issues are separate CRUD from entries (`healthIssues.js`). | delivered |
| **HT-5** | Pet carers manage health issues on `/pet/:petId/health-issues` with expandable cards, documents (max 4), linked events, and open/resolved dates. | Live |
| **HT-6** | Collapsed list cards show title, up to five description lines, date, and document icon without duplicating the full description in the header when expanded. | Live |
| **HT-7** | Health Issues list uses Pet Care collection canvas and actionable empty state. | Live |
| **HT-8** | Collapsed rows may show open/resolved status at a glance (product change from initial W13 wireframe). | Planned |

## User journeys

### Add health entry

Pet carers create entries with name, dosage, frequency/recurrence, and optional notes. One-time and recurring series are supported.

### Mark taken / complete

For due entries, guardians confirm completion (optional completion date). Recurring series advance via occurrence completion; one-time entries close on `completed_on`.

### View due and overdue

Due and overdue items appear on the Pet Care dashboard Care Actions section and the due-events list (`/pc/events`).

### Edit and delete

Entries can be updated or removed; undo reverts the latest closed occurrence and restores due/completed state per CSM rules.

### Health issues

Separate health-issue records track conditions linked to pets (BDD `health_tracking` scenarios).

## Care scheduling and completion

**Canonical:** [Care Schedule Management](/docs/domains/pet_care/features/care-schedule-management.md) owns occurrence timing, commands, and history reads (D-CSM-019 … D-CSM-035).

**Care Item UX** (status words, agenda, completion flows): [care-item-evolution.md](/docs/domains/pet_care/features/care-item-evolution.md) (D-CIE-024 … D-CIE-034).

### Retired (pre-occurrence model)

| Topic | Status |
|-------|--------|
| Entry-level `mark-taken` advancing `nextDueDate` without occurrences | **Retired** — use occurrence `complete` APIs |
| `health_history` as authoritative complete/skip log | **Retired** (D-CSM-003, D-CSM-035) |
| `GET /:id/history` reading `health_history` only | **Retired** — closed occurrences (D-CSM-035) |
| Three-date model lesson in `.agents/memory/health-entry-completion.md` | **Retired** — rules moved to CSM canonical doc |

## Health issues

Managed via `server/routes/healthIssues.js` with separate CRUD from entries.

Dedicated UI: `PetHealthIssuesScreen`, entry from pet profile **Health & history** row. Initial collapsed layout follows W13 (`docs/domains/pet_profile/changes/guardian-ui-wave2-issue-briefs.md` §W13); HT-8 defers visible status on collapsed rows until product approves.

### Decision log

| ID | Decision | Status |
|----|----------|--------|
| **HT-D-001** | Expanded card shows title in body (W13); description appears only in expanded body, not duplicated in the collapsed header. | Live |
| **HT-D-002** | User-facing errors on health-issue and care-entry document surfaces do not include raw exception text. | Live |
| **HT-D-003** | Document strip delete controls use a shared ≥48dp overlay (`HealthDocumentStripDeleteButton`). | Live |
| **HT-D-004** | Max attachment snackbar for health issues uses health-issue-specific copy (not “per event”). | Live |
| **HT-D-005** | Collapsed visible status pill — pending; see HT-8. | Planned |

## Org family events alignment

Org family events use `from_date` = due, `to_date` = completed on; `family_event_history` stores the three-date audit trail (see fostering/organization domains).

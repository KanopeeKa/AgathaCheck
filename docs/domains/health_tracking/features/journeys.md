---
title: Health tracking journeys
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,health_tracking,journeys]
domain: health_tracking
---

# Health tracking journeys

User-facing flows for medication, treatments, and health issues (`health_tracking.feature`).

## Add health entry

Pet carers create entries with name, dosage, frequency/recurrence, and optional notes. One-time and recurring series are supported.

## Mark taken / complete

For due entries, guardians confirm completion (optional completion date). Recurring series advance `next_due_date`; one-time entries set `completed_on`.

## View due and overdue

Due and overdue items appear on the Pet Care dashboard Due section and dedicated due-events list (`/pc/events` per experience program D17).

## Edit and delete

Entries can be updated or removed; undo reverts the latest history row and restores due/completed state.

## Health issues

Separate health-issue records track conditions linked to pets (see BDD health_tracking scenarios).

---

**Specs:** [specs.md](specs.md)

---
title: Away plan scope simplify — Decision log
owner: Product / Agent
audience: both
status: frozen
last_updated: 2026-09-26
tags: [pet_care, care_context, away_planning, decisions]
---

# Away plan scope simplify — Decision log (D-ACP-011)

**Status:** Frozen (2026-09-26). Product confirmed in chat; PDF uses strict parity with the on-screen list.

## D-ACP-011 — Away plan lists in-window care only; pre-departure overdue is attention-only

**Supersedes:** R-A1 breadth (pre-window open occurrences while `today < S`).

### Inclusion (`planned_care_items[]` after filter)

1. Rows with `in_window` set (scheduled, planned, or estimated dates in `[S, E]`).
2. When `today >= S`, still-open work with `open_occurrence.scheduled_date < S` (stale before departure).
3. Exclude: pre-window overdue or due-before-`S` while `today < S`.
4. Exclude: `indeterminate_pending` rows with no `in_window` (no “waiting on prior dose” noise).

### Pre-departure attention (per pet)

While `today < S`, wire `pre_absence_overdue_attention: { show, overdue_count }` when any row has `open_occurrence.open_status === overdue`. UI: link to pet profile — no overdue rows on the plan.

### Moves

- No **Plan this** on the away plan.
- In-window rows with `schedule_flexibility` ∈ `{ flexible, earlier_only }` show **See options** → care event detail; reschedule logic stays on the event screen.
- Inline Care Planner suggestions removed from the away plan; carer task count may still show.

### PDF

Handover uses the same filtered `planned_care_items[]` as the screen (strict parity).

### Estimates

In-window estimates remain read-time projection; completing or rescheduling on the care event must refresh coverage/plan providers (existing invalidation).

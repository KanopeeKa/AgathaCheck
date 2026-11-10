---
title: All care by care item — delivery plan
owner: Product / Documentation
audience: both
status: in-delivery
status_since: 2026-11-10
folds_into: docs/domains/pet_care/features/care-item-evolution.md
plan: all-care-by-item-c455
last_updated: 2026-11-10
---

# All care by care item — delivery plan

Execute-plan: [all-care-by-item-c455](/.agents/plans/all-care-by-item-c455.md). Integration branch: `cursor/all-care-by-item-c455-integration-c455`.

## Goal

One **All care** screen at `/pc/events` where each care item is a multi-line card grouped into **Today**, **Upcoming**, **Paused care**, and **Closed care**, with multi-select pet chips in the address bar and deep links from the pet profile. Bottom nav **Care** (FR **Soins**); screen title **All care** on the global queue.

## Phases (summary)

| Phase | Outcome |
|-------|---------|
| 1 | Pet chips + `?pet=`; Paused / Closed collapsible sections on global list; canonical **Planned** rows |
| 2 | Pet profile redirect to `/pc/events?pet=`; rename nav; filter cleanup |
| 3 | API `completionsToday` on list reads |
| 4 | Multi-line care cards; skeleton; E2E on `/pc/events` |
| 5 | Dashboard + pet profile cards; Care tab badge |

## Phase 1 — shipped scope

- Visible multi-select **pet chips** on `/pc/events` when the shell has more than one pet.
- `?pet=` query param (comma-separated ids) synced with chip and collection-filter pet selection.
- **Paused care** and **Closed care** collapsible section shells on the global list (legacy row presentation; agenda unchanged).

## Phase 2 — shipped scope (this PR)

- `/pet/:petId/events` redirects to `/pc/events?pet=`; legacy `care-rhythms` follows the same destination.
- Pet profile **View all care** opens global All care with the pet chip and `returnTo` back to the profile.
- Bottom nav **Care** (EN); global screen title **All care** (`careNavLabel`, `allCare`).
- Global filter panel drops pet, status, and show-skipped dimensions (pet chips + section model replace them).

## Proof on UAT (programme)

Sign in as a pet carer with due care → **Care** tab → multi-line cards under **Today** (phase 4+); expand **Paused care**; pet profile **View all care** with correct chip (phase 2+).

---
title: People UI hub — navigation & desk decisions
owner: Product / Experience
audience: both
domain: people
status: active
last_updated: 2026-09-28
related_plan: people-ui-hub-a58d
---

# People UI hub — navigation & desk decisions

**Approved:** 2026-09-28 (execute-plan `people-ui-hub-a58d`, control issue #1373).

## Summary

People becomes a **first-class Guardian destination** with a unified **desk module** on Today. This supersedes prior wording that People would not appear on the compact bottom bar and that the Pet Care dashboard would keep a standalone **My Vets** section.

## Bottom navigation (Option A — locked)

| Slot | Route | Label (EN nav) |
|------|-------|----------------|
| 1 | `/pc/home` | Today |
| 2 | `/pc/pets` | Pets |
| 3 | `/pc/events` | Care |
| 4 | `/pc/people` | People |
| 5 | `/account` | Account |

**Always five destinations** on the compact `BottomNavigationBar` at every viewport width. Do **not** drop a tab on narrow phones. If labels crowd, reduce padding, icon size, and `selectedFontSize` / `unselectedFontSize` — never remove a slot.

**Selection:** `/pc/people`, legacy `/account/people`, and People detail routes highlight the People tab (same pattern as Pets + `/pet/*`).

**Redirects:** `/account/people` → `/pc/people` (permanent in router).

## Desktop (≥840px)

Add **People** to the Pet Care navigation rail and expanded sidebar with the same route and vocabulary label.

## Today dashboard — single People module

Replace `PetCareMyVetsSection` with one module eyebrow **People** (vocabulary), header link **See all** → `/pc/people`.

| Sub-block | Content | Limit |
|-----------|---------|-------|
| Pet professionals | Rank by linked pet count (desc); ties: primary vet on any pet, then name | 2 |
| Trusted carers | Rank: upcoming absence carer first, else most pets linked, else name | 2 |
| Household rail | Horizontal chips: first name + avatar/initials per household member | scroll + overflow |

Sub-block labels use [vocabulary.md](../features/vocabulary.md) — not “Vet team” or Away-plan “care team”.

**Deprecation:** `/pc/vets` redirects to `/pc/people` with professionals filter (one release minimum).

## Amended sources

| Document | Change |
|----------|--------|
| [people-care-team.md § UI](../features/people-care-team.md) | Bottom tab + desk module allowed |
| [guardian-dashboard-brief.md](/docs/domains/pet_profile/features/guardian-dashboard-brief.md) | My Vets section → People module (historical table row superseded) |
| [phase-1-navigation.md](/docs/domains/navigation/changes/phase-1-navigation.md) | Fifth primary destination documented |

## Out of scope (follow-up plans)

- Person/org detail tabs, filter sheet, desktop table (mockup board phases 2–4)
- Pet profile “People around {pet}” inline section

## Verification

- Flutter widget tests for nav index and five visible bar items
- Playwright: open People from bottom nav; desk module sections smoke
- BDD `people.feature` wired to Playwright when stable

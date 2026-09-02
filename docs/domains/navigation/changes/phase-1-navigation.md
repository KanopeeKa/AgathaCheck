---
title: Phase 1 — Shell & navigation reversal
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 1 — Shell & navigation reversal

**Parent:** [roadmap-delivery-plan.md](../../cross-domain/changes/roadmap-delivery-plan.md) · [program-contract.md](../../cross-domain/changes/program-contract.md)  
**Brief:** [navigation-brief.md](../features/navigation-brief.md), [guardian-dashboard-brief.md](/docs/domains/pet_profile/features/guardian-dashboard-brief.md) §Notifications

## Purpose

Reverse Navigation v2 and ship the brief's section-switcher drawer + global bell + Account area,
end to end, before any dashboard content changes.

## In scope

- Drawer rework: Pet Care / Shelter (top, always both, mode-independent) + Account
  (bottom-pinned)
- Header rework: hamburger (dashboard roots) / back arrow (sub-screens), persistent bell, no Home
  button
- Bell + unified notification slide-over (program-contract §3.2)
- New `/account` route and Account dashboard
- Retirement of `/pc/notifications`, `/o/notifications`, and the two per-mode Settings screens
  (content redistributed per the Phase 0.1 audit)
- `@legacy`-tag and replace the one superseded scenario in `experience_navigation.feature`;
  extend `notifications.feature` with new scenarios (program-contract §6.1)

## Out of scope / forbidden ownership

- Pet Care/Organisation dashboard **content** (Phase 2/3) — Phase 1 only needs each dashboard
  route to exist and render *something* correct today (even the old mixed feed temporarily) behind
  the new chrome; content rework is a separate phase so this phase's diff stays reviewable
- Org-scoped settings destination screens themselves (Phase 3/5) — Phase 1 only needs to route
  correctly to wherever the audit says they now live, even if that destination is a stub
- Must not touch `server/routes/organizations/**` business logic — this is a Flutter-shell phase

## Depends on

Phase 0 (dashboard-section widget not required here, but the notification kind/priority/resolvedAt
schema is — this phase is where they're first surfaced in UI).

## Exposes to

Phase 2/3 build their dashboard content inside the routes this phase establishes
(`/pc/home`, `/o/orgs`, `/account`).

## Domain objects and states

No new domain objects — this phase is UI/routing + the notification panel UI over Phase 0's
schema.

## Business rules

1. Drawer content is **identical regardless of current mode** — always exactly: Pet Care item,
   Organisation item, separator, Account item (bottom-pinned, visually separated). No
   asymmetric per-mode variants (reverses nav-v2's `guardianEntries()` / `organizationEntries()`
   split in `drawer_menu_config.dart`).
2. No drawer item routes to Events, Vets, or either legacy Settings screen (D3).
3. Header shows hamburger **only** on the three section-root screens
   (`/pc/home`, `/o/orgs`, `/account`); every other authenticated screen shows a back arrow
   instead. If ambiguity is possible (e.g. a screen reachable both as a root and as a pushed
   sub-screen), the leading control always reflects *how the user arrived*, not a static
   per-route table — verify this against `go_router`'s navigation stack, not just the route path.
4. Bell is visible in the header on every authenticated screen (dashboards and sub-screens alike)
   — it's a persistent global utility, not a per-screen decision.
5. Bell badge = single combined unread count across `care` + `administrative` kinds (D8) — never
   a dual badge.
6. Notification slide-over opens as a full-height right panel (reuse the existing drawer's
   slide animation primitive for visual consistency, per the brief's "should visually relate to
   the hamburger drawer").
7. Kind filter chips (`All`, `Care`, `Organisation`) sit above the existing date-grouped list;
   selecting a chip filters in place, no navigation/route change.
8. Administrative notifications referencing an open object show an "Action needed" affordance
   until `resolvedAt` is set (D9) — resolved automatically when the underlying object transitions,
   never by a manual "mark resolved" tap from the recipient.
9. `/account` is reachable from the drawer's bottom-pinned item. **Superseded (transitional):** D-v4-2 also allows `/account` from the Pet Care compact bottom bar until the drawer is retired.
10. Sign out lives inside `/account`, not as a separate global drawer row (matches the brief
    exactly — reverses nothing here since nav-v2 already had sign out in a utility block, just
    relocates it into Account specifically).

## Screens and navigation

| Route | Role |
|---|---|
| `/account` | New — Account dashboard root |
| `/notifications` | New — unified inbox, reachable only via bell |
| `/pc/home` | Existing route, same path, new chrome only in this phase (content in Phase 2) |
| `/o/orgs` | Existing route, same path, new chrome only in this phase (content in Phase 3) |
| `/pc/notifications`, `/o/notifications` | **Removed** |
| `/g/settings`, `/o/settings` | **Removed** — content redistributed per Phase 0.1 audit |
| `/pc/events`, `/pc/vets`, `/o/events`, `/o/vets` | Kept as routes (still needed by Phase 2/3
  full-screen destinations) but **removed from the drawer** — reachable only from dashboard
  preview "All X" links |

## Notifications

This phase implements the **UI and read-side** of program-contract §3 (panel, chips, badge,
resolved-state rendering). It does **not** need every possible administrative notification type
to exist yet — Phase 2/4 wire the emission call sites incrementally. Ship the panel able to render
whatever the schema already supports (today's `care` types, backfilled), then each later phase
adds its own emission without touching this phase's UI code again.

## Permissions

No permission changes in this phase — purely navigational.

## Audit events

None new.

## Phases with exit criteria

Sprints 1.1–1.6 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- No drawer item's route matches `/pc/events`, `/pc/vets`, `/o/events`, `/o/vets`, `/g/settings`,
  `/o/settings`, `/pc/notifications`, `/o/notifications`
- Bell + badge render on every authenticated screen (integration test asserts this, not just a
  spot check)
- `/account` renders all content items resolved by the Phase 0.1 audit
- `experience_navigation.feature`'s `@legacy` scenario replaced; `notifications.feature` extended
  with new scenarios; new Playwright specs green on `main`
- `/ui-design-deep` review completed and any findings addressed before merge
- `flutter-coverage` and BDD-coverage gates both pass at or above their current floors

## Migration / compatibility

No DB migration in this phase beyond what Phase 0 already added. This is a pure Flutter-side
rip-and-replace of the shell — expect a large, mechanical diff; keep it reviewable by sequencing
sprints 1.1→1.6 as separate PRs (stacked, per atomic-PR policy) rather than one giant PR.

## Legal/document dependencies

None.

## Open questions

- Program-contract Q1 (exact "Action needed" affordance styling) and Q3 (settings audit result)
  must both be resolved during this phase, not deferred.

## Canonical BDD scenarios

```gherkin
Feature: Section switcher drawer
  As an authenticated user
  I want the hamburger menu to show only Pet Care, Shelter, and Account
  So that I always have a simple, predictable way to switch sections

  Scenario: Drawer shows exactly three destinations regardless of current mode
    Given I am signed in as a guardian who is also a foster
    And I am on the Pet Care dashboard
    When I open the hamburger drawer
    Then I should see exactly "Pet Care", "Shelter", and "Account"
    And I should not see "Events" or "My vets" as drawer items

  Scenario: Bell shows a single combined unread count
    Given I have 2 unread care notifications and 1 unread administrative notification
    When I view any authenticated screen
    Then the bell badge should show "3"

  Scenario: Notification kind filter narrows the list without navigating
    Given I have both care and administrative notifications
    When I open the notification panel and tap the "Organisation" chip
    Then I should see only administrative notifications
    And my current screen should not change underneath the panel

  Scenario: Administrative notification with an open object shows Action needed
    Given a shelter has sent me a foster request
    When I open the notification panel
    Then the foster request notification should show an "Action needed" affordance
    When I respond to the foster request
    Then the notification should no longer show "Action needed"
```

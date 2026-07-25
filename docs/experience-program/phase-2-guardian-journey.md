# Phase 2 — Guardian journey

**Parent:** [`roadmap-delivery-plan.md`](roadmap-delivery-plan.md) · [`program-contract.md`](program-contract.md)  
**Brief:** [`briefs/guardian-dashboard-brief.md`](briefs/guardian-dashboard-brief.md)

## Purpose

Replace the mixed-feed Guardian dashboard with the brief's three symmetric preview sections, and
resolve the two concepts the brief's own vocabulary needed redefining for this codebase: "Event"
(D17) and "family events" → pet timeline (D18).

## In scope

- `/g/home` rebuilt as My Pets / Upcoming Pet Events / My Vets, using Phase 0's shared
  dashboard-section widget
- Pending-inbox → administrative-notification migration (D10)
- Pet card visual redesign (shared `pet_card.dart`, verified on all 3 existing call sites)
- `/g/events` reframed as a due-item list over health/weight/other entries (D17)
- Vet display-first detail screen (D24)
- Bulk share wrapper (D23)
- Pet timeline feature (D18) + `family_events` retirement (D19)

## Out of scope / forbidden ownership

- Organisation-side dashboard/pets screen changes (Phase 3) — this phase's pet-card and
  timeline work must not regress the **existing** org pets screen, but does not add org-specific
  tabs/filters (that's Phase 3's `pet_screen_filters.feature`)
- No new permission model — this phase uses only existing guardian-side ownership checks
- Must not delete `family_events`/`familyEventsRouter.js` until the data migration (2.7) is
  verified — sequence this last within the phase, not first

## Depends on

Phase 1 (shell + notification panel must exist so pending inboxes have somewhere to surface).
`docs/architecture/org-custody-model.md` (`custody_transfers` as the pet-timeline's guardian-segment
source).

## Exposes to

Phase 3's organisation pet screen reuses the same pet-card component and, where relevant, the same
timeline widget on the org-side pet detail screen.

## Domain objects and states

| Object | Change |
|---|---|
| `pet_timeline_entries` (new table) | `id, pet_id, entry_type ('manual'), title, description, start_date, end_date, created_by, created_at` — only manual entries are stored; custody and session segments are computed at read time from existing tables |
| `family_events` | Deprecated after 2.7's one-time migration; router removed |

## Business rules

1. Dashboard shows at most 4 pets (My Pets), 5 upcoming items (Upcoming Pet Events), and the full
   vet list in compact row form (My Vets is text-based, not card-based, no stated cap in the
   brief — keep it uncapped but scannable).
2. Pet card status bar colour: plum for guardian-owned, green for foster — reuse
   `ownership_accent.dart`, never colour-only (pair with the existing text/icon convention).
3. "Add an event" opens a type-picker (Health / Weight / Other) routing to the existing entry
   forms — it must not create a new generic "event" record type.
4. Pet timeline render order per pet, chronological: guardian custody segments (from
   `custody_transfers`) interleaved with fostering-session cards (from the J3 read model) and any
   manual entries, oldest first. A gap with no data of any kind renders the "No data" placeholder
   with a fill action (title/description/start/end) that creates a `pet_timeline_entries` row.
   Guardian name on a custody segment is shown **only** if the current viewer has permission to
   see that guardian's identity (reuse the existing pet-sharing/visibility rules — do not invent a
   new visibility check).
5. Pending share/foster-placement/adoption-placement/custody-transfer inboxes are removed from the
   dashboard **only after** their notification-emission replacement (program-contract §3.3) is
   verified working end-to-end — do this as the last sprint of this phase, not the first, so the
   dashboard never has a window with neither the old banner nor a working notification.
6. Bulk share: multi-select toggle on All Pets screen → existing single-share dialog fires once
   per selected pet — no new bulk backend endpoint (D23).

## Screens and navigation

| Route | Change |
|---|---|
| `/g/home` | Rebuilt: 3 sections |
| `/g/events` | Reframed: due health/weight/other items, "Add an event" sheet |
| `/g/vets` (list), new vet detail route | Display-first detail screen added; existing form screen becomes edit-only |
| Pet detail screen | + Pet timeline section |
| All Pets screen | + Bulk share entry point |

## Notifications

Emits the pending-inbox notification types listed in program-contract §3.1
(`pendingShareReceived`, `pendingFosterPlacementReceived`, `pendingAdoptionPlacementReceived`,
`pendingCustodyTransferReceived`) — all `administrative` kind, unresolved until the underlying
object transitions.

## Permissions

No new permission keys. Existing guardian-side ownership/sharing checks apply unchanged to the
pet timeline's guardian-name visibility rule (business rule 4).

## Audit events

`pet_timeline_entry_created` / `pet_timeline_entry_updated` (manual entries only) — new
`audit_events` `event_type` values, `resource_type = 'pet_timeline_entry'`.

## Phases with exit criteria

Sprints 2.1–2.8 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- Dashboard shows no full mixed feed (owned+shared+fostered+passed-away+due-events all in one
  `ListView`) — verified by removing `GuardianShellHomeContent`'s old body entirely, not just
  visually hiding it
- Pending-inbox notifications verified end-to-end (create a pending share in a test, confirm a
  notification appears, confirm it resolves on accept) before the old dashboard banners are removed
- Pet card redesign verified on guardian dashboard, org dashboard, and org pets screen (regression
  check, not just the new call site)
- `family_events` migration verified idempotent (Jest up/down + row-count assertion), then table
  and router removed in the same or an immediately following PR
- New/rewritten BDD: `guardian_dashboard.feature`, `pet_timeline.feature`; `organisation_pet_timeline.feature`'s `@legacy` scenarios removed

## Migration / compatibility

`family_events` → `pet_timeline_entries` one-time migration (2.7): copy any row not already
represented in `foster_placements` (migration `016` already handled the `placement`/`foster`
subset) into a manual timeline entry preserving `notes` → `description`, `from_date`/`to_date` →
`start_date`/`end_date`. Verify row counts before/after; keep the old table until a follow-up PR
confirms no read path still references it, then drop it.

## Legal/document dependencies

None.

## Open questions

- Exact cap/format for "My Vets" list length — brief doesn't state a cap; recommend uncapped with
  a scroll, confirm during `/ui-check`.

## Canonical BDD scenarios

```gherkin
Feature: Guardian dashboard
  As a guardian
  I want a dashboard that previews my pets, upcoming events, and vets
  So that I can act quickly without wading through a mixed feed

  Scenario: Dashboard shows exactly three sections
    Given I am signed in as a guardian with pets, due health entries, and vets
    When I view the Guardian dashboard
    Then I should see "My Pets", "Upcoming Pet Events", and "My Vets" sections only

  Scenario: My Pets preview is capped at four
    Given I have 6 pets
    When I view the Guardian dashboard
    Then I should see at most 4 pet cards
    And I should see an "All Pets" link

  Scenario: Pending foster placement surfaces as a notification, not a dashboard banner
    Given an organisation has sent me a pending foster placement
    When I view the Guardian dashboard
    Then I should not see a pending-placement banner on the dashboard
    And I should see an unresolved administrative notification in the bell panel

Feature: Pet timeline
  As a pet's guardian or an organisation admin
  I want to see a chronological timeline of the pet's custody and fostering history
  So that I understand its full journey without a separate family-events screen

  Scenario: Timeline shows a fostering session card
    Given "Max" had a fostering session with "Frank" from "2025-06-01" to "2025-08-31"
    When I view "Max"'s timeline
    Then I should see a fostering session card for "Frank" with those dates

  Scenario: Timeline shows a placeholder when no data exists for a period
    Given "Max" has no recorded custody, session, or manual entry for a period
    When I view "Max"'s timeline
    Then I should see a "No data" placeholder for that period
    And I should be able to fill it with a title, description, start date, and end date
```

---
title: Phase 3 — Organisation presentation & access control
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 3 — Organisation presentation & access control

> **Status: SUPERSEDED (2026-08-02).** Organisation v2 replaces the section-card dashboard IA with a
> single **profile composer** at `/o/orgs/:id`. See
> [`organisation-v2-delivery-plan.md`](organisation-v2-delivery-plan.md) and
> [`decisions-log.md`](decisions-log.md) (D-v2-IA-1). Kept as historical record for Phase 3 sprint
> planning; do not implement new work against this spec.

**Parent:** [`roadmap-delivery-plan.md`](roadmap-delivery-plan.md) · [`program-contract.md`](program-contract.md)  
**Brief:** [`briefs/shelter-dashboard-brief.md`](briefs/shelter-dashboard-brief.md)  
**Note:** Largest phase in the program. Default plan is single-agent sequential (D33); consider
`/spawn-sprint-agents` if the sprint list below proves too large for one sitting — sprints 3.3,
3.6, and 3.8 are the most independent of each other (disjoint files) and are the natural split
points if parallelism is chosen later.

## Purpose

Rebuild the top-level Organisation dashboard as My Organisations + Discover Organisations, and
decompose the single long `organization_detail_screen.dart` into the brief's modular section-card
architecture, backed by the role/permission model from program-contract §4 (explicitly TBD, D12).

## In scope

- `organizations` schema: discoverability fields, legal identifier fields (D20, D21, D28)
- `organization_permissions` table + `associate` role (D13, D14)
- `GET /organizations/discover` public endpoint + `OrgDiscoveryList` widget (D22)
- `organization_detail_screen.dart` decomposition into section cards
- Organisation Presentation screen (cover/logo hero, legal info, contact)
- Admin Contacts dedicated screen (directory + self-card + visibility prefs)
- Legal & Documents read-only slide-over
- Pet screen tabs and filters
- Permission audit events (D16)

## Out of scope / forbidden ownership

- Organisation Customisations screen itself (Phase 5) — this phase only needs the org **edit**
  screen to exist with a placeholder entry point into it
- Foster self-management visibility and the agreement-withdrawal flow (Phase 4) — Admin Contacts
  self-card ships in this phase; the **Foster** card's self-management ships in Phase 4, even
  though both reuse the same `notification_preferences` extension (build the shared
  extension here, consume it in both phases)
- Must not duplicate or fork any J1–J5 owned table (`org_foster_parents`, `foster_profiles`,
  `foster_placements`) — Fosters section reuses the existing Manage Fosters screen unchanged in
  this phase; only the entry-point card on the new org dashboard changes

## Depends on

Phase 1 (shell), Phase 0 (`hasPermission()` scaffolding). `/docs/domains/fostering/features/g0-contract-pack.md`
§7 (permission key catalog this phase's bundles are built from).

## Exposes to

Phase 4 consumes `hasPermission()` with the real `organization_permissions` table for foster/pet
action gates. Phase 5 consumes the same table for its admin UI.

## Domain objects and states

| Object | Change |
|---|---|
| `organizations` | + `town`, `administrative_area`, `description`, `is_discoverable`, `legal_identifier_1/2/3`, `public_profile_metadata` (program-contract §5) |
| `organization_users.role` | Narrows/extends to `associate \| foster \| admin \| super_admin` (D13) |
| `organization_permissions` (new) | Per program-contract §4.3 |
| Document templates (G1, existing) | + `is_public BOOLEAN DEFAULT false` flag — flagged templates surface in the new Legal & Documents slide-over |

## Business rules

1. `/o/orgs` shows My Organisations (existing `OrganizationListScreen` content, unchanged) plus a
   new Discover Organisations section beneath it — tiles with logo, name, town/administrative
   area, description snippet. Both sections coexist on one screen; Discover is not a separate
   route.
2. Discover Organisations data comes from the unauthenticated-safe endpoint even when the viewer
   is logged in — do not fork the query logic between authed/unauthed call sites.
3. `organization_detail_screen.dart` is replaced by a dashboard of section cards linking to:
   Organisation Presentation, Admin Contacts, Fosters (existing screen, unchanged route), Pets
   (existing screen + this phase's new tabs), Connected Organisations (existing, unchanged),
   Legal & Documents (new slide-over), and — Super Admin only — an "Edit organisation" entry
   leading toward Phase 5's Customisations screen (stub acceptable this phase).
4. Admin Contacts screen: self-card first (if viewer is an admin/associate with a contact card),
   remaining cards alphabetical by last name; Team-Admin permission required to add; Super-Admin
   permission required to edit/delete another person's card; every viewer can view, call, and
   in-app message per existing contact visibility rules.
5. Admin self-management (own card): phone visibility (`fosters \| admins \| all \| nobody`) and
   message-notification channel (`in-app \| email \| both`) — stored as an extension of the
   existing `notification_preferences` entity, scoped per organisation membership (program-contract
   §11/D31).
6. Legal & Documents slide-over shows only documents/templates flagged `is_public = true`; read
   and download only, grouped by type — never an edit affordance in this surface (guardrail from
   the brief, explicitly preserved).
7. Pet screen tabs: `Need attention` (computed: not in foster, OR in foster with placement ending
   within 10 days and no next session/adoption planned — query the J3 session read model, do not
   duplicate its state machine), `In foster`, `Adopted`, `All`. Filters: Name, Fostered by, Shadow,
   Rainbow bridge (passed away).
8. Effective permission for any gated action = role default (G0 §7) ∪ active
   `organization_permissions` rows for that user+org (program-contract §4.3) — every new gated
   action in this phase goes through `hasPermission()`, no inline role checks.
9. Every permission grant/revoke and role change in this phase's new Roles UI stub (full UI is
   Phase 5; this phase only needs the backend + audit wiring, not the admin screen itself) writes
   an `audit_events` row (D16).

## Screens and navigation

| Route | Change |
|---|---|
| `/o/orgs` | + Discover Organisations section |
| `/o/orgs/:id` | Rebuilt as section-card dashboard |
| `/o/orgs/:id/presentation` (new) | Organisation Presentation screen |
| `/o/orgs/:id/admin-contacts` (new) | Admin Contacts directory |
| `/o/orgs/:id/legal-documents` (new, slide-over) | Legal & Documents |
| `/o/orgs/:id/pets` (existing) | + tabs + filters |
| `/o/orgs/:id/edit` (existing form screen) | + entry point toward Phase 5's Customisations (stub) |

## Notifications

None new in this phase's core scope; Admin Contacts messaging reuses the existing in-app message
notification path unchanged.

## Permissions

New permission keys this phase introduces (program-contract §4.2): `manage_pets`,
`transfer_pet_ownership`, `manage_admin_contacts`, `manage_members`, `manage_permissions`.
Default grants: `manage_permissions` → `super_admin` only (D15); the rest follow the bundle-preset
table in program-contract §4.2 when applied, with `admin`/`super_admin` retaining their prior
G0-era default access unchanged so no existing admin loses capability on migration day.

## Audit events

`permission_granted`, `permission_revoked`, `role_changed`, `bundle_preset_applied`,
`admin_contact_visibility_changed` (program-contract §4.5).

## Phases with exit criteria

Sprints 3.1–3.10 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- `organization_detail_screen.dart` no longer exists as a single long page — verified by file
  removal, not by size reduction alone
- Discover Organisations returns real data via a Playwright request with **no** auth header
- Every new gated action has a Jest test asserting the correct outcome for all 4 wire roles, at
  least one bundle preset, and one individual override
- Existing admins retain all capability they had before migration (regression Jest suite against
  the pre-migration default-grant table)
- `/ui-design-deep` review completed for the new multi-screen organisation IA

## Migration / compatibility

`organization_users.role` migration must be preceded by a read-only audit query (program-contract
Q2) confirming the actual current distribution of role values before deciding whether `associate`
needs a backfill or whether every row already has an explicit role. Do not assume — verify.

## Legal/document dependencies

Legal identifier fields (RNA/SIREN/SIRET labels) are localisation-only (D28) — no new legal
document dependency; existing `regulatory/` docs are unaffected by this phase.

## Open questions

- Program-contract Q2 (role distribution audit) and Q4 (discover endpoint rate-limit tuning) —
  resolve at sprint 3.1 and 3.3 respectively, not before.

## Canonical BDD scenarios

```gherkin
Feature: Organisation discovery
  As any visitor, signed in or not
  I want to browse organisations that haven't opted out of discovery
  So that I can find a shelter to support or foster for

  Scenario: Discover Organisations is visible without signing in
    Given "Rescue Hearts" is discoverable
    When an anonymous visitor requests the organisations discovery list
    Then "Rescue Hearts" should appear with its name, logo, town, and description
    And no contact or legal details should be included

  Scenario: An organisation can opt out of discovery
    Given "Quiet Shelter" has opted out of discovery
    When an anonymous visitor requests the organisations discovery list
    Then "Quiet Shelter" should not appear

Feature: Organisation roles and permissions
  As a Super Admin
  I want to grant and revoke specific permissions
  So that I can delegate operational work without giving away full admin access

  Scenario: Super Admin applies the Pet Admin bundle preset
    Given "Alice" is an admin member of "Rescue Hearts"
    When the Super Admin applies the "Pet Admin" bundle preset to "Alice"
    Then "Alice" should be able to add a pet
    And an audit event "bundle_preset_applied" should be recorded

  Scenario: Only Super Admin can manage permissions
    Given "Bob" is a Foster Admin member of "Rescue Hearts"
    When "Bob" attempts to grant a permission to another member
    Then the action should be denied

Feature: Pet screen filters
  As an organisation member with pet visibility
  I want to filter pets by their care status
  So that I can quickly find pets that need attention

  Scenario: A pet with no foster placement needs attention
    Given "Max" has never been placed in foster care
    When I view the organisation Pets screen "Need attention" tab
    Then I should see "Max" with the explanation "Not in foster"

  Scenario: A pet with a foster placement ending soon needs attention
    Given "Bella" is in foster care ending in 5 days with no next session planned
    When I view the organisation Pets screen "Need attention" tab
    Then I should see "Bella" with the explanation "Foster finishing soon"
```

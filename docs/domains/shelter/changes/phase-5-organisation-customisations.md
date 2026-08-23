---
title: Phase 5 — Organisation customisations
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 5 — Organisation customisations

**Parent:** [`roadmap-delivery-plan.md`](roadmap-delivery-plan.md) · [`program-contract.md`](program-contract.md)  
**Brief:** [`briefs/shelter-dashboard-brief.md`](briefs/shelter-dashboard-brief.md) §Organisation customisations

## Purpose

Give Super Admins one place — reached from the organisation's edit screen — for everything that
is "customisation of an organisation": templates, roles/permissions administration, and change
visibility. Ships last because it depends on a stable operational core (Phases 1–4).

## In scope

- Organisation Customisations screen shell (Super Admin only, from org edit screen)
- Relocating existing J1/G1 template management (journey/document/agreement/email templates)
  under this new IA location
- Roles & Permissions admin UI: bundle preset picker, individual override grant/revoke, audit log
  viewer

## Out of scope / forbidden ownership

- Must not rebuild template storage or lifecycle — G1's existing template tables/routes are
  reused as-is; this phase only changes **where** the UI entry point lives
- Must not invent a new audit storage mechanism — reads from the existing `audit_events` table

## Depends on

Phase 3 (`organization_permissions` table, bundle presets, `manage_permissions` key).

## Exposes to

Nothing further downstream — this is the program's last phase.

## Domain objects and states

No new tables. UI-only relocation + a new audit-log read view over existing `audit_events`.

## Business rules

1. Organisation Customisations is reached **only** from the org's edit screen, **only** visible to
   Super Admins — never from the public organisation presentation or any directory screen (brief's
   explicit guardrail, preserved).
2. Template management screens (journey/document/agreement/email) move under this IA; their
   underlying routes/data are untouched — this is a navigation relocation, verified by confirming
   no route path for the actual template CRUD changes, only the screen(s) that link to them.
3. Roles & Permissions admin UI: selecting a bundle preset for a member writes the preset's
   permission-key set to `organization_permissions` with `source = 'bundle:<preset>'`; individual
   grant/revoke writes a single row with `source = 'individual'`. Both paths go through the same
   `manage_permissions`-gated endpoint.
4. Audit log viewer reads `audit_events` filtered to this organisation's `organization_id`,
   showing actor, action, resource, and timestamp — no raw metadata beyond what
   `docs/ops/observability.md` already permits logging (never health/foster PII payloads).
5. This screen is where the program's "freeze feature scope at sprint start, changes through
   change control" governance principle becomes visible to the people actually running an
   organisation — the audit log viewer doubles as their "who changed what" surface.

## Screens and navigation

| Route | Change |
|---|---|
| `/o/orgs/:id/edit` | + "Organisation customisations" entry point (Super Admin only) |
| `/o/orgs/:id/customisations` (new) | Shell screen: Templates, Roles & Permissions |
| `/o/orgs/:id/customisations/roles` (new) | Bundle preset picker, override grant/revoke, audit log viewer |

## Notifications

None new.

## Permissions

Uses only Phase 3's `manage_permissions` and `manage_document_templates` (already in G0 §7) — no
new keys.

## Audit events

No new event types — this phase **displays** the events Phases 3/4 already write.

## Phases with exit criteria

Sprints 5.1–5.4 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- A Super Admin can apply a bundle preset and see the affected member's effective permissions
  change immediately (Jest + one manual QA pass)
- Audit log viewer shows every grant/revoke/role-change/agreement-withdrawal event from Phases
  3–4 with correct actor and timestamp
- Template management screens are reachable from the new location; old entry points (if any
  existed outside the org edit flow) are removed, not duplicated

## Migration / compatibility

None beyond what Phase 3 already introduced.

## Legal/document dependencies

None beyond existing G1 template legal hooks, unchanged.

## Open questions

None outstanding at plan time — this phase's scope is a relocation + read view over already-locked
Phase 3 data structures.

## Canonical BDD scenarios

```gherkin
Feature: Organisation customisations
  As a Super Admin
  I want one place for templates and roles/permissions administration
  So that organisation configuration doesn't leak into public or directory screens

  Scenario: Only Super Admin sees the customisations entry point
    Given "Alice" is a Foster Admin member of "Rescue Hearts"
    And "Zara" is the Super Admin
    When "Alice" views the organisation edit screen
    Then "Alice" should not see an "Organisation customisations" entry point
    When "Zara" views the organisation edit screen
    Then "Zara" should see an "Organisation customisations" entry point

  Scenario: Audit log viewer shows a permission grant
    Given "Zara" applied the "Pet Admin" bundle preset to "Alice" yesterday
    When "Zara" opens the audit log viewer
    Then she should see a "bundle_preset_applied" entry for "Alice" with yesterday's timestamp
```

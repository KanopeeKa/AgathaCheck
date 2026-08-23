---
title: Phase 0 — Foundation
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Phase 0 — Foundation

**Parent:** [roadmap-delivery-plan.md](../../cross-domain/changes/roadmap-delivery-plan.md) · [program-contract.md](../../cross-domain/changes/program-contract.md)

## Purpose

Build the shared primitives every later phase depends on, with zero visible UI change, so Phase 1
onward is pure feature work rather than plumbing-plus-feature work.

## In scope

- `experience_settings_screen.dart` content audit (resolves program-contract Q3)
- Notification schema migration: `kind`, `priority`, `resolved_at` (program-contract §3.1)
- `NotificationKind` enum + type→kind default mapping (Flutter + Node)
- Shared "dashboard section" widget (title / optional header action / preview slot / end link)
- Permission-key helper scaffolding (`hasPermission()`, bundle preset constants) wired to
  **existing** G0 §7 defaults only — the `organization_permissions` table itself lands in Phase 3

## Out of scope / forbidden ownership

- No drawer, header, or bell UI (Phase 1)
- No dashboard content changes (Phase 2/3)
- No new permission override table or role migration (Phase 3) — Phase 0 only prepares the
  helper function signature so Phase 3 doesn't have to touch every call site twice
- Must not modify G0-owned tables (`foster_placements`, `org_foster_parents`, etc.)

## Depends on

Phase R (clean baseline). `docs/fostering-platform/g0-contract-pack.md` §7 (existing permission
key defaults) as the read model for the helper scaffolding.

## Exposes to

Every later phase consumes: `hasPermission()`, the dashboard-section widget, the notification
kind/priority/resolvedAt fields.

## Domain objects and states

| Object | Change |
|---|---|
| `AppNotification` (Flutter) | + `kind`, `priority`, `resolvedAt` |
| Notifications DB row | + `kind VARCHAR(16) NOT NULL DEFAULT 'care'`, `priority VARCHAR(8) NOT NULL DEFAULT 'normal'`, `resolved_at TIMESTAMPTZ` |

## Business rules

1. Existing notification rows backfill `kind = 'care'` on migration (safe default — every
   pre-existing notification type today is care-flavoured; see program-contract §3.1's type list).
2. The type→kind mapping table lives in one place (`NotificationKind` extension or a pure
   function) — no inline `if (type == ...)` branching scattered across UI code.
3. The dashboard-section widget takes `title`, `headerAction (optional)`, `previewBuilder`,
   `endLink` as parameters and owns no domain logic — pure presentation, reused verbatim by
   Phase 2 (My Pets / Upcoming Pet Events / My Vets) and Phase 3 (organisation section cards).
4. `hasPermission(role, org, key)` is the **only** sanctioned way to gate a UI action or backend
   route in any phase from here on — no direct `role === 'super_admin'` string comparisons in new
   code (existing call sites migrate incrementally in Phase 3/4, not required to convert in
   Phase 0).

## Screens and navigation

None new — the dashboard-section widget ships with a preview/demo usage in a widget test only,
not a real screen yet.

## Notifications

Schema-only change in this phase; no new notification is emitted yet (Phase 1 wires the UI, Phase
2/4 wire the emission call sites).

## Permissions

Helper scaffolding only, backed by existing defaults — no behaviour change for any existing role.

## Audit events

None new in this phase.

## Phases with exit criteria

Single phase, sprints 0.1–0.5 (see `roadmap-delivery-plan.md`).

**Exit criteria:**

- Migration has a Jest up/down test
- `NotificationKind` mapping has a unit test covering every existing `NotificationType` value
- Dashboard-section widget has a widget test with at least 2 distinct preview-content shapes
- `hasPermission()` has a unit test for every existing G0 §7 default grant
- Zero pixel/behaviour change on any existing screen (this is a pure-addition phase)

## Migration / compatibility

New nullable/defaulted columns only — no backfill risk beyond the `kind` default noted above.

## Legal/document dependencies

None.

## Open questions

- Program-contract Q3 (settings audit) is resolved **as** sprint 0.1's deliverable, not before —
  the audit itself is the answer.

## Canonical BDD scenarios

None — Phase 0 has no user-visible behaviour to specify in Gherkin. Widget/unit tests cover it.

---
title: Pet Care Today dashboard contract
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
# Pet Care Today dashboard contract

**Status:** Locked implementation handoff
**Parent:** [`phase-2-guardian-journey.md`](phase-2-guardian-journey.md)
**Master brief:** [`briefs/guardian-dashboard-brief.md`](briefs/guardian-dashboard-brief.md) (locked; do not edit)

This document is the executable contract for the Pet Care Today dashboard slice. It
clarifies how the approved dashboard direction fits the current AgathaTrack
application. It does not create a new domain model, provider, route, permission,
notification kind, or shell.

## Product boundary

`/pc/home` remains a Pet Care section landing page with exactly three management
domains:

1. **My Pets** (pet-rail section — not the workspace label)
2. **Care Actions** (eyebrow CARE ACTIONS; legacy label Due and Overdue)
3. **Care team** (user-facing; vet routes unchanged)

**Today** is a compact orientation and prioritisation layer above those three
domains. It is not a fourth section, a replacement route, or a second management
screen. It may summarise counts, urgency, and next actions, but every action
continues to the existing domain destination.

The dashboard is a preview surface. Full collections and management actions remain
behind the existing destination links and object routes.

## Stable data and authority boundaries

Downstream work must derive presentation from the existing authorities:

| Dashboard concern | Stable source/authority | Constraint |
|---|---|---|
| Owned, fostered, and shared pets | `PetListController` and `guardian_dashboard_helpers.dart` | Do not infer ownership or eligibility from visual state. |
| Pet card relationship/status | Existing `Pet` fields and `ownership_accent.dart` conventions | Plum/Pet Care and green/foster accents require text or icon support; never colour alone. |
| Due/overdue care items | `healthEntriesNotifierProvider`, `guardianDueEntries`, and existing health entry entities | “Events” means computed health, weight, and other care entries per D17; no generic event entity. |
| Completion and undo | Existing `HealthEntriesNotifier.markTaken` / `undoComplete` flow | The server remains authoritative; preserve the current optimistic preview and rollback/error semantics. |
| Veterinary contacts | `vetListProvider` and existing vet entities | Keep compact rows and existing display/detail destinations. |
| Global updates | Existing unified notification provider and header bell | Notifications remain global and outside the dashboard section list. |
| Section shell/navigation | `ExperienceShellScaffold` and drawer configuration | Keep Pet Care, Shelter, and Account as the top-level shell model. |

No new backend API, schema, event type, permission rule, notification system,
or local ownership heuristic is permitted in this dashboard branch.

## Presentation contract

### Pet preview

- Show at most **four pets** in the dashboard preview.
- Preserve owned, fostered, and shared relationship semantics from the existing
  helpers/controller.
- Use compact, bounded rectangular cards rather than an unbounded full collection.
- Target a photo region of approximately **96–112 px** on the dashboard card.
- Preserve a useful image placeholder and accessible name/status when no photo exists.
- Keep status visible through the existing ownership accent plus text or icon.
- The complete collection remains behind **All Pets / Manage pets** at `/pc/pets`.
- A pet card continues to open `/pet/:id`.

### Care preview

- Show at most **five** care items.
- Order items by existing due/overdue urgency and current server-provided ordering
  rules; do not invent a second event ordering model.
- Preserve the current mobile completion/undo interaction and server-authoritative
  state reconciliation.
- Loading, empty, and error are distinct states. An error must remain retryable and
  must not silently present as “nothing is due.”
- “Add an event” remains the existing type picker for Health, Weight, and Other,
  routing to existing forms. It must not create a generic event record.
- The full care collection remains `/pc/events`.

### Vet preview

- Use practical compact rows showing the existing vet identity, available locality,
  and linked-pet count.
- Keep the list uncapped unless a later decision explicitly changes the current
  contract; it must remain scannable and not become a dense admin table.
- Vet rows continue to open `/pc/vets/:id` in the existing flow.
- The full collection remains `/pc/vets`.

### Responsive and accessibility requirements

- Mobile-first hierarchy: Today orientation first, then the three management
  sections in the locked order.
- Preserve the existing wide/narrow desk behavior where it helps scanning, without
  creating a different information architecture on desktop.
- No horizontal overflow at 320 px.
- Interactive controls maintain at least 48×48 logical px touch targets.
- Keyboard focus, screen-reader section semantics, visible state changes, and
  large-text behavior must remain usable.
- Do not use colour as the only ownership, urgency, completion, error, or selected
  state signal.
- User-facing copy belongs in the existing localization system in the foundation
  task; this contract does not add localization files.

## Shell, notifications, and navigation

The existing shell remains unchanged:

- The drawer is the top-level section switcher for **Pet Care**, **Shelter**,
  and **Account**.
- The authenticated header keeps the hamburger on section roots, back navigation
  on sub-screens, and the persistent global notification bell.
- Notifications remain a unified cross-domain layer accessed from the bell.
- Pending share, foster-placement, adoption-placement, and custody-transfer
  items must not return as dashboard banners. Their administrative notification
  replacement is governed by D10 and must remain outside dashboard content.

### Deferred navigation decisions

This branch does **not** introduce a five-tab bottom bar, a universal Add action,
or a new Today route. A bottom bar would change shared Pet Care/Shelter shell
semantics, root/sub-screen header behavior, deep-link/back behavior, and future
native portability. A universal Add action would also need a cross-domain
destination and permission model rather than simply reusing the existing
care-event picker.

Those ideas can be reconsidered only after a separate product decision defines:

- the canonical tabs and their relationship to the existing drawer;
- root and sub-screen back/deep-link behavior;
- Pet Care/Shelter switching and Account placement;
- Add-action scope, object types, permissions, and notification effects; and
- mobile accessibility and native-portability requirements.

## Action and destination contract

| User action | Existing destination/behavior |
|---|---|
| Open a pet card | `/pet/:id` |
| Open the full pet collection | `/pc/pets` |
| Open a care item | Existing health-entry detail/workflow |
| Open all care items | `/pc/events` |
| Complete or undo a care item | Existing `markTaken` / `undoComplete` flow |
| Open a vet row | `/pc/vets/:id` |
| Open all vets | `/pc/vets` |
| Review global updates | Existing header notification bell/panel |
| Switch top-level experience | Existing Pet Care/Shelter/Account drawer |

Dashboard cards and Today summaries may improve discoverability, but must not
change these action meanings.

## File ownership and handoff

The next tasks should use this ownership boundary:

- **Presentation foundation:** pure selectors/derivations and localized copy only;
  no production shell or backend changes.
- **Today, pet, care, and vet slices:** isolated presentation components and
  focused tests; no reinterpretation of the authority boundaries above.
- **Dashboard integration:** composition, responsive layout, and action wiring
  after the four slices are complete.
- **Journey proof:** BDD/Playwright/accessibility coverage and exact scenario-title
  mapping.

The locked master brief remains unchanged. Any future product deviation must be
recorded in [pet-profile-decisions.md](../features/pet-profile-decisions.md) before implementation.

## Baseline characterization coverage

The current suite records the behavior that the redesign must preserve while the
preview contract changes:

- `guardian_shell_home_content_test.dart`: current three-section composition,
  current all-six-pet rendering baseline, Manage pets affordance, and wide/narrow
  layout behavior.
- `guardian_my_pets_section_test.dart`: owned, fostered, shared, and empty-state
  grouping semantics.
- `guardian_upcoming_events_section_test.dart`: five-item cap, mobile/desktop
  presentation, completion, optimistic loading, server exclusion, and undo.
- `experience_shell_scaffold_test.dart`: root/sub-screen controls, persistent bell,
  combined unread badge, no Home button, and drawer boundaries.
- `guardian_dashboard.feature` and its mapped Playwright spec: current route
  journeys and pending-banner absence. The obsolete six-pet scenario remains
  unchanged until the presentation slice updates it deliberately.

These tests are characterization, not permission to preserve obsolete visual
requirements. The four-pet preview and Today orientation become implementation
requirements in the downstream tasks.
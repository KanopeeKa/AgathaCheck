---
title: Guardian dashboard redesign brief
owner: Experience Program Team
audience: both
status: active
last_updated: 2026-08-21
tags: [experience,guardian,organisation]
---
> **Status:** Locked master brief (source of truth). Do not edit inline — track deviations in
> [pet-profile-decisions.md](/docs/domains/pet_profile/features/pet-profile-decisions.md) and feature-level detail in
> [`/docs/domains/pet_profile/changes/phase-2-guardian-journey.md`](/docs/domains/pet_profile/changes/phase-2-guardian-journey.md). Imported verbatim 2026-07-25.
> Note: "Events" and "family events" terminology in this brief is **redefined** by decisions
> D17 and D18 — see the decisions log before implementing.

# Guardian dashboard redesign brief

## Purpose

Redesign the Guardian dashboard so it becomes a clear, useful landing page for guardian workflows rather than a generic mixed home feed. The dashboard should help users quickly orient themselves around their pets, upcoming care actions, veterinary contacts, and important updates while remaining light, readable, and mobile-first [file:33][web:46][web:48].

This brief is written to be readable by both humans and AI implementation tools. It defines the structure, behavior, and UX intent while leaving room for the implementing system to apply its own visual system, spacing rules, and component logic.

## Role of the dashboard

The Guardian dashboard should act as a section landing page, not as a full management screen. Each section should preview a limited subset of information and provide a clear path to the dedicated screen where the full list and related actions live [file:33].

The dashboard should include the following primary sections:

- My Pets
- Upcoming Pet Events
- My Vets

Notifications should be treated as a global cross-domain layer accessed from the header, not as a core content block inside the Guardian dashboard [web:50][web:52][web:60][web:76].

## Structural pattern

All dashboard content sections should follow a consistent pattern:

- Section title
- Optional section-level action in the header when relevant
- Compact preview of the most important items
- End link or button leading to the full screen for that object type

This creates a symmetrical and predictable dashboard model. The dashboard shows the most relevant subset, while the dedicated full screen handles the complete list and associated management actions.

## Section rules

The Guardian dashboard should use this navigation logic:

| Section | Dashboard role | Dedicated full screen | Primary screen-level action |
|---|---|---|---|
| My Pets | Preview of pet list | All Pets | Add a pet, Bulk share |
| Upcoming Pet Events | Preview of next events | All Events | Add an event |
| My Vets | Preview of vet list | All Vets | Add a vet |

Management actions should generally live in the dedicated screens or object-level views rather than in the dashboard preview itself. The dashboard should remain light and scannable.

## My Pets

### Purpose

The My Pets section should give quick visual access to the user’s pets and clearly distinguish between owned pets and foster pets. It should feel warm and visual, but still structured enough to scale [file:33].

### Card format

Use slightly rounded rectangular cards as the default pattern. Each card should contain:

- Pet image occupying the upper visual area
- A thin status bar between image and name area
- Pet name in the lower text area

This pattern is recommended over circular image-only tiles because it scales better for names, empty states, and future metadata while preserving a friendly visual feel [file:33][web:48].

### Status indication

The pet status should be communicated by the thin separator bar between image and name:

- Use the agreed Guardian theme for the user’s own pets
- Use the agreed Organisation theme for foster pets

Do not rely only on text labels when the status can be communicated with a clear but restrained visual code. The implementation may still add a small text label or badge if needed for accessibility or clarity.

### Layout behavior

The pet cards should be responsive and arranged by available width. The implementation should aim for:

- 2 cards per row on standard mobile widths
- 3 cards per row on larger phones or small tablet widths
- A consistent card ratio that keeps the image large enough for easy recognition

The dashboard should show a curated number of pets rather than the full set. Recommended default:

- Show up to 4 pets in the preview on standard mobile layouts
- If more pets exist, keep the section concise and provide an “All Pets” link at the bottom

### Section-level action

The action to add a pet should appear in the section header as **Add a pet**. It should not appear as the last card in the grid.

### Interaction

- Tapping a pet card opens that pet’s screen
- Tapping **All Pets** opens the dedicated full pet list screen
- Tapping **Add a pet** opens the add-pet flow

### Scope note

Bulk pet management should remain minimal at this stage, but one bulk action is explicitly required: **Bulk share**. The dedicated All Pets screen should therefore support **Add a pet** as the primary create action and **Bulk share** as the only collection-level bulk action for now. Other pet-specific actions may remain at the pet-card or pet-detail level if already supported.

## Upcoming Pet Events

### Purpose

This section should preview the most important upcoming pet-related actions without trying to replicate the full Events screen. It should help the user see what needs attention soon and quickly jump to the full event workflow when needed [page:1].

### Card pattern

Use the same event card language as the existing Events screen so that event objects remain visually and behaviorally consistent across the product [page:1].

The dashboard version should:

- Reuse the same component family as the Events screen
- Show the top 5 upcoming items only
- Feel like a preview rather than a second full events list

### Section actions and links

- The section should include **Add an event** in the header
- The bottom of the section should include **All Events** or **See all** linking to the full Events screen

### Interaction

- Tapping an event opens the relevant event detail or workflow
- Tapping **All Events** opens the full events screen
- Tapping **Add an event** opens the event creation flow

### Scope note

The existing Events screen already exists and does not need a major redesign as part of this brief. The immediate goal is consistency with the dashboard preview and the addition of a clear create action.

## My Vets

### Purpose

This section should provide quick access to veterinary contacts associated with the guardian’s pets. It should function as a practical relationship list rather than a dense admin table.

### List format

Display vets in a simple list showing:

- Vet name
- City, if available
- Number of associated pets

This section should be easy to scan and more text-based than the pet section.

### Detail model

Tapping a vet should open a dedicated vet card or screen in **display mode** first. That display layer should include the vet details and direct actions such as:

- Call
- Email

A separate **edit mode** should exist for modifying the vet record. The current edit-first model should be replaced by this display-first pattern.

### Section actions and links

- The section should include **Add a vet** in the header
- The bottom of the section should include **All Vets** linking to the full vet list screen

### Scope note

Bulk vet management is not needed at this stage. Edit and delete should be object-level actions inside each vet’s display or card flow rather than screen-wide bulk tools.

## Section symmetry rules

The dashboard should apply a consistent preview-to-full-screen structure across all three sections. This symmetry is intentional and should guide both UX and implementation.

The general model is:

- Dashboard section = lightweight preview
- Full screen = complete list and primary screen-level action
- Object detail = object-specific actions such as edit or delete where appropriate

This keeps the dashboard focused while still making every area feel complete and navigable.

## Notifications

### Recommendation

Notifications should be a global cross-domain feature, not split between Guardian and Organisation. Users should have one place to review all important updates, while the notification content itself can indicate whether the item belongs to Guardian or Organisation [web:50][web:52][web:60][web:76].

### Placement

Notifications should be accessed from a bell icon in the header, not from the hamburger menu and not from the Account area [web:68][web:71][web:75].

### Open behavior

Tapping the bell should open a full-height slide-over panel from the right. This panel should visually relate to the hamburger drawer so the global shell feels consistent, but it should function as a notification center rather than a section switcher [web:68][web:73][web:76].

### Notification center behavior

The notification panel should:

- Show notifications from both Guardian and Organisation in one unified inbox
- Use visual labeling, grouping, or filtering to distinguish notification sources
- Support unread state clearly
- Deep-link each notification to the relevant destination screen
- Preserve user context as much as possible when opened and dismissed [web:50][web:60][web:73][web:76]

### Design principles

The notification center should follow these rules:

- It must be useful, relevant, and not noisy [web:50][web:60]
- It should not force users to visit multiple areas to understand what needs attention [web:52][web:76]
- It should help users triage rather than simply dump alerts in time order [web:60][web:74]
- Read state and resolved state should be treated as distinct concepts where relevant [web:60][web:74]
- The bell and its badge should remain globally understandable and should not compete with the section-switching logic of the hamburger [web:68][web:71][web:75]

## Mobile and accessibility expectations

The dashboard and notification layer should be mobile-first and easy to use on small screens. Controls in section headers, cards, rows, and the notification bell should maintain comfortable touch targets and clear visual affordance [web:46][web:48].

The dashboard should avoid becoming visually dense. Hierarchy, spacing, and preview limits should help users scan quickly and act confidently.

## Guardrails

The implementation should avoid the following pitfalls:

- Turning the Guardian dashboard into another generic home feed
- Showing too many pets, events, or vets in the preview sections
- Mixing full management workflows directly into dashboard preview blocks
- Using inconsistent section structures across pets, events, and vets
- Splitting notifications into separate silos by domain
- Putting notifications inside Account or the hamburger section switcher
- Making the notification panel behave like a second navigation menu
- Overloading the pet cards with too much metadata too early

## Flexibility for implementation

This brief is intentionally directional rather than over-specified at the component level. The implementing AI or designer may choose the precise visual style, spacing scale, motion, iconography, and detailed component behavior, provided the structural and interaction rules in this brief remain intact [file:33].

The final output should feel coherent with the redesigned navigation model, should support future native-app portability, and should preserve a calm, modern, mobile-first product shell [file:32][file:33][web:46][web:48].

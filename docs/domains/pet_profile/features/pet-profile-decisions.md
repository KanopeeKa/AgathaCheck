---
title: Pet profile decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-10
tags: [pet_profile, decisions]
domain: pet_profile
feature_id: pet-profile-decisions
---

# Pet profile — locked decisions

Product decisions for Pet Care dashboard, pet timeline, events, and vet UX (D17–D24, D34–D38). Other docs reference these IDs instead of restating rationale.

---

## D — "Event" and pet timeline redefinition

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D17** | "Event" (Pet Care dashboard "Upcoming Pet Events", `/pc/events`) means **health events only**: due/overdue health entries, weight entries, and "other" entries. It is a computed/filtered view over existing domain data — **not** a new domain entity. "Add an event" = quick-add sheet routing to the existing health/weight/other-entry forms. | locked | Phase 2 |
| **D18** | The legacy "family events" concept (`family_events` table, `familyEventsRouter.js`, `organisation_pet_timeline.feature`) is **superseded** by a per-pet **Timeline** composed of: (a) human-guardian custody segments (start/end/note/guardian name — name visible only with permission) derived from `custody_transfers` history; (b) fostering-session cards (existing J3 read model, reused as-is); (c) a manual fallback entry (title/description/start/end) fillable by the guardian (human or org) when no system-derived segment exists ("No data" placeholder). Timeline lives on the **pet detail screen**, not the Pet Care dashboard — it is a different feature from D17's Upcoming Pet Events. | locked | Phase 2 |
| **D19** | Remaining `family_events` rows not already migrated by migration `016` are one-time migrated into the new manual-timeline-entries table (preserving notes/dates), then `family_events` table + router are retired. | locked | Phase 2 |

## F — Pet Care-side small features

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D23** | Bulk share = thin Flutter-only multi-select wrapper around the existing single-pet share endpoint (loop per selected pet). No new backend bulk endpoint. | locked | Phase 2 |
| **D24** | Vet detail becomes **display-first** (Call/Email actions visible immediately); a separate edit mode/screen replaces today's edit-first `VetFormScreen` default. | locked | Phase 2 |

## Pet Care Today dashboard contract

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D34** | Pet Care `/pc/home` has exactly three management sections: **My Pets**, **Care Actions** (legacy Due and Overdue), and **Veterinary team** (user-facing label; vet routes unchanged). **Away planning** is a fourth dashboard element — a compact entry tile above those sections (not a management screen or new route). **Today** orientation/prioritisation, when shown, remains separate from both. | locked | Phase 2 |
| **D35** | The dashboard preview is capped at **4 pets** and **5 care items**. Pet previews use bounded rectangular cards with an approximately **96–112 px** photo region, accessible placeholders, and ownership/status text or icon support. **Veterinary team** uses uncapped warm clinic cards with initials avatars and optional linked-pet previews. | locked | Phase 2 |
| **D36** | Pet Care Today is presentation-only over existing providers and helpers. Ownership/relationship semantics, due ordering, server-authoritative completion/undo, retryable error states, existing routes, and global notifications remain unchanged. "Events" continues to mean computed health/weight/other care entries under D17, never a new generic event entity. | locked | Phase 2 |
| **D37** | A five-tab bottom bar, universal Add action, and new Today route are deferred from this branch. They require a separate decision covering shared Pet Care/Shelter shell semantics, root/back/deep-link behavior, Add scope and permissions, accessibility, and native portability. | deferred | Future navigation decision |
| **D38** | **Pet Care** is the canonical product name for the individual-carer workspace (peer to **Shelter**). **My Pets** names only the dashboard pet-rail section (owned/fostered/shared preview), not the workspace. Dashboard due-items block: eyebrow **CARE ACTIONS** (FR **SOINS**), link **All Actions** (FR **Tous les soins**). Bottom nav tab **Actions** (FR **Soins**). Workspace routes migrate `/pc/*` → `/pc/*`; wire `pet_care` replaces `guardian` for experience scope. Custody **guardianship** legal terms in [org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md) are unchanged. Full map: [Pet Care domain README — Wire and code map](/docs/domains/pet_care/README.md#wire-and-code-map). | locked | Pet Care rename |

**D34 note:** Section titles in D34 used "Due and Overdue" for the care block; **D38** supersedes that label with **Care Actions** / **Actions** nav. **My Pets** and **Veterinary team** unchanged (D-AWAY-012).

## User journeys

User-facing flows for pet carers managing pets in AgathaTrack.

### Pet Care dashboard (landing)

The Pet Care dashboard (`/pc/home`) is a section landing page with three symmetric previews: **My Pets**, **Care Actions** (eyebrow CARE ACTIONS), and **Care team**. Each section shows a compact subset and links to the full management screen. Locked brief: [guardian-dashboard-brief.md](guardian-dashboard-brief.md).

### Create and edit pet

Pet carers add pets from the pet list or dashboard, enter profile fields (name, species, breed, photo, vet link), and save. Edits update the pet record; weight edits may create a same-day weight entry (see [weight_tracking](/docs/domains/weight_tracking/README.md)).

### Pet timeline

Pet timeline cards replace legacy family-events terminology (D18). Timeline shows foster placements, health milestones, and profile events on the pet detail view.

### Bulk share

Pet carers select multiple owned pets and open the bulk-share flow from the pets list (D23).

### View pet list and detail

All Pets screen lists owned and foster pets with visual distinction (Pet Care vs Shelter theme on status bar). Pet detail surfaces health, weight, sharing, and timeline sections.

## Implementation reference

### Pet activity model (org sort / preview)

Organisation v2 **last-activity sorting** for the 12-pet profile preview uses a product-layer model distinct from compliance audit (`audit_events`) and guardian timeline (`pet_timeline_entries`). Full specification: [pet-activity-model.md](pet-activity-model.md). Architecture stub (superseded): [/docs/architecture/pet-activity-model.md](/docs/architecture/pet-activity-model.md).

### Pet CRUD validation

- Pets belong to a guardian account; foster pets appear via organisation custody (see organization / fostering domains).
- Calendar dates on the wire use `YYYY-MM-DD` ([calendar-dates.md](/docs/architecture/calendar-dates.md)).

### Sharing section on pet detail

Role-specific sharing UI lives under `flutter_app/lib/features/pet_profile/widgets/sharing/` — see [sharing](/docs/domains/sharing/README.md) for share-link semantics.

### Guardian mobile completion

Due-events preview supports reversible mobile completion with transient cache during refresh (same rules as care-item mobile completion UX).

### Pet Care Today — authority boundaries

Locked decisions **D34–D36** define product boundaries. Implementation must derive presentation from existing authorities only (no new API, schema, or ownership heuristics):

| Dashboard concern | Stable source/authority | Constraint |
|---|---|---|
| Owned, fostered, and shared pets | `PetListController` and `guardian_dashboard_helpers.dart` | Do not infer ownership or eligibility from visual state. |
| Pet card relationship/status | Existing `Pet` fields and `ownership_accent.dart` conventions | Plum/Pet Care and green/foster accents require text or icon support; never colour alone. |
| Due/overdue care items | `healthEntriesNotifierProvider`, `guardianDueEntries`, and existing health entry entities | “Events” means computed health, weight, and other care entries per D17; no generic event entity. |
| Completion and undo | Existing `HealthEntriesNotifier.markTaken` / `undoComplete` flow | The server remains authoritative; preserve optimistic preview and rollback/error semantics. |
| Veterinary contacts | `vetListProvider` and existing vet entities | Keep compact rows and existing display/detail destinations. |
| Global updates | Existing unified notification provider and header bell | Notifications remain global and outside the dashboard section list. |
| Section shell/navigation | `ExperienceShellScaffold` and drawer configuration | Keep Pet Care, Shelter, and Account as the top-level shell model. |

### Pet Care Today presentation foundation

Pure, local adapter for existing owned pets and health entries — no requests, permission inference, or provider-owned collection changes.

- **Inputs:** eligible pets via `PetListController.guardianShellPets`; `HealthEntry` values and an explicit clock for care priorities; explicit screen state for loading/error.
- **Outputs:** `GuardianTodayCarePriorities` (overdue, due-today, reminder-window upcoming; dashboard preview capped at five); `GuardianTodayPetPreview` (attention-first four-pet preview + overflow count); relationship/care-status/screen-state enums for UI consumers.
- **Ordering:** overdue → due-today → reminder-window upcoming; date order and source order break ties. Pet selection follows the same urgency groups, then stable guardian-shell order. Passed-away pets are not presented.
- **States:** `firstUse`, `allClear`, `attention`, `loading`, `partial`, and `error` are distinct; errors must not present as an empty care list.

### Pet Care Today orientation widget

`GuardianTodayOrientation` is the compact, provider-free orientation layer above the three management sections — not a dashboard section, route, or care list.

```dart
GuardianTodayOrientation(
  state: GuardianTodayScreenState,
  summary: GuardianTodayCareSummary?,
  onRetry: VoidCallback?,
)
```

- Pass state and summary from the presentation foundation; do not watch providers inside the widget.
- `summary` is required for `attention` and `allClear`; missing data resolves to `partial`.
- Compose once above My Pets, Care Actions, and Veterinary team; no individual care rows; grouped semantic summary for screen readers; retry is the only interactive control (48dp target).

### Dashboard desk framing (D-desk)

Shell and section chrome on `/pc/home` (medium+ viewports) without redesigning row components. Control issue #928; supersedes bottom “All …” links with header-row actions per **D-desk-3**.

| ID | Decision | Status |
|----|----------|--------|
| **D-desk-1** | Nav rail/sidebar uses semantic `surface`; main column uses `background`. No vertical dividers or card-wrapped sidebar. | locked |
| **D-desk-2** | Mobile unchanged: plum app bar + bottom nav; no desktop sidebar framing on &lt;600px. | locked |
| **D-desk-3** | Section chrome: eyebrow title (left) + optional “All …” (right) when a real destination exists. | locked |
| **D-desk-4** | No phantom “All …” links — same gating as today. | locked |
| **D-desk-5** | Open canvas default; no tinted `GuardianDeskSectionCard` shells except Care preview `petCareLight` and optional Fostering org tint. | locked |
| **D-desk-6** | Pets hero rail may omit PETS eyebrow when the rail is the anchor. | locked |
| **D-desk-7** | Dashboard max width **1120px**, centered; horizontal padding 16 / 24 / 32 by breakpoint. | locked |
| **D-desk-8** | Sidebar active state: one primary channel (colour + optional slim left bar). | locked |
| **D-desk-9** | Out of scope: row component redesign; shell-wide max width on every route; create actions in section headers. | locked |
| **D-desk-10** | Optional non-interactive sketch overlays on wide web only (`assets/dashboard/dashboard-deco-*.png`); `ExcludeSemantics` + `IgnorePointer`. | locked |

| Width | Nav surface | Canvas | Section chrome |
|-------|-------------|--------|----------------|
| &lt;600px | Plum app bar + bottom nav | `background` full width | Header row; 16px padding |
| 600–839px | Rail `surface` | Column `background` | Header row; 24px padding |
| ≥840px | Sidebar `surface` | Column `background`, max 1120px centered | Header row; 24–32px padding |

### Pet Care Today — action destinations

| User action | Existing destination/behavior |
|---|---|
| Open a pet card | `/pet/:id` |
| Open the full pet collection | `/pc/pets` |
| Open a care item | Existing health-entry detail/workflow |
| Open all care items | `/pc/events` |
| Complete or undo a care item | Existing `markTaken` / `undoComplete` flow |
| Open a vet row | `/pc/vets/:id` |
| Open all vets | `/pc/vets` |
| Review global updates | Header notification bell/panel |
| Switch top-level experience | Pet Care / Shelter / Account drawer |

### Pet Care Today — characterization tests

Preserve behavior while preview caps change: `guardian_shell_home_content_test.dart`, `guardian_my_pets_section_test.dart`, `guardian_upcoming_events_section_test.dart`, `experience_shell_scaffold_test.dart`, `guardian_dashboard.feature` / Playwright (pending-banner absence). Four-pet preview and Today orientation are implementation requirements in downstream UI slices.

### Tests

- BDD: `pet_profiles.feature`
- Playwright: `pet.profiles.spec.ts`

## Pet tags v1

Private per-user labels for organizing and filtering pets on `/pc/pets`. No sharing integration.

| Layer | Detail |
|-------|--------|
| Data | `pet_tags` (user-owned definitions); `pet_tag_assignments` (many-to-many). Assignments are not cleaned up when `pet_access` is revoked (lazy ignore). CASCADE on user, pet, or tag delete. |
| API | `GET/POST/PATCH/DELETE /api/pet-tags`; `POST/DELETE /api/pets/:petId/tags` (assign/unassign). Client uses `GET /api/pet-tags` with `pet_ids[]` for filter, profile, and manage UI. |
| UI | Account → Preferences → Pet tags (catalog CRUD); pet profile → My tags; `/pc/pets` → tag filter (Match any / Match all). |

## Profile facts (server — PR-01)

| ID | Requirement | Status |
|----|-------------|--------|
| **ACJ-PF-001** | `identification_status` / `neuter_status` enum `yes \| no \| unknown` on `pets` (migration `099_pet_profile_facts`) | Live (integration) |
| **ACJ-PF-003** | PUT merge: status + dismiss fields + `chip_id` kept when omitted; normalise chip ↔ status per programme | Live (integration) |
| **ACJ-PF-004** | Provenance columns `*_status_source`, `*_status_updated_at` on wire + DB | Live (integration) |
| **ACJ-PF-005** | View-only PUT → 403; invalid enum → 400 | Live (integration) |
| **ACJ-PF-005b** | Org shadow snapshot excludes new status fields (unchanged shadow shape) | Live (integration) |

## Profile facts (Flutter — PR-02)

| ID | Requirement | Status |
|----|-------------|--------|
| **ACJ-PF-PL-001** | `identificationStatus` / `neuterStatus` on `Pet` + `PetModel` wire (`yes \| no \| unknown`; default `unknown`) | Live (integration) |
| **ACJ-PF-PL-003** | Pet form edit PUT preserves status fields when the profile form does not change them | Live (integration) |
| **ACJ-PF-PL-004** | Optional `*_status_source` on wire parsed on read; included in `toJson` when set | Live (integration) |

## Planned — Agatha care journey (PR #1833 programme)

Delivery spec: [agatha-care-journey-programme.md](../../pet_care/changes/agatha-care-journey-programme.md). Fold into this doc when PR-01+ land.

| ID | Planned decision | Notes |
|----|------------------|-------|
| **ACJ-PF-PL-002** | “Not for my pet” uses `chip_dismissed` / `neuter_dismissed`, not status enums | PR-04 |
| **ACJ-PF-PL-005** | New status fields excluded from org shadow / share preview / redacted views by default | PR-01 |

## How to use

- Activity model detail: [pet-activity-model.md](pet-activity-model.md)
- Delivery plans: [plans.md](../changes/plans.md)
- Pet Care Today implementation: sections above (D34–D36, presentation foundation, orientation, D-desk)
- Wave 2 issue briefs (historical AC archive, in-delivery): [guardian-ui-wave2-issue-briefs.md](../changes/guardian-ui-wave2-issue-briefs.md)
- Locked dashboard brief: [guardian-dashboard-brief.md](guardian-dashboard-brief.md)
- Guardian journey delivery: [phase-2-guardian-journey.md](../changes/phase-2-guardian-journey.md)

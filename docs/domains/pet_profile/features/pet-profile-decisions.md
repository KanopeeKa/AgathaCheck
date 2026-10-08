---
title: Pet profile decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
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

## How to use

- Activity model detail: [pet-activity-model.md](pet-activity-model.md)
- Delivery plans: [plans.md](../changes/plans.md)
- Pet Care Today contract (phase 3.2): [guardian-today-contract.md](../changes/guardian-today-contract.md)
- Locked dashboard brief: [guardian-dashboard-brief.md](guardian-dashboard-brief.md)
- Guardian journey delivery: [phase-2-guardian-journey.md](../changes/phase-2-guardian-journey.md)

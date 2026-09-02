---
title: Pet profile decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-02
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
| **D34** | Pet Care `/pc/home` remains exactly three management sections: **My Pets**, **Due and Overdue**, and **Care team** (user-facing label; vet routes unchanged). **Today** is a compact orientation/prioritisation layer above them, not a fourth section, management screen, or new route. | locked | Phase 2 |
| **D35** | The dashboard preview is capped at **4 pets** and **5 care items**. Pet previews use bounded rectangular cards with an approximately **96–112 px** photo region, accessible placeholders, and ownership/status text or icon support. **Care team** uses uncapped warm clinic cards with initials avatars and optional linked-pet previews. | locked | Phase 2 |
| **D36** | Pet Care Today is presentation-only over existing providers and helpers. Ownership/relationship semantics, due ordering, server-authoritative completion/undo, retryable error states, existing routes, and global notifications remain unchanged. "Events" continues to mean computed health/weight/other care entries under D17, never a new generic event entity. | locked | Phase 2 |
| **D37** | A five-tab bottom bar, universal Add action, and new Today route are deferred from this branch. They require a separate decision covering shared Pet Care/Shelter shell semantics, root/back/deep-link behavior, Add scope and permissions, accessibility, and native portability. | deferred | Future navigation decision |
| **D38** | **Pet Care** is the canonical product name for the individual-carer workspace (peer to **Shelter**). **My Pets** names only the dashboard pet-rail section (owned/fostered/shared preview), not the workspace. Dashboard due-items block: eyebrow **CARE ACTIONS** (FR **SOINS**), link **All Actions** (FR **Tous les soins**). Bottom nav tab **Actions** (FR **Soins**). Workspace routes migrate `/pc/*` → `/pc/*`; wire `pet_care` replaces `guardian` for experience scope. Custody **guardianship** legal terms in [org-custody-model.md](/docs/domains/shelter/features/org-custody-model.md) are unchanged. Full map: [pet_care domain rename plan](/docs/domains/pet_care/changes/domain-rename-plan.md). | locked | Pet Care rename |

**D34 note:** Section titles in D34 used "Due and Overdue" for the care block; **D38** supersedes that label with **Care Actions** / **Actions** nav. **My Pets** and **Care team** unchanged.

## How to use

- Delivery plans: [plans.md](../changes/plans.md)
- Pet Care Today contract: [guardian-today-contract.md](../changes/guardian-today-contract.md) (filename legacy; content describes Pet Care home)
- Locked brief: [guardian-dashboard-brief.md](guardian-dashboard-brief.md)

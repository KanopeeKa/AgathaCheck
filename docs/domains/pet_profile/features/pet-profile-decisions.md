---
title: Pet profile decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [pet_profile, decisions]
domain: pet_profile
feature_id: pet-profile-decisions
---

# Pet profile — locked decisions

Product decisions for Guardian dashboard, pet timeline, events, and vet UX (D17–D24, D34–D37). Other docs reference these IDs instead of restating rationale.

---

## D — "Event" and pet timeline redefinition

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D17** | "Event" (Guardian dashboard "Upcoming Pet Events", `/g/events`) means **health events only**: due/overdue health entries, weight entries, and "other" entries. It is a computed/filtered view over existing domain data — **not** a new domain entity. "Add an event" = quick-add sheet routing to the existing health/weight/other-entry forms. | locked | Phase 2 |
| **D18** | The legacy "family events" concept (`family_events` table, `familyEventsRouter.js`, `organisation_pet_timeline.feature`) is **superseded** by a per-pet **Timeline** composed of: (a) human-guardian custody segments (start/end/note/guardian name — name visible only with permission) derived from `custody_transfers` history; (b) fostering-session cards (existing J3 read model, reused as-is); (c) a manual fallback entry (title/description/start/end) fillable by the guardian (human or org) when no system-derived segment exists ("No data" placeholder). Timeline lives on the **pet detail screen**, not the Guardian dashboard — it is a different feature from D17's Upcoming Pet Events. | locked | Phase 2 |
| **D19** | Remaining `family_events` rows not already migrated by migration `016` are one-time migrated into the new manual-timeline-entries table (preserving notes/dates), then `family_events` table + router are retired. | locked | Phase 2 |

## F — Guardian-side small features

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D23** | Bulk share = thin Flutter-only multi-select wrapper around the existing single-pet share endpoint (loop per selected pet). No new backend bulk endpoint. | locked | Phase 2 |
| **D24** | Vet detail becomes **display-first** (Call/Email actions visible immediately); a separate edit mode/screen replaces today's edit-first `VetFormScreen` default. | locked | Phase 2 |

## Guardian Today dashboard contract

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D34** | Guardian `/g/home` remains exactly three management sections: **My Pets**, **Due and Overdue**, and **My Vets**. **Today** is a compact orientation/prioritisation layer above them, not a fourth section, management screen, or new route. | locked | Phase 2 |
| **D35** | The dashboard preview is capped at **4 pets** and **5 care items**. Pet previews use bounded rectangular cards with an approximately **96–112 px** photo region, accessible placeholders, and ownership/status text or icon support. My Vets remains an uncapped compact, scannable row list unless separately revised. | locked | Phase 2 |
| **D36** | Guardian Today is presentation-only over existing providers and helpers. Ownership/relationship semantics, due ordering, server-authoritative completion/undo, retryable error states, existing routes, and global notifications remain unchanged. "Events" continues to mean computed health/weight/other care entries under D17, never a new generic event entity. | locked | Phase 2 |
| **D37** | A five-tab bottom bar, universal Add action, and new Today route are deferred from this branch. They require a separate decision covering shared Guardian/Organisation shell semantics, root/back/deep-link behavior, Add scope and permissions, accessibility, and native portability. | deferred | Future navigation decision |

---

## How to use

- Delivery plans: [plans.md](../changes/plans.md)
- Guardian Today contract: [guardian-today-contract.md](../changes/guardian-today-contract.md)
- Locked brief: [guardian-dashboard-brief.md](guardian-dashboard-brief.md)

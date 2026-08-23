---
title: Notification decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [notifications, decisions]
domain: notifications
feature_id: notification-decisions
---

# Notifications — locked decisions

Product decisions for the global bell, unified panel, and kind vs scope semantics (D7–D11). Other docs reference these IDs instead of restating rationale.

---

## B — Notifications (kind vs scope)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D7** | Notifications have **two orthogonal axes**: `kind` (**Care** — health/weight/other-entry due items; **Administrative** — org/foster workflow items, approvals, sessions, messages, agreement-withdrawal alerts) and `scope` (`guardian` / `organization`, the existing enum, kept only as a *grouping label*, not a routing/screen split). A single foster user can receive Care-kind items with `scope=organization` (health reminder for a fostered pet) and Administrative-kind items with `scope=organization` (shelter message) — proving kind ≠ scope. | locked | Phase 1 |
| **D8** | One global bell, one unified full-height right slide-over. Badge = single combined unread count. Inside the panel: filter chips **All / Care / Organisation** (kind-based, reusing plum/green ownership-accent tokens) sit above the existing date-grouped list. For the ~98% guardian-only or guardian+foster population, the chips are low-friction (mostly everything is "Care" for guardian-only users) and become genuinely useful only once org/foster activity exists. | locked | Phase 1 |
| **D9** | "Resolved" state (distinct from "read") applies **only** to Administrative-kind notifications that reference an open actionable object (foster request, agreement-withdrawal alert, pending transfer/share/custody/adoption). Resolved is **derived** from the referenced object's state transition, not a manual dismiss. Care-kind items keep the existing read/unread-only model. | locked | Phase 1 |
| **D10** | The former dashboard-resident pending inboxes (pending shares, pending foster placements, pending adoption placements, pending custody transfers) **move into the Administrative notification feed** (unresolved until accepted/declined) instead of living as permanent dashboard banners. This resolves the Guardian dashboard's "where do these go" gap. | locked | Phase 2 |
| **D11** | Emergency/urgent Administrative notifications (e.g. agreement withdrawal) get a visually distinct treatment (warning/danger token leading icon, pinned above date order within the Administrative filter) but are **not** a third kind — still Administrative, just priority-flagged. | locked | Phase 4 |

---

## How to use

- Contract detail: [program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §3
- Phase delivery: [phase-1-navigation.md](/docs/domains/navigation/changes/phase-1-navigation.md)
- Navigation shell decisions: [navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md)

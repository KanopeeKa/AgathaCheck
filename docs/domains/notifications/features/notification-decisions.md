---
title: Notification decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [notifications, decisions]
domain: notifications
feature_id: notification-decisions
---

# Notifications — locked decisions

Product decisions for the global bell, unified panel, and kind vs scope semantics (D7–D11). Other docs reference these IDs instead of restating rationale.

> **Notifications v2 (accepted 2026-10-04)** supersedes or amends D7–D10. See §C and the [v2 spec](notifications-v2-spec.md). The B table is kept as history. While v2 ships PR by PR, the code still follows §B until the PR named in §C lands.

---

## B — Notifications (kind vs scope)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D7** | ~~Superseded by v2 (§C)~~ Notifications have **two orthogonal axes**: `kind` (**Care** — health/weight/other-entry due items; **Administrative** — org/foster workflow items, approvals, sessions, messages, agreement-withdrawal alerts) and `scope` (`guardian` / `organization`, the existing enum, kept only as a *grouping label*, not a routing/screen split). A single foster user can receive Care-kind items with `scope=organization` (health reminder for a fostered pet) and Administrative-kind items with `scope=organization` (shelter message) — proving kind ≠ scope. | locked | Phase 1 |
| **D8** | ~~Chips and combined badge superseded by v2 (§C)~~ One global bell, one unified full-height right slide-over. Badge = single combined unread count. Inside the panel: filter chips **All / Care / Organisation** (kind-based, reusing plum/green ownership-accent tokens) sit above the existing date-grouped list. For the ~98% guardian-only or guardian+foster population, the chips are low-friction (mostly everything is "Care" for guardian-only users) and become genuinely useful only once org/foster activity exists. | locked | Phase 1 |
| **D9** | "Resolved" state (distinct from "read") applies **only** to Administrative-kind notifications that reference an open actionable object (foster request, agreement-withdrawal alert, pending transfer/share/custody/adoption). Resolved is **derived** from the referenced object's state transition, not a manual dismiss. Care-kind items keep the existing read/unread-only model. | locked | Phase 1 |
| **D10** | The former dashboard-resident pending inboxes (pending shares, pending foster placements, pending adoption placements, pending custody transfers) **move into the Administrative notification feed** (unresolved until accepted/declined) instead of living as permanent dashboard banners. This resolves the Pet Care dashboard's "where do these go" gap. | locked | Phase 2 |
| **D11** | Emergency/urgent Administrative notifications (e.g. agreement withdrawal) get a visually distinct treatment (warning/danger token leading icon, pinned above date order within the Administrative filter) but are **not** a third kind — still Administrative, just priority-flagged. | locked | Phase 4 |

---

## How to use

- Contract detail: [program-contract.md](/docs/domains/cross-domain/changes/program-contract.md) §3
- Phase delivery: [phase-1-navigation.md](/docs/domains/navigation/changes/phase-1-navigation.md)
- Navigation shell decisions: [navigation-decisions.md](/docs/domains/navigation/features/navigation-decisions.md)

---

## C — Notifications v2 supersession

Source: [notifications-v2-spec.md](notifications-v2-spec.md) §0.

| ID | Decision | Status | Lands in |
|----|----------|--------|----------|
| **D7** | Kinds become `relationship \| administrative \| suggestion \| account`. `care` is retired from the inbox. Care reminders are push/local only, and Care Actions / Actions are their single home. | superseded | PR1 (server), PR2 (client) |
| **D8** | The bell and slide-over are kept. Chips are replaced by **Activity / For you** tabs. The combined unread badge is replaced by the calm badge: a number for needs-response + urgent + unanswered new sign-in, otherwise a dot. | partially superseded | PR2 |
| **D9** | Resolved also applies to `relationship` and `account` items that reference an open object (invites, new sign-in, payment issue). It is still derived, never a manual dismiss. | extended | PR4 |
| **D10** | Pending shares and household invites become `relationship`. Foster/adoption/custody stay `administrative`. All of them are in **Needs your response**, with inline accept/decline instead of a deep link. | amended | PR3–PR4 |
| **D11** | Urgent pinned at the top of Activity. Also used for subscription payment issues (A9). | unchanged | — |
| **N1** | The inbox holds only what the inbox alone can tell you. | locked | — |
| **N2** | Grouping is a read-model concern; storage is one row per recipient per event. | locked | PR4 |
| **N3** | Wire `type` stays camelCase; `general` is banned for new rows. | locked | PR3 |
| **N4** | Suggestions are server-generated only; pet-profile cards read the same API. | locked | PR5 |
| **N5** | The inbox is not compliance evidence; that lives in `audit_events` / reports. | locked (hard-delete blocked on audit debt) | — |
| **N6** | Invites expire at 14 days, with one invitee reminder on day 7. | locked | PR4 |
| **N7** | The absence-coverage suggestion (S7) goes to the record owner only. | locked | PR5 |
| **N8** | Email digest on by default only for users with no push device. | locked | PR6 |
| **N9** | 90-day inbox archive for every kind. | locked | PR1 |
| **N10** | `account` kind for security and subscription, shown in Activity. | locked | PR7 |
| **N11** | Security notices contain no sign-in links or codes; they offer "This was me" / "Secure my account". | locked | PR7 |
| **N12** | Subscription notices cover only what the store doesn't tell the user; independent of the billing provider; need a server entitlement source. | locked | PR8 (blocked: billing provider) |
| **N13** | New-device detection uses a coarse device label only; no IP or location. | locked | PR7 |

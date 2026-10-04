---
title: Notifications journeys
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [domain,notifications,journeys]
domain: notifications
---

# Notifications journeys

User-facing flows for the global bell and inbox, per [Notifications v2](notifications-v2-spec.md) (accepted 2026-10-04) and [notification-decisions.md](notification-decisions.md) §C.

> **Rollout:** v2 ships in PR1–PR8 (spec §12). Until PR2 lands, the app still shows the All / Care / Organisation chips and care items in the inbox.

## Open the inbox from the header bell

On every authenticated screen, the header shows a persistent bell. On wide layouts it opens a full-height right slide-over; on compact layouts, a full screen with the same content. The inbox has two tabs: **Activity** (default) and **For you**.

The bell shows a **number** for items that need you: invites to answer, urgent items, and an unanswered new-sign-in alert. It shows a **dot** when there is only something new to read. Care reminders never touch the bell.

## Answer an invite without leaving the inbox

Someone shares a pet or invites you to a household. The item appears under **Needs your response** with **Accept / Decline**. Accept shows what you're granted before confirming; Decline offers Undo. Tapping the row itself opens the full invite screen. If the invite was cancelled meanwhile, the row shows "Already handled".

## See who joined, left or changed your access

Activity lists people updates: invites accepted or declined, access changed or removed, members joining or leaving, pets added to or removed from a household, ownership transferred, a pet marked as passed away. Similar updates within a day are grouped ("Paul and 2 others joined…"); tap the group to expand it.

## Review a security alert

After a sign-in from a new device, Activity shows the device and time, with **This was me** / **Secure my account**. Secure my account signs out other devices and asks for a new password. Password changes and forced sign-outs are also reported. Security alerts are also emailed, contain no sign-in links, and can't be turned off.

## Subscription updates *(after the billing provider is chosen)*

Activity reports when Unlimited becomes active, an annual renewal is coming up, a payment fails (urgent, with **Update payment**), or the plan ends (with what changes on Free; no data is deleted).

## Act on an Agatha suggestion

**For you** groups suggestions by pet. Each card shows why it appeared, one action (e.g. *Add reminder*), and **Dismiss / Not relevant / Why am I seeing this?**. Health-related cards remind you that Agatha isn't a vet. Suggestions expire after 14 days; users get at most a few per week, plus an optional weekly digest.

## Organisation and foster items

Foster requests, placements, adoption, custody, org messages and agreement-withdrawal alerts stay in Activity with their "From: <org>" label. Pending ones sit under **Needs your response**; urgent ones are pinned at the top (D11).

## Care reminders

Due and overdue care is in **Care Actions** (dashboard) and **Actions**, and is delivered as device reminders. It is no longer duplicated in the inbox.

## Notification settings

Account → Notification settings shows a category × channel grid (in-app / push / email), per-suggestion-type toggles, and locked security items. Per-pet mute affects reminders, suggestions and people-update pushes, never security notices. Org-scoped self-management prefs are reached from org people cards (D26–D27).

---

BDD: `notifications.feature` (legacy) + `notifications_v2.feature` · E2E: navigation contract requires bell + panel ready state

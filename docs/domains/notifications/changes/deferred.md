---
title: Notifications deferred work
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-04
tags: [domain,notifications,deferred]
---

# Notifications — deferred work

Open rows: [/docs/debt/debt.md](/docs/debt/debt.md) (filter **Domain = notifications**).

## From Notifications v2 (spec §0, §14)

| Item | Why deferred | Trigger to revisit |
|------|--------------|--------------------|
| In-app quiet hours | Not in the product; OS Focus covers v2 (FR-PU-2) | User demand or push opt-out rising |
| R13 ownership-transfer request + accept | Transfer is immediate in the API today | People spec's two-sided transfer ships |
| "Dot only for needs-response" badge option | Not needed yet | "Inbox opens without action" metric |
| S7 recipients beyond the record owner | N7 | Co-parents report coverage gaps |
| Approximate sign-in location on A1 | Needs DPIA (N13); user decision 2026-10-04: not now | DPIA done + product ask |
| A1 push to other session families | No server push token registry yet; `accountSecurityPush.js` logs only | Push token store + FR-BG-6 refresh payload |
| A4/A5 email-change notices | No email-change flow yet | Email-change feature scheduled |
| Subscription notices A7–A11 (PR8) | No server entitlement source; billing provider undecided | Provider chosen |
| Inbox row hard-delete at 365 days | `audit_events` doesn't yet cover org/sharing/foster (N5) | Audit debt row closed |

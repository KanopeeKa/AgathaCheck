---
title: Notifications domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,notifications]
---

# Notifications

In-app notification feed (Activity / For you), account security notices, Agatha Suggestions, and delivery preferences. Care due/overdue reminders live in Care Actions and device reminders — not the bell inbox (Notifications v2, accepted 2026-10-06).

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Role |
|----------|------|
| [notifications-v2-spec.md](features/notifications-v2-spec.md) | Functional spec (rev 2.5.1), decision log D7–D11 / N1–N13, user journeys (§16), implementation reference (§17), programme index (§19), account security architecture (§20), deferred work (§21) |

## Domains this touches

| Domain | What changes |
|--------|--------------|
| [People](/docs/domains/people/README.md) | D21/D25 reminder routing; R13 transfer request deferred until two-sided transfer |
| [Navigation](/docs/domains/navigation/README.md) | Global bell, slide-over panel (Phase 1) |
| [Subscription](/docs/domains/subscription/README.md) | A7–A11 notices (PR8 blocked on billing provider) |
| [Pet Care](/docs/domains/pet_care/README.md) | Care reminders out of inbox; suggestion cards on pet profile |

## Implementation status (summary)

| Area | Status | Notes |
|------|--------|-------|
| PR1–PR7 rollout | In delivery / shipped per plan | See [§19 programme](features/notifications-v2-spec.md#19-programme--rollout-index) |
| PR8 subscription notices | Blocked | Billing provider + server entitlement source |
| People D21/D25 routing | Planned | [§17](features/notifications-v2-spec.md#17-implementation-reference) |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/notifications/` |
| Node routes | `server/routes/notifications.js` |
| Jest | `notifications.test.js` |
| BDD | `notifications.feature`, `notifications_v2.feature` |
| Playwright E2E | `notifications.spec.ts` |

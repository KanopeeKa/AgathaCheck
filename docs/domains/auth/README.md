---
title: Authentication & profile domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,auth]
---

# Authentication & profile

Sign-up, login, session refresh, password reset, and guardian profile settings.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## Canonical capability

| Document | Contents |
|----------|----------|
| [specs.md](features/specs.md) | Requirements, journeys, session/API rules |

## In-flight

| Document | Role |
|----------|------|
| [plans.md](changes/plans.md) | Plans index |
| [deferred.md](changes/deferred.md) | Deferred work |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/auth/` |
| Node routes | `server/routes/auth/` |
| Jest | `server/test/auth/` |
| BDD | `authentication.feature` |
| Playwright E2E | `auth.login.spec.ts, auth.signup.spec.ts, auth.profile.spec.ts` |

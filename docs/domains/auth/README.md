---
title: Authentication & profile domain
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,auth]
---

# Authentication & profile

Sign-up, login, session refresh, password reset, and guardian profile settings.

Part of the AgathaTrack domain-first documentation tree. Cross-cutting architecture: [/docs/architecture/index.md](/docs/architecture/index.md).

## On this domain

| Section | Link |
|---------|------|
| User journeys | [features/journeys.md](features/journeys.md) |
| Implementation specs | [features/specs.md](features/specs.md) |
| Plans index | [changes/plans.md](changes/plans.md) |
| Deferred work | [changes/deferred.md](changes/deferred.md) |

## Code map

| Layer | Path |
|-------|------|
| Flutter | `flutter_app/lib/features/auth/` |
| Node routes | `server/routes/auth/` |
| Jest | `server/test/auth/` |
| BDD | `authentication.feature` |
| Playwright E2E | `auth.login.spec.ts, auth.signup.spec.ts, auth.profile.spec.ts` |

---
title: Auth feature
owner: Platform team
status: active
component_id: flutter.feature.auth
last_updated: 2026-10-06
last_reviewed: 2026-10-06
---

# Purpose

Sign-in, sign-up, session, and account profile entry. **Non-goals:** subscription billing, sharing invites, or shell navigation (owned by `experience`).

## Public entrypoint

`package:pet_profile_app/features/auth/auth.dart`

## Public surface

| Symbol | Kind | Reason |
|--------|------|--------|
| `AuthUser`, `AuthResult`, `DeleteAccountResult` | domain entities | Cross-feature identity |
| `AuthRepository`, `SessionStore` | domain ports | Test overrides and analytics |
| `authStateProvider` and related | application providers | Session gate for features |
| `auth_providers.dart` re-export | provider barrel | Legacy import path |
| `LandingScreen`, `LoginScreen`, `SignupScreen`, `ForgotPasswordScreen`, `MyDetailsScreen` | UI screens | Router destinations |

## Dependencies

| Allowed | Forbidden |
|---------|-----------|
| `core/network`, `core/theme`, `experience` public API for branding context only | `data/` implementations from other features |

## Side effects & freshness

Persists tokens via `SessionStore`; refresh via `AuthHttpClient`. Session is source of truth until logout.

## Permissions

Account lifecycle APIs; maps `SessionExpiredException` in data layer.

## Tests

`flutter_app/test/features/auth/`

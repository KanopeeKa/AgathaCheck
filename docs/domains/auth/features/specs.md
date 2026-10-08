---
title: Authentication specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [domain,auth,specs]
domain: auth
feature_id: authentication
---

# Authentication

Sign-up, login, session refresh, password reset, and guardian profile settings (`authentication.feature`, `auth.*.spec.ts`).

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| **AUTH-1** | Pet carers register with email and password (minimum six characters) with validation for format, mismatch, duplicate email, and password rules. | delivered |
| **AUTH-2** | Email/password login with clear errors for unknown email and incorrect password; password visibility toggle on login. | delivered |
| **AUTH-3** | Log out ends the session; subsequent API calls require re-authentication. | delivered |
| **AUTH-4** | Profile view and update from the account/profile screens. | delivered |
| **AUTH-5** | Unauthenticated shell links login ↔ sign-up. | delivered |

## User journeys

### Sign up

Pet carers register with email and password (minimum six characters). Validation covers mismatched passwords, missing email, invalid email format, duplicate email, and password rules.

### Log in

Email/password login with incorrect-password and unknown-email errors. Password visibility toggle on the login form.

### Log out

Session ends from the app; subsequent API calls require re-authentication.

### Profile

View account details and update profile fields from the profile screen.

### Navigation between auth screens

Login ↔ sign-up navigation links on the unauthenticated shell.

## Session and tokens

- Access tokens are short-lived; refresh handled centrally in `authHttpClientProvider` (see lesson: auth token refresh).
- JWT signing secret: `server/config/jwtSecret.js` — prod requires `JWT_SECRET` or `SESSION_SECRET`; non-prod uses load-bearing `default_secret` fallback for CI (see lesson: jwt-secret-dev-fallback).

## Node routes

Canonical auth API under `server/routes/auth/` (session, profile, password modules).

## Error handling

Session expiry surfaces as `SessionExpiredException` → login redirect with SnackBar — datasources must not bypass the shared HTTP client.

## Engineering rules

- All authenticated HTTP must use `authHttpClientProvider`; multipart uploads must use `client.send()` — see [.agents/memory/auth-token-refresh.md](/.agents/memory/auth-token-refresh.md).
- Non-prod `default_secret` JWT fallback is load-bearing for Jest/CI — do not throw unconditionally when unset — see [.agents/memory/jwt-secret-dev-fallback.md](/.agents/memory/jwt-secret-dev-fallback.md).

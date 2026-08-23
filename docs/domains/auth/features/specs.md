---
title: Authentication specs
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain,auth,specs]
domain: auth
---

# Authentication specs

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

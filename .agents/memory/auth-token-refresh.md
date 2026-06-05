---
name: Auth token refresh + retry
description: Durable rules for keeping authenticated API calls alive across access-token expiry in the Flutter app
---

# Authenticated HTTP must refresh + retry in ONE shared client layer

**Rule:** Every authenticated remote datasource must go through the shared auth
`http.Client` wrapper (provided via `authHttpClientProvider`). Never read the
access token from prefs or build raw `http.*` / `request.send()` calls in feature
code.

**Why:** Access tokens are short-lived; idle users hit 401 mid-session. Centralizing
token injection + single-flight refresh + one-shot retry in the client is the only
place that guarantees *all* calls (including multipart uploads) survive expiry and
fail gracefully (`SessionExpiredException` → `AuthState.sessionExpired` → SnackBar +
login redirect). Scattered token plumbing silently rots — a real bug existed where
code read the wrong prefs key and was unauthenticated, and a multipart upload called
`request.send()` directly and bypassed refresh entirely.

**How to apply when adding/auditing a datasource:**
- Wire `client: ref.watch(authHttpClientProvider)` into its provider.
- For multipart, call `client.send(request)` — NOT `request.send()`.
- Guardrail grep when reviewing: `request\.send\(\)` and raw `http.(get|post|put|delete)\(`
  should return nothing in authenticated feature datasources.

**Keep the refresher itself unwrapped:** the auth/login/refresh service uses a plain
client, or a refresh 401 would recurse.

**Datasources must auth EVERY method, not just reads:** the health datasource set the
Bearer header only on `getEntries` (GET) and omitted it on `createEntry`/`update`/`delete`/
`markTaken`/uploads. Deployed builds then POSTed with no `Authorization` → 401 (server was
fine: routes already insert `user_id` from JWT). Fix = a `_authHeaders({jsonBody})` helper
applied to all methods. When auditing, check writes + multipart, not just the list call.

**Quirk:** `AppLocalizations.of(context)` is NULLABLE in this project — use `!`.

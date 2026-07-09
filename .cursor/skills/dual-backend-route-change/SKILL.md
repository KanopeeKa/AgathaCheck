---
name: dual-backend-route-change
description: Add or change an HTTP API route with Node (canonical) + Dart Shelf parity, Jest tests, and calendar-date wire format. Use for new endpoints, request validation, auth guards, or status-code changes.
paths:
  - server/routes/**
  - server/lib/**
  - server/test/**
---

# Dual-backend route change

Node Express is **canonical** (fully tested). Dart Shelf must mirror HTTP behaviour.

## Checklist (same PR)

- [ ] Route path + HTTP method (Node + Dart)
- [ ] Auth / role guards
- [ ] Request body validation
- [ ] Response JSON shape
- [ ] Status codes (incl. 501 stubs where deferred)
- [ ] Calendar date fields as `YYYY-MM-DD` (`calendarDate.js` / `calendar_date.dart`)
- [ ] `router.use(createApiLimiter())` in route composer (not auth routes using `createAuthLimiter`)
- [ ] Jest test in mirrored `server/test/<domain>/`
- [ ] `dart analyze lib` clean on `server/`
- [ ] No raw `err.message` / `e.toString()` / `$e` in 5xx bodies — use `publicError()` / `errorDetails()`

## File layout

```
server/routes/<domain>/
  index.js          # composer; mount static before /:id
  <area>Router.js
server/test/<domain>/
  <area>.test.js
server/lib/
  <domain>_routes.dart  # or split when >500 lines
```

## Steps

1. Read existing domain: `docs/architecture/index.md` + current route module.
2. Implement Node handler + tests first (supertest + mock pool).
3. Mirror Dart route handler; share validation patterns from `server/lib/validation.dart`.
4. If Flutter consumes the endpoint, update repository/datasource in matching `flutter_app/lib/features/<feature>/`.
5. **Verify:**
   ```bash
   cd server && npx jest --env=node --forceExit test/<domain>/
   cd server && dart analyze lib
   node scripts/check_file_size.js
   ```

## Known Dart-only gaps (document, do not block)

- Audit logging — Node only (`docs/technical-debt.md`)
- PostHog person delete — Node only

## Domain memories

- Org body `organization_id`: `.agents/memory/body-supplied-org-id-validation.md`
- Health completion: `.agents/memory/health-entry-completion.md`
- Auth HTTP client: `.agents/memory/auth-token-refresh.md`

## Defer parity

If intentionally stubbing 501 in Dart, note in PR + `docs/refactoring-debt.md`.

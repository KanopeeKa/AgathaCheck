---
name: single-backend-route-change
description: Add or change an HTTP API route with Node.js (canonical), Jest tests, and calendar-date wire format. Use for new endpoints, request validation, auth guards, or status-code changes.
paths:
  - server/routes/**
  - server/test/**
---

# Single-backend route change

Node Express is the **only** backend (fully tested).

## Checklist (same PR)

- [ ] Route path + HTTP method
- [ ] Auth / role guards
- [ ] Request body validation
- [ ] Response JSON shape
- [ ] Status codes
- [ ] Calendar date fields as `YYYY-MM-DD` (`calendarDate.js`)
- [ ] `router.use(createApiLimiter())` in route composer (not auth routes using `createAuthLimiter`)
- [ ] Jest test in mirrored `server/test/<domain>/`
- [ ] No raw `err.message` / `e.toString()` / `$e` in 5xx bodies — use `publicError()` / `errorDetails()`

## File layout

```
server/routes/<domain>/
  index.js          # composer; mount static before /:id
  <area>Router.js
server/test/<domain>/
  <area>.test.js
```

## Steps

1. Read existing domain: `docs/architecture/index.md` + current route module.
2. Implement Node handler + tests first (supertest + mock pool).
3. If Flutter consumes the endpoint, update repository/datasource in matching `flutter_app/lib/features/<feature>/`.
4. **Verify:**
   ```bash
   cd server && npx jest --env=node --forceExit test/<domain>/
   node scripts/check_file_size.js
   ```

## Domain memories

- Org body `organization_id`: `.agents/memory/body-supplied-org-id-validation.md`
- Health completion: `.agents/memory/health-entry-completion.md`
- Auth HTTP client: `.agents/memory/auth-token-refresh.md`

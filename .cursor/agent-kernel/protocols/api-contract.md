# Protocol: api-contract

**When:** API request/response behaviour changes, new endpoints, mobile client impact.

**Replaces guidance from:** `single-backend-route-change` skill (internal), `.cursor/rules/single-backend.mdc`.

**Reference:** `docs/architecture/api-reference.md`, `docs/architecture/calendar-dates.md`.

---

## 1. Inspect

- Existing route module and composer order (static before `/:id`)
- Flutter repository/datasource consumers
- Installed mobile clients — **cannot be force-upgraded** with backend

## 2. Same-PR checklist (behaviour change)

- [ ] Route path + HTTP method
- [ ] AuthN + AuthZ (see `authorization.md`)
- [ ] Request validation (`validation.md`)
- [ ] Response DTO shape — no indiscriminate DB row serialization
- [ ] Status codes + standardized errors (`publicError`)
- [ ] Calendar dates as `YYYY-MM-DD` on wire (`calendarDate.js`)
- [ ] `router.use(createApiLimiter())` in route composer
- [ ] Jest in `server/test/<domain>/`
- [ ] Flutter client update if consumed

## 3. Compatibility

- Prefer **additive** evolution (new fields optional, new endpoints)
- Breaking changes → version bump, migration plan, or halt (escalation)
- Pagination for large lists
- Explicit date/time semantics (`date-time.md`)

## 4. OpenAPI

Update OpenAPI/docs when the repo maintains them for the touched surface. **Agent-required**; CI may not enforce yet.

## 5. File layout

```
server/routes/<domain>/
  index.js
  <area>Router.js
server/test/<domain>/
  <area>.test.js
```

## 6. Verification

```bash
cd server && npx jest --env=node --forceExit test/<domain>/
./scripts/pre-push-changed.sh
```

---
name: single-backend-route-change
description: >-
  INTERNAL (Tier 3) — superseded by Router protocols api-contract + validation +
  authorization. Do not user-invoke; use /babysit-plus or /execute-plan with Router.
paths:
  - server/routes/**
  - server/test/**
---

# Single-backend route change (internal — Tier 3)

> **Superseded by:** `.cursor/agent-kernel/protocols/api-contract.md`, `validation.md`, `authorization.md`  
> **Framework:** `docs/engineering/cursor-agent-framework.md`

Node Express is the **only** backend. Router loads API protocols when route behaviour changes.

## Canonical checklist

See `protocols/api-contract.md` — route path, AuthN/AuthZ, validation, response DTO, status codes, `YYYY-MM-DD` dates, rate limiter, Jest tests, no 5xx leaks.

## File layout

```
server/routes/<domain>/
  index.js
  <area>Router.js
server/test/<domain>/
  <area>.test.js
```

## Verify

```bash
cd server && npx jest --env=node --forceExit test/<domain>/
./scripts/pre-push-changed.sh
```

## Domain memories

- Org body `organization_id`: `.agents/memory/body-supplied-org-id-validation.md`
- Health completion: `.agents/memory/health-entry-completion.md`
- Auth HTTP client: `.agents/memory/auth-token-refresh.md`

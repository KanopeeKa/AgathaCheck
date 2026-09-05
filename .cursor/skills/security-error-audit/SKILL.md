---
name: security-error-audit
description: >-
  INTERNAL (Tier 3) — superseded by Router protocol security.md §5xx audit. Do not
  user-invoke; Router loads when server routes change.
paths:
  - server/**
---

# Security error-leak audit (internal — Tier 3)

> **Superseded by:** `.cursor/agent-kernel/protocols/security.md` §5xx audit  
> **Framework:** `docs/engineering/cursor-agent-framework.md`

## Rule

**Never** return raw `err.message`, `e.toString()`, or `'$e'` in production **5xx** JSON bodies. Use `publicError()` / `errorDetails()` from `server/config/security.js`.

## Grep

```bash
rg "err\.message|e\.toString\(\)|\$\{?e\}?|details:\s*err" server/routes server/lib --glob '*.js'
```

## Verify

```bash
cd server && npx jest --env=node --forceExit
```

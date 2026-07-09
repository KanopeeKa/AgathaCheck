---
name: security-error-audit
description: Audit API error responses for raw exception leaks on Node and Dart backends. Use before security review, after route changes, or when fixing 5xx error handling.
paths:
  - server/**
---

# Security error-leak audit

## Rule

**Never** return raw `err.message`, `e.toString()`, or `'$e'` in production **5xx** JSON bodies.

Use `publicError()` / `errorDetails()` from:
- `server/config/security.js`
- `server/lib/http_security.dart`

## Grep patterns (both backends)

Run all four — one pattern misses sites:

```bash
# Node
rg "err\.message|e\.toString\(\)|\$\{?e\}?|details:\s*err" server/routes server/lib --glob '*.js'

# Dart
rg "e\.toString\(\)|'\$e'|\"\$e\"|details.*\$e" server/lib --glob '*.dart'
```

Also grep inside `res.json(` / `jsonEncode` error bodies.

## Fix pattern

Replace raw exception text with `publicError(err)` (Node) or `publicError(e)` (Dart) in client-facing 5xx responses.

## Leave alone

- `console.error`, `print('... $e')` — server-side logs, not client responses.
- Non-prod detail is intentional for Jest/dev; redaction gates on `NODE_ENV=production`.

## Verify

```bash
cd server && npx jest --env=node --forceExit
cd server && dart analyze lib
```

Full patterns: `.agents/memory/error-leak-redaction-patterns.md`

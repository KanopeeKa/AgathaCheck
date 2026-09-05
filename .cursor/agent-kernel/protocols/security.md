# Protocol: security

**When:** AuthN/session, secrets, sensitive data, public endpoints, uploads, sharing abuse, security bugs.

**Ambient rule:** `.cursor/rules/security.mdc` (path-scoped on `server/**`).

**Memories:** `.agents/memory/jwt-secret-dev-fallback.md`, error-leak patterns in `.agents/memory/MEMORY.md`.

---

## 1. Inspect

- Auth middleware and token handling (`server/routes/auth/`, session refresh)
- Route composers for rate limiting (`createAuthLimiter`, `createApiLimiter`)
- Error responses on modified routes
- Upload handlers and file storage entry points
- Public/unauthenticated endpoints

## 2. Invariants

- One authoritative AuthN mechanism — no ad-hoc token parsing in handlers
- Access/refresh purpose separation; secrets/tokens never logged
- External input validated (see `validation.md`)
- Production 5xx: `publicError()` / `errorDetails()` — never raw `err.message`, `e.toString()`, `$e`
- Sensitive files private by default (see `private-files.md`)
- Public endpoints: data minimization
- No security through obscurity (opaque URLs ≠ authorization)
- Passwords: bcrypt; JWT via jsonwebtoken

## 3. Threat checklist

- [ ] IDOR/BOLA on object IDs
- [ ] Privilege escalation (role/capability changes)
- [ ] Insecure defaults (open by default, missing AuthZ)
- [ ] Sensitive fields in responses or logs
- [ ] Path traversal / unconstrained file access
- [ ] Missing rate limits on auth/sensitive routes
- [ ] Dependency advisories (high+ blocked in CI)

## 4. 5xx leak audit (route changes)

```bash
rg "err\.message|e\.toString\(\)|\$\{?e\}?|details:\s*err" server/routes server/lib --glob '*.js'
```

## 5. Tests / verification

- Security bug → **negative regression test** required
- Auth-sensitive routes → exercise forbidden actor (see `authorization.md`)
- `cd server && npx jest` for touched domains
- `npm audit` in `server/` and `e2e/` before push

## 6. Documentation

R3 or new security model → ADR or domain doc update (`documentation.md`).

---
name: JWT secret dev/test fallback is load-bearing for CI
description: Why the 'default_secret' fallback must survive even after prod hardening
---
The JWT signing secret is resolved in one shared module (`server/config/jwtSecret.js`): `JWT_SECRET || SESSION_SECRET`, throwing only when `NODE_ENV=production`.

**Rule:** keep the non-production `'default_secret'` fallback. Do NOT make the throw unconditional.

**Why:** all 9 Jest suites sign their own test tokens with the same `JWT_SECRET || SESSION_SECRET || 'default_secret'` chain, and `.github/workflows/*` set NO JWT/SESSION secret. An unconditional throw (or a different fallback value) crashes module import in CI / breaks token verification. The fallback value must stay exactly `'default_secret'` to match the tests.

**How to apply:** if asked to "remove the insecure default entirely," either keep the prod-gated fallback, or also inject a secret into the CI/jest env AND update all 9 test files' signing key in lockstep.

---
name: Error-leak redaction must cover ALL exception-exposure patterns
---
When redacting raw exception text from client error responses, a single grep pattern will miss sites. The Node backend uses multiple styles:

- **Node** (`server/routes/*.js`): `error: err.message`, `error: \`Prefix: ${err.message}\`` (template), and `details: err.message`.

**Rule:** before claiming error-leak redaction is complete, grep for the full set — `err.message`, `e.toString()`, `$e`, and `details` — inside `res.json` bodies. Use `publicError()` / `errorDetails()` from `server/config/security.js`.

**Why:** a first pass redacted only `err.message`/`details` in Node and missed every `\`Error: ${err.message}\`` template site (5+ route files still leaked in prod) — caught only by code review, not the initial grep.

**Note:** `console.error` are server-side logs, not client responses — leave them. Redaction is gated on `NODE_ENV=production`; non-prod (incl. Jest) keeps full detail so tests asserting dev-style error strings still pass.

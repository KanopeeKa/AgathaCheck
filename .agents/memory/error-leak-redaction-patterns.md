---
name: Error-leak redaction must cover ALL exception-exposure patterns per backend
description: The Node/Dart backends expose raw exception text via several distinct syntaxes; grepping one misses the rest
---
When redacting raw exception text from client error responses, a single grep pattern will miss sites. Both backends use multiple styles:

- **Node** (`server/routes/*.js`): `error: err.message`, `error: \`Prefix: ${err.message}\`` (template), and `details: err.message`.
- **Dart** (`server/lib/*.dart`): `'error': e.toString()` AND `'error': 'Prefix: $e'` (string interpolation) AND `'details': '$e'`.

**Rule:** before claiming error-leak redaction is complete, grep for the full set — `err.message`, `e.toString()`, `$e`, and `details` — inside `jsonEncode`/`res.json` bodies, on BOTH backends. Keep `server/config/security.js` and `server/lib/http_security.dart` (publicError/errorDetails) in lockstep.

**Why:** a first pass redacted only `e.toString()`/`details` in Dart and missed every `'Error: $e'` interpolation site (5+ route files still leaked in prod) — caught only by code review, not the initial grep.

**Note:** `print('... $e')` are server-side logs, not client responses — leave them. Redaction is gated on `NODE_ENV=production`; non-prod (incl. Jest) keeps full detail so tests asserting dev-style error strings still pass.

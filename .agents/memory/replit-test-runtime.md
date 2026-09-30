---
name: Replit local test runtime
description: PostgreSQL lifetime, Nix browser libraries, and differences between locally bundled Flutter resources and CI's CDN resources.
---

Run a disposable PostgreSQL instance as a foreground process in a persistent
background task or managed service, not merely as a `pg_ctl start` child of a
one-off shell.

**Why:** Shell cleanup can terminate the detached database after the setup
command succeeds, making later tests unexpectedly report connection refused.

**How to apply:** Use a separate local port and database for validation, remove
inherited `DATABASE_URL` from test commands, and keep the server task alive
until verification finishes. Never redirect these tests at the project's live
database.

Use the Chromium version installed by the locked Playwright package. On Nix,
the downloaded browser may lack runtime library resolution even though the
system Chromium works.

**Why:** The downloaded matching browser needed Nix's `libgbm`, `libxkbcommon`
and ALSA library directories. Replacing it with the older system browser would
change the test environment rather than resolve the missing libraries.

**How to apply:** Inspect missing libraries with `ldd`; obtain their installed
paths from the system Chromium executable's dependencies and supply them
through the test process's library path. Avoid recursive searches or broad
globs over the entire Nix store, which can be unexpectedly slow here. Keep
machine-specific paths out of committed Playwright configuration.

Scope test-clock headers to same-origin backend API requests, never global
browser headers.

**Why:** The local Flutter build bundles rendering assets to avoid blocked
egress, while CI loads assets from a CDN. A global custom header reaches the
CDN and can break cross-origin loading before Flutter mounts, even though the
same test passes against locally bundled assets.

**How to apply:** Test both API inclusion and external/static-resource
exclusion. Preserve other request headers and route handlers when setting or
clearing a test clock; do not increase boot timeouts to conceal header leakage.

Keep required PostgreSQL regression tests strict when their database is absent.

**Why:** A database-free unit CI job is not evidence for mandatory transaction
or concurrency coverage. Making DB tests silently pass hides missing coverage.

**How to apply:** Separate the unit-only job from the DB-backed job and full
local verification, rather than weakening required DB test prerequisites.
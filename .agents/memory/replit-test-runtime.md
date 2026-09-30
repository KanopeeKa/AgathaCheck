---
name: Replit local test runtime
description: Process lifetime and Nix library constraints when running real PostgreSQL and matching Playwright browsers locally.
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
---
name: Mockup sandbox registration
description: How to recover when a design worker leaves mockup component files without a registered sandbox artifact.
---

A folder under `artifacts/mockup-sandbox/` alone does not make its `/__mockup/` canvas route runnable. Before relying on a mockup frame, verify that the matching managed artifact and its Component Preview Server workflow exist.

**Why:** A design worker can create a component and set a canvas frame live before the Vite sandbox is registered. The primary app then serves the route fallback, making the frame display the main app instead of the mockup.

**How to apply:** Do not delete an incomplete sandbox folder without the user's consent. Register a clean managed sandbox with the required preview path, install its declared dependencies in that artifact directory, start its workflow, then copy the isolated mockup component into the managed sandbox and repoint only the reserved frame.

## Nested package and build hygiene

Treat each managed mockup sandbox as its own package root. If the package helper cannot target a nested artifact and the execution sandbox cannot change its working directory, use the artifact's own lockfile-aware package command from that directory rather than creating a root package.

**Why:** Nested artifact dependencies can otherwise be installed into the wrong package, and a default production build can replace tracked hashed files under `dist/`, leaving unrelated generated changes in a PR.

**How to apply:** Keep dependency changes confined to the artifact's `package.json` and lockfile. Direct verification builds to a temporary output directory when possible. After delegated reviews or builds, check `git status` for `dist/` changes and restore/clean generated output before committing.
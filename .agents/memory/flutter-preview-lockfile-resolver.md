---
name: Flutter preview lockfile resolver
description: Preview launcher lockfile guard and resolver behavior in this workspace.
---

The preview launcher refuses to build when `flutter_app/pubspec.lock` is dirty. Its managed Flutter toolchain may deterministically resolve a small set of transitive packages differently from a local test toolchain, causing a later restart to be blocked by the guard.

**Why:** A stale/incompatible Flutter test invocation rewrote the lockfile after validation. The preview launcher then correctly declined to overwrite a dirty lockfile before running its build.

**How to apply:** Before restarting the preview after Flutter tooling work, confirm the lockfile is clean. If the managed preview resolver consistently writes a particular transitive resolution, commit that stable resolution rather than repeatedly restoring a conflicting local one. Avoid concurrent Flutter commands while launching the preview.
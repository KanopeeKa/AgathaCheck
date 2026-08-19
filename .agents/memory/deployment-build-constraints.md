---
name: Deployment build constraints
description: Publishing prerequisites for this Flutter app with nested server dependencies.
---

Publishing expects a root-level private Node manifest even when the application dependencies live under `server/`; the root manifest may remain dependency-free.

**Why:** The publishing security scan installs from the repository root before running the configured build and fails immediately when `package.json` is absent.

**How to apply:** Keep the root manifest aligned with the empty root lockfile, and keep server dependency installation explicitly scoped to `server/`.

The publishing image may expose Flutter 3.32/Dart 3.8 while the app requires Dart 3.12 or newer; the local preview uses a pinned Flutter 3.44 bootstrap.

**Why:** The default image can fail `flutter pub get` before any application code is compiled.

**How to apply:** Do not lower the app SDK constraint; publishing must use a compatible pinned Flutter toolchain before its build command can succeed.
---
name: Replit Flutter preview compatibility
description: How to handle design validation when the development Flutter SDK is older than the app's declared Dart requirement.
---

The local Replit environment may expose Flutter 3.32 / Dart 3.8 while this app requires Dart 3.12 or later. In that state, local `pub get`, analysis, and web builds cannot validate changed Flutter source. A downloaded CI web artifact is useful only as a clearly labelled historical visual baseline.

**Why:** Reusing an existing generated bundle can make the running preview appear healthy while it silently excludes the source changes being reviewed. That creates false visual sign-off, especially for UI phases.

**How to apply:** Check the installed Flutter/Dart version against `flutter_app/pubspec.yaml` before claiming visual validation. If they are incompatible, request approval for a compatible preview/toolchain workflow or use CI to build the branch; do not modify workflow configuration or hand-edit generated web output without explicit user approval.

When Flutter 3.44 runs `pub get` here, it temporarily resolves several SDK-pinned transitive packages to older versions than the tracked lockfile. A local preview bootstrap must restore a clean lockfile after the build, including on a failed build.

**Why:** A visual-preview command must not silently create dependency changes that look ready to commit, especially when they come from Flutter's SDK constraints rather than a deliberate package update.

**How to apply:** Treat the lockfile as immutable in preview-only tooling. Refuse to run if it already has uncommitted edits, back it up before `pub get`, and restore it after the build.
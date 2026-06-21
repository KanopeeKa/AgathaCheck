---
name: Flutter pub cache "Undefined name 'Matrix4'" quirk
description: flutter test failing inside the SDK's own painting library means the pub cache is stale, not a code bug — run flutter pub get first.
---

When `flutter test` (in `flutter_app/`) fails to compile with errors like
`Undefined name 'Matrix4'` / `Method not found: 'Vector4'` pointing **inside the Flutter
SDK itself** (e.g. `packages/flutter/lib/src/painting/matrix_utils.dart`,
`star_border.dart`), this is **not** a bug in the test or app code.

**Cause:** the pub cache / package resolution is incomplete — `vector_math` (which
provides `Matrix4`/`Vector4`) is unresolved.

**Fix:** run `cd flutter_app && flutter pub get`, then re-run the tests. They compile cleanly.

**Also:** the very first `flutter test` invocation after a fresh checkout/cache can take
well over a minute to compile and may exit with no output if the tool timeout is too low —
give it the max timeout and re-run rather than assuming a real failure.

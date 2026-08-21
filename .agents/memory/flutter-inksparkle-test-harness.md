---
name: Flutter InkSparkle test harness
description: Prevent managed Flutter shader-version mismatches from masking widget interaction tests.
---

When the managed Flutter test environment fails to decode
`shaders/ink_sparkle.frag` after `tester.tap` on a Material `InkWell`, set
`splashFactory: NoSplash.splashFactory` on the **test-only** `MaterialApp`
theme. Keep the production theme unchanged.

**Why:** The failure is an environment shader-manifest compatibility problem
rather than an application callback failure; it prevents real interaction
assertions from executing.

**How to apply:** Add the splash override only to the focused widget-test
builder that triggers the failure, then retain normal tap/semantics assertions
against the real widget callbacks and state transitions.
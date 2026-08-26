---
name: Canvas versus app preview
description: Distinguishes the live canvas iframe from the main application preview during visual iteration.
---

Treat a selected canvas iframe and the main application Preview as separate render targets. Confirm the selected shape's component path before editing; when discarding a mockup direction, remove both its canvas shape and its artifact source/registration.

**Why:** Both previews can be visible in the same workspace, but changes to one do not affect the other. Editing the wrong surface creates misleading visual verification and leaves discarded variants behind.

**How to apply:** Use the canvas state for the selected iframe, use the main workflow for the application Preview, and verify both the board and artifact source when a design direction is removed.
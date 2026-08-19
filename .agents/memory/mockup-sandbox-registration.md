---
name: Mockup sandbox registration
description: How to recover when a design worker leaves mockup component files without a registered sandbox artifact.
---

A folder under `artifacts/mockup-sandbox/` alone does not make its `/__mockup/` canvas route runnable. Before relying on a mockup frame, verify that the matching managed artifact and its Component Preview Server workflow exist.

**Why:** A design worker can create a component and set a canvas frame live before the Vite sandbox is registered. The primary app then serves the route fallback, making the frame display the main app instead of the mockup.

**How to apply:** Do not delete an incomplete sandbox folder without the user's consent. Register a clean managed sandbox with the required preview path, install its declared dependencies in that artifact directory, start its workflow, then copy the isolated mockup component into the managed sandbox and repoint only the reserved frame.
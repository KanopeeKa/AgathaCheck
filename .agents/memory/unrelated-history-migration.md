---
name: Unrelated-history migration
description: How to reconcile an orphaned product branch with the current trunk without creating an unrelated-history merge.
---

When a feature branch and trunk have no Git merge base but their trees share a reviewed conceptual snapshot, use that snapshot as an explicit three-way merge base, preserve the old tip for auditability, and create a normal single-parent migration commit on current trunk.

**Why:** An unrelated-history merge hides whether the product delta was actually reviewed and leaves branch topology unsuitable for ordinary PR ancestry checks.

**How to apply:** Compare the conceptual base, current trunk, and feature tip; resolve only true content conflicts in favor of the reviewed feature or current-trunk behavior as appropriate; verify trunk is an ancestor of the new tip.
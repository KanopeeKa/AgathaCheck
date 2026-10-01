---
name: Care dose selection compatibility
description: Why absence of missed doses does not eliminate same-day dose selection, and which browser regressions must be paired.
---

The legacy dose selector is not exclusively a missed-dose review. Multiple
pending doses on the same calendar day intentionally use it even before their
scheduled times. One current-day occurrence plus a future-day occurrence instead
uses the established completion-date confirmation and reversible inline Undo.
Completed history must not determine which interaction opens.

**Why:** Counting all pending occurrences broke ordinary dashboard completion
when the schedule engine supplied a future head. Restricting selection to missed
doses fixed that scenario but broke the existing future-timed, same-day multi-dose
interaction. Broad backend and Flutter checks passed while the browser paths
exposed this difference.

**How to apply:** Verify both real browser paths together on a fresh source build
when changing compatibility routing. Check the exact selected current-day dose,
preserve future doses, and retain genuine missed-dose LIFO behavior. Do not
weaken the multi-dose assertions or bypass required server-side next-date choices
to make one of these paths pass.
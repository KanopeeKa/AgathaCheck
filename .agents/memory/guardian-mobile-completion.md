---
name: Pet Care mobile completion
description: Approved behavior for reversible mobile completion in the Pet Care due-events preview.
---

On Pet Care phone-width due-event rows, retain a completed item in its original
five-item preview position with an inline Undo action after the user confirms
the existing completion-date sheet. The temporary completed presentation belongs
to the list, not an individual row, so it survives the provider refresh.

**Why:** The approved mobile direction needs a visible, reversible completion
state without replacing established completion-date and server-sync semantics.
The server remains the source of truth; a transient provider loading state must
not make the approved confirmation disappear.

**How to apply:** Keep this treatment below the mobile breakpoint only. Cache
the last server-derived due preview solely while an in-flight refresh is loading;
do not write cached or optimistic records back on ordinary reads. Remove the
temporary completed item only after a successful Undo, and leave desktop/tablet
due-event cards unchanged.

**Legacy filename:** `guardian-mobile-completion.md` — workspace renamed to Pet Care (D38).

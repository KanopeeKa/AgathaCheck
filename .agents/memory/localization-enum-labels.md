---
name: Localization audits must cover enum .label getters
description: When "fully localizing" a screen, hardcoded English hides in enum .label getters used by dropdowns/displays, not just inline widget literals.
---

When asked to fully localize a Flutter screen, replacing inline string literals is
not enough. Domain enums (e.g. `HealthEntryType`, `HealthFrequency` in
`health_entry.dart`) expose `String get label` getters that return **hardcoded
English**. Any dropdown item, filter, or display built from `enum.label` renders
English even after the screen's own literals are localized.

**Why:** These getters live in the domain layer, far from the presentation code
being audited, so a grep of the screen file alone misses them. A reviewer caught
this exact miss after the screen's ~40 literals were already localized.

**How to apply:** During a localization pass, grep the screen for `.label` (and
similar enum-derived getters) and map each enum value to an `AppLocalizations` key
via a small `_xLabel(l, value)` helper in the screen. Add any missing ARB keys in
**both** en and fr. Most enum-label keys may already exist in the ARBs (e.g.
`medication`, `doesNotRepeat`); only add the genuinely missing ones. Guard against
regression with a widget test asserting the localized option text in both locales.
Related pitfall: enum `.name` is minified in release builds — never use `.name`.

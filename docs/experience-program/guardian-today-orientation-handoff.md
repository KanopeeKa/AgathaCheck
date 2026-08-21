# Guardian Today orientation handoff

`GuardianTodayOrientation` is the compact, provider-free orientation layer for
the Guardian home. It is not a dashboard section, route, care list, or
management surface.

## Constructor contract

```dart
GuardianTodayOrientation(
  state: GuardianTodayScreenState,
  summary: GuardianTodayCareSummary?,
  onRetry: VoidCallback?,
)
```

- Pass the state and summary already derived by the Guardian Today presentation
  foundation; do not watch providers or rebuild care priority rules inside the
  widget.
- `summary` is required for `attention` and `allClear`. Missing summary data
  deliberately resolves to the `partial` visual state instead of showing
  invented counts.
- Pass `onRetry` only where the composing layer owns a refresh action. The
  component does not know about providers or routing.

## Integration rules

- Compose it once above the three Guardian management sections.
- Keep it compact; it surfaces grouped overdue, due-today, and upcoming counts
  but never renders individual care rows.
- Its root exposes one grouped semantic summary. Decorative icons and visual
  count pills are excluded from screen-reader traversal.
- The retry control is the only interactive element and retains a 48dp target.
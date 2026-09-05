# Protocol: accessibility

**When:** Meaningful Flutter UI changes, forms, interactive controls, navigation.

**Ambient rules:** `.cursor/rules/accessibility.mdc`, `.cursor/rules/design.mdc`.

**Supersedes:** `/ui-check` skill (Tier 3 internal) — use this protocol instead.

---

## 1. Deep review checklist

- Semantic labels on inputs and icon-only buttons (tooltips)
- Keyboard navigation and **visible focus** on web
- Contrast and readable scaling
- Touch targets ≥ **48×48** logical px
- Status not conveyed by color alone
- Error communication accessible to screen readers
- Loading/state announcement where appropriate
- `MergeSemantics` / `Semantics(identifier:)` when tree insufficient

## 2. Quick pass (ex-`/ui-check`)

For single-screen PR polish — **≤5 minutes**:

1. Purpose clear in 5 seconds?
2. Primary action obvious?
3. Labels on inputs; focus visible; touch ≥48dp
4. Theme/`colorScheme` — no ad-hoc colors
5. Empty/loading/error still reasonable?
6. Auth/landing: role-neutral entry if touched

Escalate to `/ui-design-deep` for theme, landing/auth, multi-screen, or `/g/*` + `/o/*` span.

## 3. E2E

Playwright: `enableFlutterAccessibility()` before interact; axe on `@smoke-a11y` tier.

## 4. Verification

`./scripts/pre-push-changed.sh` when code changed.

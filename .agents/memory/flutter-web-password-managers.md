---
name: Flutter web password-manager autofill
description: Why browser password-manager extensions can't autofill Flutter web fields, and the native-HTML-form bridge fix.
---

# Password-manager extensions vs. Flutter web (CanvasKit)

Flutter web's default CanvasKit renderer (and skwasm) paints text fields onto a
`<canvas>`. The real `<input>` elements are only created transiently on focus,
so the displayed value lives on the canvas, not in the DOM.

- **Browser-native autofill works** (Chrome/Firefox hook the editing engine at a
  low level).
- **Extension password managers fail** (Proton Pass, Bitwarden, 1Password) —
  they scan the DOM for visible email/password inputs at load and on mutation,
  and there are no persistent form fields for them to attach to.
- `AutofillGroup` + `Form` + `autofillHints` are correct and necessary but do
  **not** fix the extension case. Flutter 3.29+ removed the old HTML renderer
  that used to help, so there is no renderer toggle that fixes this.

## The fix: inline native HTML login form

Put a real `<form>` (email + password, proper `autocomplete`) directly in
`web/index.html`, embedded in the landing Sign In tab via `HtmlElementView`.
A Dart conditional-import bridge (`dart:js_interop` extension type over the JS
object; no-op stub off-web) mounts the form and registers callbacks. Auth stays
in Dart — JS only sources the typed/autofilled credentials and calls back; Dart
drives the form busy/error state after the login future settles.

**Why this shape:** keeping auth in Dart avoids duplicating token handling in JS
and avoids Promise interop. The JS form only needs to be real DOM for the
extensions to see it. Inline embedding (not a modal overlay) keeps fields visible
and discoverable on page load without duplicating the whole login card.

**How to apply:**
- The logged-out entry is `/landing` (LandingScreen), not `/login` (LoginScreen
  exists but is unrouted). Web uses `NativeLoginInlineView` in
  `LandingLoginForm`; mobile/desktop apps keep Flutter `TextFormField`s.
- `detach()` must clear the password/email fields and null the callbacks so
  credentials aren't retained in the DOM after dismissal.
- index.html lives in `web/`; the running workflow serves the prebuilt
  `build/web`, so any index.html or Dart change needs `flutter build web`
  + workflow restart before it shows in the preview.
- Deep links like `/landing` 404 against the static server (no SPA fallback);
  load `/` and let GoRouter redirect when screenshotting.

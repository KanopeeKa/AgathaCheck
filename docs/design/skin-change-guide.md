# Skin-change guide

**One question, one answer:** to change AgathaTrack's color scheme, edit
`flutter_app/lib/core/theme/app_color_tokens.dart`. Every screen, component,
and (as of this guide) generated PDF report reads its colors from that file
— nothing else in `lib/` should need to change for a straight palette swap.

This page is the full checklist for a re-skin: the one file that drives the
Flutter app, the handful of companion files that can't share Dart constants
(different runtime: web shell HTML/CSS, PDF export types, Node email
templates), and the logo assets. Tone, layout, spacing, and UX patterns are
untouched by a re-skin — see `principles.md` for those.

## 1. The source of truth

| File | What it controls |
|------|-------------------|
| `flutter_app/lib/core/theme/app_color_tokens.dart` | Every named color constant (`guardianPrimary`, `organizationPrimary`, `success`, `danger`, borders, text, etc.) |
| `flutter_app/lib/core/theme/app_theme.dart` | Wires those tokens into Flutter's `ColorScheme` / `ThemeData` — radii, elevation, component themes. Only touch if you're changing *shape*, not color. |
| `flutter_app/lib/core/theme/experience_colors.dart` | Guardian (plum) vs organisation (teal) mode switch — reads the same tokens. |
| `docs/design/tokens.md` | Human-readable palette reference + accessibility/contrast notes. Update alongside the token file. |

Changing a hex value in `app_color_tokens.dart` propagates through
`Theme.of(context)` / `ColorScheme` to essentially every widget in the app.
A handful of files still reference `Theme.of(context).colorScheme.*` names
you'd expect (`error`, `primaryContainer`, `success`-style tokens) rather
than the constants directly — that's intentional Material 3 usage, not a
bypass, and still ultimately reads from this file.

## 2. Companion palettes that mirror the tokens (different runtime, can't share Dart consts)

These live outside `lib/` (or use a different color type) so they can't
literally `import` `app_color_tokens.dart`. Update them together with the
token file when re-skinning — each links back to which token it mirrors.

| File | Why it's separate | What to update |
|------|--------------------|-----------------|
| `flutter_app/lib/core/theme/pdf_report_tokens.dart` | The `pdf` package's `PdfColor` is a different type from Flutter's `Color`; PDF report generation can't read `ThemeData` at runtime. | Hex values, each commented with the `AppColorTokens` constant it mirrors. `test/core/theme/pdf_report_tokens_test.dart` fails if the two drift. |
| `flutter_app/web/manifest.json` | PWA metadata read by the browser before Flutter boots. | `background_color`, `theme_color` (currently `#755B68` = `guardianPrimary`). |
| `flutter_app/web/index.html` | Native HTML/CSS login form (for password-manager autofill) rendered before/alongside the Flutter canvas — see the comment in that file. | Inline `<style>` block: input border/focus colors, submit button background/hover, link color, and the `prefers-color-scheme: dark` block. |
| `server/lib/email/branding.js` | Node backend, not Flutter — used in transactional email HTML. | `PRIMARY_COLOR`, `PRIMARY_COLOR_HOVER`. |

## 3. Logo assets

The app supports two logo variants selected by `AppExperience` (guardian vs
organisation) via `flutter_app/lib/core/branding/logo_assets.dart`
(`LogoAssets.pngFor` / `jpgFor`).

| Asset | Used by |
|-------|---------|
| `flutter_app/assets/logo-plum.png` / `.jpg` | Guardian experience — `BrandedLogo`, `AppLogoTitle`, landing hero, PDF report header |
| `flutter_app/assets/logo-teal.png` / `.jpg` | Organisation experience — same call sites, org routes |
| `server/assets/logo-plum.png` / `.jpg`, `server/assets/logo-teal.png` / `.jpg` | Identical copies embedded in transactional emails (`server/lib/email/`) |

To swap logos: replace these 8 files in place (keep filenames and
dimensions consistent — PNG for in-app/email use, JPG for the landing hero)
and declare any new filenames in `flutter_app/pubspec.yaml` under `flutter:
assets:`.

Favicon and PWA/app icons are separate static images, not generated from
the logo assets, and should be refreshed by hand for a full rebrand:

| File | Purpose |
|------|---------|
| `flutter_app/web/favicon.png` | Browser tab icon |
| `flutter_app/web/icons/Icon-192.png`, `Icon-512.png` | PWA install icons |
| `flutter_app/web/icons/Icon-maskable-192.png`, `Icon-maskable-512.png` | PWA maskable icons (Android adaptive icon safe zone) |

## 4. Documented color exceptions (deliberately outside the token system)

From `tokens.md` — these are intentional, not tokenization gaps:

| Token / value | Reason |
|---------------|--------|
| `AppColorTokens.petRainbowIconGradient` | Passed-away memorial icon — a literal rainbow, not a brand color |
| `Pet.palette` (`flutter_app/lib/features/pet_profile/domain/entities/pet.dart`) | Per-pet, user-chosen identification colors — not a system/brand color |
| `AppColorTokens.orgSuperAdminBorder` / `orgAdminBorder` | Role-badge ring accents, deliberately distinct from the primary palette |

## 5. Verifying a re-skin

1. Edit `app_color_tokens.dart` (and the companion files above for
   consistency).
2. `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos`
3. `cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration`
   — `test/core/theme/app_theme_test.dart` and
   `test/core/theme/pdf_report_tokens_test.dart` assert the new values wire
   through correctly.
4. `cd flutter_app && flutter build web --release --no-tree-shake-icons`
   and spot-check a guardian screen, an organisation screen, and a
   generated PDF report.

## See also

- `tokens.md` — palette values, usage per token, accessibility/contrast rules
- `principles.md` — tone and UX principles that do **not** change with a re-skin
- `index.md` — design guidance map for agents

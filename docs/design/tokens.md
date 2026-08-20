# Design tokens

Canonical palette for AgathaTrack. Implemented in `flutter_app/lib/core/theme/`.  
**Phase 0:** `app_theme.dart` + `ExperienceColors` extension. Screens adopt experience tokens in later phases.

**Re-skinning the app?** See `skin-change-guide.md` for the full checklist —
the one file to edit (`app_color_tokens.dart`) plus logos, web manifest,
PDF report tokens, and email branding that mirror it.

## Foundations

| Token | Hex | Flutter role |
|-------|-----|--------------|
| background | `#F8F5F1` | `scaffoldBackgroundColor` |
| surface | `#FFFFFF` | cards, sheets |
| surfaceAlt | `#F3EDE7` | grouped sections |
| border | `#E5DDD6` | dividers, outlines |
| borderStrong | `#D5CCC4` | emphasis borders |
| shadow | `rgba(45,51,56,0.08)` | elevation shadows |

## Approved landing direction (pending production integration)

The approved landing/auth prototype introduces a distinct Operations Desk
surface treatment. These values are the visual reference for the landing
integration; they do **not** replace the current app-wide tokens until the
production screen and theme rollout are implemented.

| Token | Hex | Use |
|-------|-----|-----|
| landingPaper | `#F5F2E9` | warm-paper auth surface |
| landingPaperDeep | `#EBE9DC` | subtle paper grouping |
| landingPanel | `#FBFAF5` | auth card surface |
| landingInk | `#2F4439` | landing text |
| landingInkSoft | `#52685A` | secondary landing text |
| landingOlive | `#3B5849` | story panel / care-desk context |
| landingOliveDark | `#2F483D` | deep olive depth |
| landingSage | `#A8B9A0` | restrained supporting tint |
| landingGold | `#CAA75C` | logo surround, rules, focused accents |
| landingGoldSoft | `#EFE5C5` | low-emphasis gold surface |
| landingClay | `#C47D68` | exceptional warm signal only |
| landingLine | `#D6DFD3` | light borders and dividers |

### Landing color roles

These supporting roles complete the landing palette. Use the role names rather
than inventing nearby one-off colors:

| Role | Hex / value | Use |
|------|-------------|-----|
| storyText | `#F2F2E9` | primary text on the olive story panel |
| storyTextStrong | `#F6F3E8` | large display text and high-emphasis story content |
| storyTextMuted | `#C7D0C5` | story lede and supporting copy |
| storyMeta | `#CBD4C7` | compact top-bar metadata |
| storyAccent | `#D6C481` | eyebrow, icon, rule, and display emphasis |
| storyLive | `#C6D693` | small live/synced indicator |
| inputSurface | `#FDFCF8` | email/password input surface |
| inputBorder | `#D8E0D6` | resting input border |
| inputFocusBorder | `#839C82` | focused input border |
| inputFocusRing | `#E4EBDE` | 3px focus halo around inputs |
| noticeSurface | `#F4EDCF` | inline informational notice |
| noticeBorder | `#DFD7AE` | informational notice border |
| noticeText | `#78683D` | informational notice text |
| buttonShadow | `#294336` | restrained depth under the primary landing button |

Alpha overlays are part of the composition, not standalone brand colors:

- Story gold atmosphere: `rgba(205,181,104,0.18)` at the upper-right.
- Story sage atmosphere: `rgba(164,192,159,0.20)` at the lower-left.
- Signal pills: `rgba(225,228,202,0.09)` with
  `rgba(225,228,202,0.19)` border.
- Desk preview: `rgba(18,42,31,0.22)` with a quiet
  `rgba(221,228,206,0.22)` border.

Landing authentication has one universal entry point. Do not add a
guardian/shelter/organisation selector to the login form; experience and
permissions are determined after authentication.

### Landing typography

| Role | Typeface | Reference |
|------|----------|-----------|
| Display headline | Instrument Serif, Georgia fallback | 49–86px responsive, regular weight, tight leading |
| Auth heading | Instrument Serif, Georgia fallback | approximately 39px, regular weight |
| Body and controls | DM Sans, system sans fallback | 10–16px depending on hierarchy |
| Data/time preview | Space Mono, monospace fallback | compact metadata only |

Use the serif face for emotional orientation and major statements, not for
forms or operational labels. Uppercase labels are compact, bold, and
letter-spaced; avoid applying that treatment to paragraphs or error messages.

### Landing layout and shape

- Desktop composition: story panel plus auth panel, approximately `1.05fr /
  0.95fr`; collapse to one column below the mobile breakpoint.
- Auth content max width: approximately `430px`; story copy max width:
  approximately `660px`.
- Core rhythm: `8px` micro gap, `12px` control gap, `16px` section gap,
  `24px` card padding, `45–58px` panel padding.
- Shape language: `9px` inputs/buttons, `11px` brand mark surround, `16–17px`
  cards, and pill radius for status signals.
- Primary controls remain at least `48px` high in production, even if the
  compact visual reference uses a smaller mockup scale.

### Landing interaction states

- Active sign-in/create-account tab: olive text plus a muted-gold underline;
  do not rely on color alone.
- Input focus: visible border and focus ring; never remove the browser or
  Flutter focus treatment.
- Primary button hover may lift subtly; active state should settle back down.
- Disabled, validation, and notice states need text or icon support in addition
  to color.

### Logo usage

The canonical mark is the protective shelter arch over simple cat and dog
forms. Do not replace it with paws, paw prints, or a generic pet icon.

- Canonical repository source and Flutter runtime asset:
  `flutter_app/assets/branding/agathatrack-care-mark.svg`, plus the existing
  PNG/JPG compatibility assets.
- Mockup public copy:
  `artifacts/mockup-sandbox-live/public/agathatrack-care-mark.svg`.
- The gold surround is a landing composition treatment, not part of the SVG
  itself.

## Typography colors

| Token | Hex | Use |
|-------|-----|-----|
| heading | `#2D3338` | titles |
| body | `#394249` | primary text → `onSurface` |
| muted | `#68737A` | secondary → `onSurfaceVariant` |
| disabled | `#A3ABB1` | disabled controls only |
| inverse | `#FFFFFF` | on primary buttons |

## Guardian mode (default primary — landing + `/g/*`)

| Token | Hex |
|-------|-----|
| primary | `#755B68` |
| hover | `#664C59` |
| active | `#573F4B` |
| light | `#F4EEF2` |
| soft | `#E7DCE2` |

Full primary on all guardian CTAs (option A).

## Organisation mode (`/o/*`)

| Token | Hex |
|-------|-----|
| primary | `#218B6C` |
| hover | `#1B765C` |
| active | `#17664F` |
| light | `#EAF7F2` |
| soft | `#D8EFE6` |

Org-guardianship pet photo border on guardian home: **primary** teal (subtle).

## Warm accent (never primary CTA)

| Token | Hex |
|-------|-----|
| accent | `#D6A08F` |
| lightAccent | `#F4E4DD` |

Empty states, onboarding, welcome — not main action buttons.

## Semantic (shared across modes)

| Token | Hex | Notes |
|-------|-----|-------|
| info | `#5C7EA6` | |
| success | `#2B7A2E` | S2 — icons/badges/small text; not large fills |
| successLight | `#E8F5E9` | backgrounds only; verify contrast |
| warning | `#D6A63A` | prefer icon/badge; validate on light surfaces |
| danger | `#C65B58` | errors, destructive |

## Drawer grouping (v2)

Semantic **background fill only** — no borders on menu rows.

| Code | Token | Guardian menu | Organisation menu |
|------|-------|---------------|-------------------|
| **p** | `guardianLight` | My Pets, Notifications, Events, My vets | Guardian view (switch) |
| **g** | `organizationLight` | Organisation view (switch) | My Organisation, Notifications, Events, Org vets |
| **w** | `surfaceAlt` | Settings, Help, About, Contact, Legal, Invite, Log out | same utility block |

Shell top bar uses experience primary (plum on `/g/*`, green on `/o/*`). Utility group never uses mode primary as row background.

**Ownership accents** (pets, vets, notifications): plum = guardian/personal; green = fostered/org-linked. Pair with text + icon (`docs/design/navigation-v2.md`).

**Super admin** tag: warm coral (`orgSuperUserBg` / `orgSuperUserFg`) — distinct from ownership colors.

## Utility (drawer: settings, logout, FAQ, contact)

Use foundation **body** / **muted** text on **w** group backgrounds — not guardian plum or org teal as text color for utility labels.

## Accessibility

- Normal text ≥ 4.5:1; large text / UI boundaries ≥ 3:1
- Focus ring ≥ 3:1 against adjacent colors; never shadow-only
- Touch targets ≥ 48dp logical px
- Light tints (`*Light`, `*Soft`) are background-only unless contrast checked
- `disabled` not for secondary readable text
- Do not use color alone for selected/active/validation state

## Contrast notes (verified targets)

| Pair | Intent |
|------|--------|
| body on background | pass AA |
| body on surface | pass AA |
| guardian primary on inverse | pass AA |
| org primary on inverse | pass AA |
| success on surface | pass AA for small labels |
| muted on background | verify; darken if weak |

## Dashboard sections (guardian shell)

Dashboard preview blocks on `/g/home` use **top-border accents only** — no filled card surface:

- Border: 2px top edge in section theme colour (`ColorScheme.primary` or experience accent)
- Background: transparent (scaffold `background` shows through)
- Guardian dashboard sections: plum top border; org sections: teal when on org routes

## Implementation

| File | Role |
|------|------|
| `app_color_tokens.dart` | const hex values |
| `experience_colors.dart` | `ThemeExtension` + helpers |
| `app_theme.dart` | `ThemeData`, component themes, legacy `AppTheme.org*` aliases |
| `pdf_report_tokens.dart` | Mirrors the same hex values as `PdfColor` constants for generated PDF reports (separate type, can't share Dart consts across packages) |

Default `ColorScheme.primary` = guardian plum (pet-guardian-first landing).

Experience-specific primaries via `Theme.of(context).extension<ExperienceColors>()` and `experiencePrimaryFor(AppExperience)`.

## Accessibility

See contrast and touch rules above.

## Motion

Respect `prefers-reduced-motion`. Calm, short transitions only.

## Spacing and touch

- Minimum tap target: 48×48 logical px
- Border radius: cards 16, inputs/buttons 12, dialogs 20 (unchanged from current theme)

## Documented color exceptions

| Token | Use |
|-------|-----|
| `passedAwayPhotoOverlay` | Memorial lighten on passed-away pet photos |
| `orgSuperAdminBorder` / `orgAdminBorder` | Org member role card rings |
| `petRainbowIconGradient` | Passed-away form icon only |
| `pet.colorValue` | Per-pet user-chosen color (not system) |

# Design tokens

Canonical palette for AgathaTrack. Implemented in `flutter_app/lib/core/theme/`.  
**Phase 0:** `app_theme.dart` + `ExperienceColors` extension. Screens adopt experience tokens in later phases.

## Foundations

| Token | Hex | Flutter role |
|-------|-----|--------------|
| background | `#F8F5F1` | `scaffoldBackgroundColor` |
| surface | `#FFFFFF` | cards, sheets |
| surfaceAlt | `#F3EDE7` | grouped sections |
| border | `#E5DDD6` | dividers, outlines |
| borderStrong | `#D5CCC4` | emphasis borders |
| shadow | `rgba(45,51,56,0.08)` | elevation shadows |

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

## Utility (drawer: settings, logout, FAQ)

Use foundation **body** / **muted** — not guardian plum or org teal.

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

## Implementation

| File | Role |
|------|------|
| `app_color_tokens.dart` | const hex values |
| `experience_colors.dart` | `ThemeExtension` + helpers |
| `app_theme.dart` | `ThemeData`, component themes, legacy `AppTheme.org*` aliases |

Default `ColorScheme.primary` = guardian plum (pet-guardian-first landing).

Experience-specific primaries via `Theme.of(context).extension<ExperienceColors>()` and `experiencePrimaryFor(AppExperience)`.

## Drawer grouping

| Current view | Shell + home CTAs | Role block in drawer | Utility block |
|--------------|-------------------|----------------------|---------------|
| `/g/*` | plum | guardian plum; org section teal | neutral |
| `/o/*` | teal | org teal; guardian section plum | neutral |

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

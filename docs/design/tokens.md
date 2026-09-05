---
title: Design tokens
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-04
tags: [design,ui,ux]
---
# Design tokens

Canonical **colour tables** for AgathaTrack. Full component and layout spec: [`system.md`](./system.md) (Operations Desk / Replit-approved). Implemented in `flutter_app/lib/core/theme/`.

**Re-skinning?** See [`skin-change-guide.md`](./skin-change-guide.md) — edit `app_color_tokens.dart` plus logos, web manifest, PDF, and email branding.

## Foundations

| Token | Hex | Flutter role |
|-------|-----|--------------|
| background | `#EAE8E8` | `scaffoldBackgroundColor` |
| surface | `#FFFDFC` | cards, sheets |
| surfaceAlt | `#F2ECE6` | grouped sections |
| border | `#E4DDD6` | dividers, outlines |
| borderStrong | `#D6CBC3` | emphasis borders |
| shadow | `rgba(31,41,55,0.08)` | elevation shadows |

## Approved landing direction

The public landing uses the same Pet Care plum, Shelter teal, and warm-neutral
system as the app. Its composition is distinct, but it must not introduce a
third, one-off palette.

| Token | Hex | Use |
|-------|-----|-----|
| landingPaper | `#EAE8E8` | warm public canvas |
| landingPanel | `#FFFDFC` | auth and care-preview cards |
| landingInk | `#1F2937` | landing text |
| landingInkSoft | `#52606D` | secondary landing text |
| landingPlum | `#755B68` | universal primary action |
| landingTeal | `#1D7C84` | photo arches, focus, care context |
| landingTealDeep | `#14656C` | high-contrast teal content |
| landingTealSoft | `#E6F2F2` | quiet teal surface |
| landingLine | `#D9E5E1` | light borders and dividers |

### Landing color roles

These supporting roles complete the landing palette. Use the role names rather
than inventing nearby one-off colors:

| Role | Hex / value | Use |
|------|-------------|-----|
| storyText | `#1F2937` | high-emphasis public story text |
| storyTextMuted | `#52606D` | story lede and supporting copy |
| storyAccent | `#1D7C84` | care-context emphasis |
| inputSurface | `#FFFDFC` | email/password input surface |
| inputBorder | `#D9E5E1` | resting input border |
| inputFocusBorder | `#1D7C84` | focused input border |
| inputFocusRing | `rgba(29,124,132,0.16)` | 3px focus halo around inputs |
| noticeSurface | `#F4EDCF` | inline informational notice |
| noticeBorder | `#DFD7AE` | informational notice border |
| noticeText | `#78683D` | informational notice text |
| buttonShadow | `#294336` | restrained depth under the primary landing button |

Do not introduce extra landing overlays or atmospheric colors without first
adding a semantic token in `app_color_tokens.dart`.

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

- Active sign-in/create-account tab: plum text plus a teal underline;
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
- The warm-paper surround is a landing composition treatment, not part of the SVG
  itself.

## Typography colors

| Token | Hex | Use |
|-------|-----|-----|
| heading | `#1F2937` | titles |
| body | `#374151` | primary text → `onSurface` |
| muted | `#667085` | secondary → `onSurfaceVariant` |
| disabled | `#98A2B3` | disabled controls only |
| inverse | `#FFFFFF` | on primary buttons |

## Pet Care mode (default primary — landing + `/pc/*`)

| Token | Hex |
|-------|-----|
| primary | `#755B68` |
| hover | `#664C59` |
| active | `#573F4B` |
| light | `#E8E1E3` |
| soft | `#E7DCE2` |

Full primary on all guardian CTAs (option A).

## Shelter mode (`/o/*`)

| Token | Hex |
|-------|-----|
| primary | `#1D7C84` |
| hover | `#176972` |
| active | `#125860` |
| light | `#EAF5F5` |
| soft | `#D8ECEC` |

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

| Code | Token | Pet Care menu | Organisation menu |
|------|-------|---------------|-------------------|
| **p** | `guardianLight` | My Pets, Notifications, Events, My vets | Pet Care view (switch) |
| **g** | `organizationLight` | Organisation view (switch) | My Organisation, Notifications, Events, Org vets |
| **w** | `surfaceAlt` | Settings, Help, About, Contact, Legal, Invite, Log out | same utility block |

Shell top bar uses experience primary (plum on `/pc/*`, teal on `/o/*`). Utility group never uses mode primary as row background.

**Ownership accents** (pets, vets, notifications): plum = guardian/personal; green = fostered/org-linked. Pair with text + icon (`docs/archived/navigation-v2.md`).

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

Dashboard preview blocks on `/pc/home` use an **open canvas** on `background` — section grouping via eyebrow headers and local row/card surfaces, not large tinted section wrappers:

- Section chrome: eyebrow title + optional “All …” on one header row (D-desk-3)
- Optional: 2px top-border accent in section theme colour for legacy `DashboardSection` paths
- **Care preview exception:** `GuardianDeskSectionCard` with `petCareLight` wraps the CARE ACTIONS list (same token as pet-detail care preview); Care Team stays open canvas with per-row `CareTeamCard` surfaces
- Fostering org tint (`organizationLight`) remains the cross-experience exception
- Pet Care dashboard accents: plum; org/fostering cross-context: teal/org tokens when applicable

## Dashboard sections (Shelter shell)

Shelter dashboard blocks on `/o/orgs` use an **organizationLight canvas** — not Care `background` or plum (D-desk-S8). Section grouping matches the guardian desk eyebrow pattern but with teal tokens only:

| Surface | Token | Widget / route |
|---------|-------|----------------|
| Scaffold canvas | `organizationLight` | `orgListScaffoldBackground` on `/o/orgs` and org shell body |
| Section eyebrow | `organizationPrimary` | `OrgHubSectionHeader`, `GuardianDashboardSectionHeader` (Shelter tasks) |
| Membership cards | `surface` | `orgListCardColor` / unified membership tile |
| Task preview card | `surface` | `GuardianDeskSectionCard` inside `ShelterTasksPreview` |
| Compact bottom nav | `organizationPrimary` bar; `organizationLight` unselected labels | `ShelterBottomNavigation` |
| Rail / sidebar chrome | `surface` background; `organizationPrimary` selected state | `ShelterNavigationRail`, `ShelterNavigationSidebar` |
| Compact app bar | `organizationPrimary` | `ExperienceShellScaffold` when Shelter primary nav active |
| Workspace toggle menu | `organizationPrimary` when `/o/**` active | `ExperienceWorkspaceToggle` |

**Grep guard (shelter-dashboard-v2):** no `petCarePrimary` / plum on `/o/**` presentation paths in this plan. Routed org UI uses `themeForAppExperience` to remap `ColorScheme` and component themes that would otherwise inherit guardian plum from `AppTheme.lightTheme`. Semantic warning/danger unchanged.

## Dashboard ambient decorations (guardian home, wide web)

Optional non-interactive sketch overlays gated by **measured leftover space** (not viewport alone):

| Asset | Role |
|-------|------|
| `dashboard-deco-cat.png` | Pet rail — cat end cap |
| `dashboard-deco-yarn-segment.png` | Pet rail — horizontal connector (X-fit only) |
| `dashboard-deco-yarn-ball.png` | Pet rail — yarn ball end cap |
| `dashboard-deco-puppy-bowl.png` | Care Team column watermark |

- Opacity: **0.8** (`GuardianDashboardDecoThresholds.opacity`)
- Mobile (`<600px`): hidden
- Pet rail: overlay in horizontal slack beside cards; hidden when rail scrolls
- Care Team puppy: wide desk layout (content width `≥900px`) + non-empty list; lower-right of stretched column
- `ExcludeSemantics` + `IgnorePointer`; real content always wins

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

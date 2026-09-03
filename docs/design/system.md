---
title: AgathaTrack design system
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-26
tags: [design, tokens, system]
---

# AgathaTrack Design System

**Status:** Canonical visual specification
**Product:** AgathaTrack — dependable care coordination for guardians, shelters, and foster teams
**Platform:** Flutter web, iOS, and Android
**Last updated:** 2026-08-22

This document is the visual source of truth for new and redesigned AgathaTrack
surfaces. It turns the approved Operations Desk blueprint into exact, reusable
tokens and component rules. Runtime values live in
`flutter_app/lib/core/theme/app_color_tokens.dart` and
`flutter_app/lib/core/theme/app_theme.dart`; implementation must mirror this
specification rather than introducing one-off visual values.

## Design intent

AgathaTrack feels like a calm, trustworthy care desk, not a social pet app or
a generic administration console.

- **Warm paper and quiet white surfaces** provide a focused, humane workspace.
- **Pet Care plum** and **Shelter teal** show experience context, never
  permission or severity by themselves.
- **Warm paper, plum, cooler Shelter teal, and the protective arch mark** form
  the role-neutral landing and auth experience.
- **Coral is decorative only.** It is never the primary action, error, or
  warning colour.
- Every state conveyed by colour also has text, icon, shape, or position.

The current product name is **AgathaTrack**. Do not introduce **AgathaCheck**
in new UI, marketing, or design-system copy.

---

## 1. Color tokens

### 1.1 Primitive palette

Use primitive values only when defining semantic tokens or a documented
component variant. Product UI should consume semantic tokens.

#### Warm neutrals

| Token | Hex | Purpose |
|---|---:|---|
| `neutral-50` | `#FFFDFC` | brightest raised surface |
| `neutral-100` | `#EAE8E8` | warm page background |
| `neutral-200` | `#F2ECE6` | grouped surface |
| `neutral-300` | `#E4DDD6` | standard border |
| `neutral-400` | `#D6CBC3` | strong border / drag handle |
| `neutral-500` | `#98A2B3` | disabled text and icon |
| `neutral-600` | `#667085` | secondary text |
| `neutral-700` | `#52606D` | supporting dark text |
| `neutral-800` | `#374151` | body text |
| `neutral-900` | `#1F2937` | headings / strong ink |
| `neutral-950` | `#1F2937` | high-emphasis ink |

#### Legacy Operations aliases

| Token | Hex | Purpose |
|---|---:|---|
| `operationsOlive` | `#14656C` | compatibility alias; use Shelter teal in new UI |
| `operationsOliveLight` | `#1D7C84` | compatibility alias; use Shelter teal in new UI |
| `operationsGold` | `#755B68` | compatibility alias; use Pet Care plum in new UI |

#### Pet Care plum

| Token | Hex | Purpose |
|---|---:|---|
| `plum-50` | `#FBF8FA` | faint guardian tint |
| `plum-100` | `#E8E1E3` | guardian contextual surface |
| `plum-200` | `#E7DCE2` | guardian soft surface |
| `plum-300` | `#CDB9C3` | guardian subtle border |
| `plum-400` | `#A78294` | guardian icon support |
| `plum-500` | `#755B68` | Pet Care primary |
| `plum-600` | `#664C59` | Pet Care hover |
| `plum-700` | `#573F4B` | Pet Care pressed / active |
| `plum-800` | `#422F39` | Pet Care dark text on tint |
| `plum-900` | `#301F29` | high-emphasis plum |
| `plum-950` | `#21141C` | dark overlay only |

#### Shelter teal

| Token | Hex | Purpose |
|---|---:|---|
| `teal-50` | `#F2FAFA` | faint Shelter tint |
| `teal-100` | `#EAF5F5` | Shelter contextual surface |
| `teal-200` | `#D8ECEC` | Shelter soft surface |
| `teal-300` | `#ADD5D8` | Shelter subtle border |
| `teal-400` | `#6CAEB4` | Shelter icon support |
| `teal-500` | `#1D7C84` | Shelter primary |
| `teal-600` | `#176972` | Shelter hover |
| `teal-700` | `#125860` | Shelter pressed / active |
| `teal-800` | `#0E464C` | Shelter dark text on tint |
| `teal-900` | `#083437` | high-emphasis teal |
| `teal-950` | `#052326` | dark overlay only |

#### Warm accent and semantic colours

| Token | Hex | Purpose |
|---|---:|---|
| `coral-50` | `#FDF7F4` | faint warm accent tint |
| `coral-100` | `#F4E4DD` | onboarding / welcome surface |
| `coral-300` | `#E8B9AA` | restrained illustration detail |
| `coral-500` | `#D6A08F` | warm accent |
| `coral-700` | `#A66A5B` | high-contrast coral text only |
| `info-500` | `#5C7EA6` | informative status |
| `success-100` | `#E8F5E9` | success background |
| `success-500` | `#2B7A2E` | success status |
| `warning-100` | `#FFF4D8` | warning background |
| `warning-500` | `#D6A63A` | warning status |
| `error-100` | `#FBE9E8` | error background |
| `error-500` | `#C65B58` | destructive / error status |

### 1.2 Semantic color tokens

```css
:root {
  --color-bg-primary: #EAE8E8;       /* Main app canvas */
  --color-bg-secondary: #FFFDFC;     /* Cards, sheets, menus */
  --color-bg-tertiary: #F2ECE6;      /* Grouped sections, quiet input areas */
  --color-bg-overlay: #1F2937;       /* Dark overlay / snackbar background */

  --color-text-primary: #1F2937;     /* Headings and high-emphasis content */
  --color-text-body: #374151;        /* Body copy and field labels */
  --color-text-secondary: #667085;   /* Metadata and supporting copy */
  --color-text-disabled: #98A2B3;    /* Disabled controls only */
  --color-text-inverse: #FFFFFF;     /* Text on dark/primary fills */

  --color-border: #E4DDD6;           /* Dividers and resting input borders */
  --color-border-strong: #D6CBC3;    /* Emphasis border / drag handle */
  --color-focus-ring: #1D7C84;       /* Visible 3px focus halo */

  --color-primary: #755B68;          /* Pet Care primary by default */
  --color-primary-hover: #664C59;    /* Pet Care hover */
  --color-primary-active: #573F4B;   /* Pet Care pressed */
  --color-primary-disabled: #CDB9C3; /* Disabled Pet Care primary */
  --color-primary-subtle: #E8E1E3;   /* Pet Care selected surface */

  --color-success: #2B7A2E;          /* Completed / saved state */
  --color-success-subtle: #E8F5E9;   /* Success background */
  --color-warning: #D6A63A;          /* Due / needs attention */
  --color-warning-subtle: #FFF4D8;   /* Warning background */
  --color-error: #C65B58;            /* Error / destructive state */
  --color-error-subtle: #FBE9E8;     /* Error background */
  --color-info: #5C7EA6;             /* Informational state */
}
```

#### Context overrides

| Context | Primary | Hover | Active | Subtle surface |
|---|---:|---:|---:|---:|
| Pet Care (default) | `#755B68` | `#664C59` | `#573F4B` | `#E8E1E3` |
| Shelter | `#1D7C84` | `#176972` | `#125860` | `#EAF5F5` |
| Landing/auth | `#755B68` | `#664C59` | `#573F4B` | `#E6F2F2` |

```css
[data-experience="shelter"] {
  --color-primary: #1D7C84;
  --color-primary-hover: #176972;
  --color-primary-active: #125860;
  --color-primary-disabled: #ADD5D8;
  --color-primary-subtle: #EAF5F5;
}
```

**Rules**

1. Use `--color-primary` for the one primary action at a decision point.
2. Never use a contextual primary as an error, warning, permission, or role
   indicator.
3. Use semantic success/warning/error tokens only with an accompanying label
   and, where useful, icon.
4. Shelter logos may personalise imagery and identity only; they may not
   replace product-controlled semantic colours or focus treatment.

### 1.3 Landing/auth palette

| Token | Hex | Usage |
|---|---:|---|
| `landing-paper` | `#EAE8E8` | warm public canvas |
| `landing-panel` | `#FFFDFC` | authentication and care-preview surface |
| `landing-ink` | `#1F2937` | auth heading / dark text |
| `landing-ink-soft` | `#52606D` | supporting auth text |
| `landing-plum` | `#755B68` | primary public action |
| `landing-teal` | `#1D7C84` | photographic arches, focus, and care context |
| `landing-teal-deep` | `#14656C` | teal text and supporting contrast |
| `landing-line` | `#D9E5E1` | landing borders |
| `landing-input` | `#FFFDFC` | field surface |

The canonical mark is the thick rounded protective arch containing a plum dog
and smaller Shelter-teal cat. Do not substitute a paw print or generic pet
icon. The SVG at `flutter_app/assets/branding/agathatrack-care-mark.svg` is
the master; all PNG/JPG, favicon, PWA, PDF, and email variants are exports.

---

## 2. Typography tokens

### 2.1 Font families

```css
:root {
  --font-display: "Instrument Serif", Georgia, serif;
  --font-sans: "DM Sans", Inter, -apple-system, BlinkMacSystemFont,
    "Segoe UI", sans-serif;
  --font-mono: "Space Mono", "SFMono-Regular", Consolas, monospace;
}
```

| Family | Use | Rules |
|---|---|---|
| Display | Landing hero and auth heading only | Regular weight; never use for forms, table data, or operational labels |
| Sans | All authenticated UI, controls, body, labels | Default product typeface |
| Mono | Compact data/time preview only | Never use for long labels or body copy |

### 2.2 Type scale

| Token | Size / line height | Weight | Letter spacing | Usage |
|---|---:|---:|---:|---|
| `font-size-xs` | `12px / 16px` | 500 | `0` | metadata, helper text |
| `font-size-sm` | `14px / 20px` | 400 | `0` | secondary body, form help |
| `font-size-base` | `16px / 24px` | 400 | `0` | default body and inputs |
| `font-size-lg` | `18px / 26px` | 500 | `-0.01em` | lead body, list emphasis |
| `font-size-xl` | `20px / 28px` | 600 | `-0.01em` | card and section title |
| `font-size-2xl` | `24px / 32px` | 600 | `-0.015em` | page title |
| `font-size-3xl` | `30px / 38px` | 600 | `-0.02em` | major page / organisation title |
| `font-size-4xl` | `40px / 46px` | 400 display | `-0.03em` | mobile landing headline |
| `font-size-5xl` | `56px / 62px` | 400 display | `-0.035em` | desktop landing headline only |

```css
:root {
  --font-weight-light: 300;
  --font-weight-regular: 400;
  --font-weight-medium: 500;
  --font-weight-semibold: 600;
  --font-weight-bold: 700;

  --line-height-tight: 1.2;
  --line-height-normal: 1.5;
  --line-height-relaxed: 1.75;

  --letter-spacing-heading: -0.015em;
  --letter-spacing-body: 0;
  --letter-spacing-uppercase: 0.08em;
}
```

### 2.3 Typography rules

- Use sentence case for headings, buttons, labels, and status text.
- Use uppercase only for compact, non-essential eyebrows or metadata; apply
  `font-size-xs`, weight 700, and `--letter-spacing-uppercase`.
- Let page titles wrap to two lines before truncating. Do not reduce text below
  the defined token to force a single line.
- Support 200% text scaling without clipped labels, fixed-height text blocks,
  or inaccessible horizontal scrolling.
- Do not encode status in font weight alone.

---

## 3. Spacing tokens

### 3.1 Base scale

```css
:root {
  --spacing-0: 0px;
  --spacing-1: 4px;
  --spacing-2: 8px;
  --spacing-3: 12px;
  --spacing-4: 16px;
  --spacing-5: 20px;
  --spacing-6: 24px;
  --spacing-8: 32px;
  --spacing-10: 40px;
  --spacing-12: 48px;
  --spacing-16: 64px;
  --spacing-20: 80px;
}
```

| Semantic token | Value | Usage |
|---|---:|---|
| `spacing-page-padding` | `16px` compact, `24px` medium+ | horizontal content inset |
| `spacing-card-padding` | `16px` standard, `24px` featured | card interior |
| `spacing-input-padding-x` | `16px` | input horizontal inset |
| `spacing-input-padding-y` | `12px` | input vertical inset |
| `spacing-between-elements` | `12px` | related controls / text groups |
| `spacing-between-groups` | `20px` | related content groups |
| `spacing-section` | `32px` | dashboard and page sections |
| `spacing-touch-inset` | `8px` | invisible hit-area expansion where required |

### 3.2 Density rules

- Use `8px` for icon-to-label and closely related text spacing.
- Use `12–16px` inside compact rows and standard cards.
- Use `20px` between related groups.
- Use `24–32px` between major sections.
- Never reduce the interactive hit area below `48 × 48dp` to make a dense list
  fit. Reduce decoration before reducing legibility or touch space.

---

## 4. Border radius and borders

```css
:root {
  --radius-sm: 4px;       /* small tags and compact controls */
  --radius-md: 8px;       /* compact inline controls */
  --radius-lg: 12px;      /* buttons and inputs */
  --radius-xl: 16px;      /* cards and featured sections */
  --radius-2xl: 20px;     /* dialogs and bottom sheets */
  --radius-full: 9999px;  /* pills, avatars, circular icon buttons */

  --border-width-default: 1px;
  --border-width-focus: 2px;
  --border-width-section-accent: 2px;
}
```

Use `--color-border` before adding a shadow. Dashboard preview sections use a
transparent background with a `2px` context-coloured top border; they are not
all elevated cards.

---

## 5. Shadows and elevation

```css
:root {
  --shadow-sm: 0 1px 2px rgba(45, 51, 56, 0.08);
  --shadow-md: 0 4px 12px rgba(45, 51, 56, 0.10);
  --shadow-lg: 0 12px 28px rgba(45, 51, 56, 0.14);
  --shadow-xl: 0 20px 48px rgba(38, 51, 44, 0.18);
  --shadow-inner: inset 0 1px 2px rgba(45, 51, 56, 0.08);
  --shadow-button-landing: 0 2px 0 #294336;
}
```

| Token | Use |
|---|---|
| `shadow-sm` | primary button press depth, subtle floating control |
| `shadow-md` | dropdown, popover, card only when a border is insufficient |
| `shadow-lg` | modal and notification panel |
| `shadow-xl` | high-priority floating overlay only |
| `shadow-inner` | optional read-only inset field / preview |

Cards default to **no shadow** and a 1px border. Use stronger elevation only
for overlays that must visibly sit above the current task.

---

## 6. Component specifications

### 6.1 Shared interaction requirements

Every interactive component must provide:

- a minimum **48 × 48dp** touch target;
- visible keyboard focus using a `2px` focus border plus `3px` focus halo;
- a semantic label that describes outcome, not just appearance;
- a disabled state only when the action cannot proceed safely;
- loading feedback that preserves layout and prevents double submission;
- text, icon, or shape support for colour-coded status.

Hover is an enhancement for pointer devices. Mobile states must remain complete
without hover.

### 6.1a Collection filters

Canonical progressive-disclosure filtering for list screens. Full spec:
[`collection-filter.md`](./collection-filter.md).

| Surface | Pattern |
|---|---|
| Wide (≥600 logical px) | Compact toolbar dimension menus + More filters + active chips |
| Narrow | Filters sheet trigger + active chips |
| Active state | Removable chips only for non-default selections |

Implementation: `flutter_app/lib/core/widgets/collection_filter/`.

### 6.2 Buttons

#### Primary button

| Property | Specification |
|---|---|
| Anatomy | optional leading icon, text label, optional trailing progress indicator |
| Height | `48px` minimum |
| Padding | `24px` horizontal, `12px` vertical |
| Min width | `120px` for standalone CTAs; intrinsic width in forms |
| Typography | `font-size-base`, weight 600 |
| Background | `color-primary` |
| Text/icon | `color-text-inverse` |
| Radius | `radius-lg` |
| Shadow | none by default; `shadow-sm` allowed on landing only |

| State | Exact treatment |
|---|---|
| Default | `color-primary` fill |
| Hover | `color-primary-hover` fill |
| Pressed | `color-primary-active` fill; remove lift |
| Focus | retain fill; add `2px` focus border and `3px` `color-focus-ring` halo |
| Disabled | `color-primary-disabled` fill; inverse text at 70% opacity; no shadow |
| Loading | keep width; replace leading icon with a 16–20px progress indicator; disable repeat presses |
| Error after submit | retain button; show inline error above or below the action, not in the button label |

#### Secondary button

| Property | Specification |
|---|---|
| Background | `color-bg-tertiary` |
| Text/icon | `color-text-primary` |
| Border | `1px color-border` |
| Other dimensions | match primary button |

Hover uses a `color-primary-subtle` background and `color-primary` text/icon.
Pressed uses the context soft surface. Disabled uses the tertiary background and
`color-text-disabled`.

#### Outline button

| Property | Specification |
|---|---|
| Background | transparent |
| Text/icon | `color-primary` |
| Border | `1px color-primary` |
| Other dimensions | match primary button |

Hover uses `color-primary-subtle`; pressed uses the contextual soft surface.
For destructive outline actions, substitute `color-error` for primary and keep
the action visually separated from Save/Create.

#### Ghost and icon buttons

| Property | Specification |
|---|---|
| Ghost background | transparent |
| Ghost text/icon | `color-primary` |
| Icon-only target | `48 × 48px`; visual icon `24px` |
| Radius | `radius-full` for circular icon action, otherwise `radius-lg` |
| Hover / pressed | `color-primary-subtle` / contextual soft surface |

Use icon-only buttons only when the action is conventional and has a tooltip
plus accessible label. The persistent notification bell is an allowed example.

### 6.3 Text inputs and form fields

| Property | Specification |
|---|---|
| Anatomy | visible label, optional required marker, input, helper/error text |
| Min height | `48px`; multiline controls grow naturally |
| Padding | `16px` horizontal, `12px` vertical |
| Background | `color-bg-secondary` |
| Text | `color-text-body`, `font-size-base` |
| Placeholder | `color-text-secondary` |
| Border | `1px color-border` |
| Radius | `radius-lg` |
| Label gap | `8px` |
| Helper/error gap | `4px` |

| State | Exact treatment |
|---|---|
| Resting | `1px color-border` |
| Hover | `1px color-border-strong` on pointer devices |
| Focus | `2px color-primary` border + `3px color-focus-ring` halo |
| Filled | same as resting; never remove label |
| Error | `2px color-error` border; error icon and `font-size-sm` error text |
| Disabled | `color-bg-tertiary` fill, `color-text-disabled`, no hover |
| Read-only | `color-bg-tertiary` fill, `color-text-body`, no disabled opacity |
| Loading options | preserve field size; show progress inside trailing area |

Authentication fields use the landing input surface and Shelter-teal focus tokens but
retain these dimensions and all accessibility states.

### 6.4 Selection controls

| Component | Specification |
|---|---|
| Checkbox / radio | 24px visual control inside a 48px target; selected fill is contextual primary |
| Switch | 52 × 32px visual track inside a 48px high row; selected track is contextual primary |
| Chips | 32px visual height, 48px target when interactive, `radius-full` |
| Segmented control | 48px minimum height; selected state uses subtle surface, primary text, and non-colour selection cue |

Use a label adjacent to each control. Do not use a switch for a decision that
requires confirmation or has destructive consequences.

### 6.5 Cards, rows, and list items

#### Standard card

| Property | Specification |
|---|---|
| Background | `color-bg-secondary` |
| Border | `1px color-border` |
| Radius | `radius-xl` |
| Padding | `spacing-card-padding` (`16px`) |
| Shadow | none by default |
| Gap | `12px` between internal groups |

#### Featured card

Use `24px` padding, `radius-xl`, and optional `shadow-sm`. Reserve for the
landing auth panel, a clear top-priority summary, or a major confirmation.

#### Operational list row

| Anatomy | Rule |
|---|---|
| Identity | avatar/photo or accessible placeholder, 40–48px visual size |
| Primary label | `font-size-base`, weight 600, `color-text-primary` |
| Secondary context | `font-size-sm`, `color-text-secondary` |
| State/context label | compact chip or plain metadata; never colour alone |
| Trailing affordance | chevron, count, or single relevant action only |
| Tap target | entire semantic row; minimum 56px visual row height |

Rows navigate; detail pages explain. Avoid decorative nested cards that obscure
what can be tapped.

### 6.6 Navigation

#### Root app bar

| Property | Specification |
|---|---|
| Height | 64px plus safe-area inset |
| Background | `color-bg-secondary` |
| Border | bottom `1px color-border` when content scrolls under |
| Leading | 48px hamburger target |
| Centre | concise context/brand area |
| Trailing | 48px notification bell target |

Root surfaces use a hamburger. Sub-screens use a back control. Do not add a
generic Home control, top-level tab strip, or duplicate notification centre.

#### Sub-screen back navigation (`returnTo`)

Shell back behaviour is implemented in
`flutter_app/lib/core/router/shell_return_navigation.dart`:

1. **Pop first** — when `Navigator.canPop` is true, pop the stack.
2. **Fallback** — otherwise `context.go` to, in order: explicit `backPath` on
   the screen, safe `returnTo` query param on the current route, then the
   experience section root (`/pc/home` Pet Care, `/o/orgs` shelter).

Entry points that should return to the caller (pet cards, vet pet rows, all
pets list) must use `openPetDetail` (`context.push` + encoded `returnTo`) or
pass `returnTo` on deep links. Default when neither pop nor `returnTo` applies:
**Pet Care dashboard** (`/pc/home`).

Reject external URLs and protocol-relative paths in `returnTo` parsing.

#### Sub-screen contextual actions

| Count | Pattern |
|---|---|
| 0 | No extra app-bar control before the bell |
| 1 primary | Single `IconButton` with tooltip (e.g. add on timeline) |
| 2+ secondary | `ScreenOverflowActions` — `more_vert` menu with **icon + label** rows |

Share, export, and other object-level utilities belong in the overflow menu.
Do not crowd the app bar with multiple icon-only secondary actions.


The drawer is a sparse section switcher:

1. Pet Care
2. Organisation
3. breathing-space divider
4. Account pinned at the bottom

Selected state combines a contextual subtle surface, primary text/icon, and
semantic selected state. Do not place Events, Vets, People, Settings, or
operations inside the global drawer.

#### Organisation profile navigation

Use predictable 56px rows in this exact visible order:

1. Admin contacts
2. People
3. Foster parents
4. Fostering sessions
5. Pets
6. Connected organisations
7. Organisation Administration

Permission-restricted destinations are omitted when the user cannot reasonably
expect them; quiet local gating is used for private actions within an otherwise
available destination.

### 6.7 Notifications

| Property | Specification |
|---|---|
| Entry | one persistent global bell |
| Surface | slide-over on wide screens; full-height sheet on compact screens |
| Width | 100% minus `16px` side inset on compact; 400px max on wide |
| Background | `color-bg-secondary` |
| Elevation | `shadow-lg` |
| Radius | `radius-2xl` for sheet top corners; `radius-xl` desktop panel |

Care and Organisation are filters within one unified panel. Urgent items use a
semantic label and icon, not a red badge alone. Preserve focus on open and
return it to the bell on close.

### 6.8 Status badges and chips

| Status | Background | Text/icon | Required supporting cue |
|---|---:|---:|---|
| Success / completed | `success-100` | `success-500` | “Completed” text or check icon |
| Due / warning | `warning-100` | `warning-500` | “Due” / “Needs attention” text |
| Overdue / error | `error-100` | `error-500` | “Overdue” text and urgency icon |
| Info | `#EDF3FA` | `info-500` | concise explanatory text |
| Pet Care context | `plum-100` | `plum-700` | Pet Care label where needed |
| Organisation context | `teal-100` | `teal-700` | Organisation label where needed |

Badges use `font-size-xs`, weight 700, `radius-full`, 6px horizontal and 4px
vertical padding. They are status support, not the only representation of a
critical state.

### 6.9 Dialogs, sheets, menus, and feedback

| Component | Specification |
|---|---|
| Dialog | max width 480px, `20px` radius, `24px` padding, `shadow-lg` |
| Bottom sheet | safe-area aware, `20px` top radius, visible drag handle, `24px` padding |
| Menu / popover | `8px` radius, `8px` internal padding, `shadow-md` |
| Snackbar | floating, 48px min height, `#1F2937` background, white text, `12px` radius |
| Inline notice | 12px padding, 8px radius, semantic subtle background and border |

Destructive dialogs name the consequence, make the destructive action explicit,
and place the safe/cancel action first. Completion and Undo messages must state
the actual server-confirmed result; never invent a client-only completion state.

### 6.10 Loading, empty, error, and permission states

| State | Required treatment |
|---|---|
| Loading | reserve layout with skeleton or calm progress indicator; do not show empty copy while data is unresolved |
| Empty | precise explanation plus one appropriate action, if one is safe |
| Error | plain language, actionable retry where meaningful, no raw backend message |
| Permission-restricted | explain only when expectation is reasonable; otherwise omit private action surfaces |

Loading controls are disabled rather than repurposed as empty-state actions.
For example, a pet-dependent action remains unavailable until the pet list has
resolved; an actually resolved empty list may then show its appropriate
no-pets guidance.

---

## 7. Mobile and app-store requirements

### 7.1 Touch, safe areas, and platform behavior

```css
:root {
  --touch-target-min: 48px;
  --safe-area-top: env(safe-area-inset-top, 0px);
  --safe-area-right: env(safe-area-inset-right, 0px);
  --safe-area-bottom: env(safe-area-inset-bottom, 0px);
  --safe-area-left: env(safe-area-inset-left, 0px);
}
```

- Treat `48 × 48dp` as the product minimum, exceeding the 44pt iOS baseline.
- Add safe-area insets to full-screen app bars, bottom sheets, sticky actions,
  and bottom navigation surfaces.
- Keep primary actions reachable without relying on edge gestures.
- Do not hide core actions behind hover, right-click, or a mouse-only tooltip.
- Respect system reduced-motion settings and platform text scaling.
- Preserve Flutter web’s native HTML password-manager bridge on authentication
  screens.

### 7.2 Responsive breakpoints

| Range | Name | Layout rules |
|---|---|---|
| `0–599px` | Compact | one-column content; 16px page padding; sheets are full width; stacked form actions when labels wrap |
| `600–839px` | Medium | 24px page padding; Pet Care navigation rail (D-v4-4); drawer hidden in Pet Care workspace |
| `840–1199px` | Expanded | max content width 1120px; Pet Care expanded sidebar (D-v4-4); notification panel may slide over content; dashboard previews can use 2–3 columns |
| `1200px+` | Large | preserve max content width; landing may use story/auth split at approximately 1.05fr / 0.95fr |

The landing/auth experience collapses from its split story/form layout to one
column below `840px`. Auth content has a `430px` max width; story copy has a
`660px` max width.

### 7.3 App-store readiness checklist

- All screens work in portrait orientation; landscape is an enhancement.
- No essential text is clipped by display cut-outs, dynamic island, or system
  navigation areas.
- Keyboard appearance does not hide the currently focused field or primary
  submit action.
- Loading, offline, error, and empty states are designed for every high-level
  destination.
- Labels support English and French expansion without truncating critical
  meaning.
- Dynamic type / font scaling is supported through semantic text styles.
- Icons have semantic labels where their meaning is not obvious.

---

## 8. Motion and accessibility

### Motion

| Interaction | Duration | Rule |
|---|---:|---|
| Button press | 100ms | settle, do not bounce |
| Surface hover | 150ms | pointer enhancement only |
| Drawer / notification panel | 220ms | directional slide |
| Route content swap | 180ms | brief fade/slide aligned with navigation |
| Completion / Undo | 180ms | confirm outcome; keep Undo text clear |

Disable non-essential motion when the platform requests reduced motion. No
looping animation beyond a loading affordance.

### Accessibility acceptance criteria

- Normal text meets **4.5:1** contrast; large text and UI boundaries meet
  **3:1** minimum.
- Focus is visible without relying on shadow alone.
- Every control has a stable, meaningful semantic label.
- State is never communicated by colour alone.
- Interactive targets meet the 48dp minimum.
- Screen-reader order follows visible reading order.
- Modal, drawer, and notification focus is trapped while open and restored to
  the invoking control on close.

---

## 9. Implementation mapping

| Specification area | Flutter implementation source |
|---|---|
| Runtime color constants | `flutter_app/lib/core/theme/app_color_tokens.dart` |
| Material component themes | `flutter_app/lib/core/theme/app_theme.dart` |
| Pet Care / Shelter context overrides | `flutter_app/lib/core/theme/experience_colors.dart` |
| Product decisions and screen behavior | `docs/design/plans/agathatrack-redesign-blueprint.md` |
| Landing reference | approved Pet Care Operations Desk landing mockup |

When implementation needs a value not defined here, add a named token first.
Do not add a literal colour, arbitrary radius, or ad hoc spacing value directly
inside a screen widget.
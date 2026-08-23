---
title: Navigation V2
owner: Documentation Team
audience: both
status: superseded
last_updated: 2026-08-21
tags: [archived,historical]
---

> ⚠️ **ARCHIVED**: This document has been superseded by newer documentation.
> It is kept for historical reference only. Do not use for active development.


# Navigation v2 — specification

> **Status: SUPERSEDED (2026-07-25).** This model did not work for users and is being fully
> reversed by the Experience program — see `docs/experience-program/decisions-log.md` (D1, D2)
> and `docs/experience-program/phase-1-navigation.md`. Kept here as historical record only; do not
> implement new work against this spec.

**Status:** ~~Approved (execute-plan `ui-navigation-v2-14ee`)~~ Superseded — see banner above  
**Supersedes:** Navigation section in `docs/experience-split-plan.md` (2026-07-23)  
**Implementation:** `flutter_app/lib/features/experience/`, `flutter_app/lib/core/router/`

---

## Goals

1. **Stable chrome** — authenticated users always see Hamburger + Home; no top-right shortcuts (notifications, vets, events, avatar menu).
2. **Role-based menus** — guardian vs organisation drawer order and semantic groups are data-driven and identical across screens in each mode.
3. **Maintainable shell** — route metadata selects full vs compact chrome; screens do not implement their own shortcut bars.
4. **Ownership colors** — plum = guardian-owned; green = fostered/org-owned; never color-only (pair with text + icon).

---

## Top chrome

### Full chrome (hubs)

Routes: `/g/home`, `/g/events`, `/g/notifications`, `/g/settings`, `/g/vets`, `/o/home`, `/o/events`, `/o/notifications`, `/o/settings`, `/o/vets`, `/organizations`.

```
┌────────────────────────────────┐
│ ☰ (badge)    Home              │
├────────────────────────────────┤
│  screen body                   │
└────────────────────────────────┘
```

- **Home** disabled or bold on current home route.
- **Hamburger badge** shows combined unread count for the active experience (replaces removed top-bar bell).

### Compact chrome (deep routes)

Routes: `/pet/:id`, `/add`, `/edit/:id`, vet add/edit, health entry forms, org sub-flows (when migrated).

```
┌────────────────────────────────────────┐
│ ☰ (badge)   ← Back    Home   Title   │
├────────────────────────────────────────┤
│  screen body                           │
└────────────────────────────────────────┘
```

- **Back** — `pop` or explicit parent; **Home** — experience home with unsaved-change guard on forms.
- Pet detail: no separate shortcut `SliverAppBar`; photo/title in scrollable body.

### Out of shell

Landing, auth, chooser, onboarding, anonymous shared link.

---

## Drawer — semantic groups

Background fill only (no borders). Text-first labels (not icon-only). Optional `Semantics(header: true)` section titles for screen readers.

| Code | Fill token | Use |
|------|------------|-----|
| **p** (plum group) | `guardianLight` | Guardian-role items in guardian menu |
| **g** (green group) | `organizationLight` | Org-role items in org menu |
| **w** (utility) | `surfaceAlt` | Settings, Help, About, Contact, Legal, Invite, Log out |

Cross-mode switch items use the **destination** mode color (e.g. Organisation view = green group on guardian menu).

### Guardian menu order

| Group | Item | Route / action |
|-------|------|----------------|
| p | My Pets | `/g/home` |
| p | Guardian Notifications | `/g/notifications` |
| p | Events | `/g/events` |
| p | My vets | `/g/vets` |
| — | separator | |
| g | Organisation view | `/organizations` |
| — | separator | |
| w | Settings | `/g/settings` |
| w | Help & FAQ | `/help` |
| w | About us | `/about` |
| w | Contact | `mailto:contact@agathatrack.com` |
| w | Legal Info | `/legal` |
| — | separator | |
| w | Invite | `/g/invite` |
| w | Log out | auth logout |

### Organisation menu order

| Group | Item | Route / action |
|-------|------|----------------|
| g | My Organisation | `/o/home` |
| g | Organisation Notifications | `/o/notifications` |
| g | Events | `/o/events` |
| g | Org vets | `/o/vets` |
| — | separator | |
| p | Guardian view | `/g/home` |
| — | separator | |
| w | Settings … Log out | same utility block as guardian |

Foster portal: hide Invite when `isFosterPortal`.

---

## Post-login

| User | Destination |
|------|-------------|
| Guardian only | `/g/home` (or `/g/onboarding` if no owned pets) |
| Org only | `/o/home` (or `/o/onboarding`) |
| Dual-role | `/app/choose` with **Guardian card pre-selected**; Continue → `/g/home` |

Remember checkbox persists default in Settings → Default experience.

---

## Ownership accents

Central helper: `ownership_accent.dart` (or `resolvePetOwnershipAccent`).

| Entity state | Accent | Label example |
|--------------|--------|---------------|
| Guardian-owned pet | Plum (`guardianPrimary`) | — |
| Fostered / org-linked pet | Green (`organizationPrimary`) | “In foster care” (always green + icon) |
| Personal vet | Plum | — |
| Org vet | Green | — |
| Guardian-scoped notification | Plum cues | — |
| Org-scoped notification | Green cues | — |
| Super admin tag | Warm coral (`orgSuperUserBg/Fg`) | Not plum/green |

---

## Organisation surfaces

| Screen | Background | Cards | Borders |
|--------|------------|-------|---------|
| Org list | `organizationLight` | `surface` (off-white) | none |
| Org detail | `organizationLight` | `surface` modules | none or subtle green |
| Primary actions / icons | `organizationPrimary` | | |

Create organisation: primary `FilledButton` on org list.

---

## Vets (summary)

- API: `vets.organization_id` nullable (null = personal).
- Routes: `/g/vets`, `/o/vets` (+ add/edit); redirect legacy `/vets`.
- Filter: chips `All` | `My vets` | per-org (dropdown if >3 orgs).
- Card: name, town, phone; call + edit icon buttons; delete on edit screen.
- Bottom: “Add a vet” primary button.

---

## Router metadata (target)

```dart
// shell_route_metadata.dart
enum ShellChromeMode { full, compact, none }

ShellChromeMode chromeForPath(String path);
AppExperience experienceForPath(String path, {Pet? contextPet});
```

New authenticated routes **must** register chrome mode in `app_router.dart` / `experience_routes.dart`.

---

## Migration tiers

| Tier | Routes | Status |
|------|--------|--------|
| 1 Hubs | `/g/*` home area, `/o/*` hubs, `/organizations` | execute-plan phases 2–5 |
| 2 Deep | pet detail, forms, vet forms | execute-plan phase 10+ (debt until done) |
| 3 Long tail | help, paywall, transfer flows | `docs/debt/refactoring-debt.md` |
| 4 Excluded | landing, shared anonymous | — |

---

## Testing expectations

- Widget: drawer order keys, chrome mode resolver, ownership accent.
- BDD: `experience_navigation.feature` — chooser pre-select; drawer destinations.
- E2E: `experience.navigation.spec.ts` — shell has Home + menu, **not** Events in top bar.
- axe (`@smoke-a11y`): landing cards, post-login shell, drawer open.

---

## Related docs

- `docs/design/tokens.md` — color tokens and drawer groups
- `docs/experience-split-plan.md` — experience URLs and chooser (amended)
- `docs/design/ui-rework-plan.md` — visual rework phases

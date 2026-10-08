---
title: Navigation decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-08
tags: [navigation, decisions]
domain: navigation
feature_id: navigation-decisions
---

# Navigation — locked decisions

Product decisions for shell navigation, drawer, header, and Account routing (D1–D6, D27). Other domains reference these IDs instead of restating rationale. Status values: `locked`, `tbd`, `deferred`.

Source: experience-program analysis + Q&A, 2026-07-25. Master brief: [navigation-brief.md](navigation-brief.md).

---

## A — Navigation reversal

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D1** | Navigation v2 (`docs/archived/navigation-v2.md`) is **fully reversed**, not extended. It did not work for users. The new [navigation-brief.md](navigation-brief.md) model (hamburger = section switcher only; bell = notifications; no sitemap drawer) replaces it. | locked | Phase 1 |
| **D2** | `docs/archived/navigation-v2.md` is kept as historical record, header-tagged **superseded**, not deleted. Same treatment `docs/archived/experience-split-plan.md` already received. | locked | Phase R |
| **D3** | Events and Vets are **removed from the drawer** entirely. They surface only via dashboard preview sections + their own full screens (`/pc/events`, `/pc/vets`, `/o/vets`, org pets/fosters screens). | locked | Phase 1 |
| **D4** | The header "Home" button from nav v2 is also removed (not requested by the new brief, and reintroducing it would recreate the "generic Home" pattern D1 rejects). Header controls become: hamburger (section switch, dashboards) **or** back arrow (sub-screens), plus a persistent bell (all authenticated screens). | locked | Phase 1 |
| **D5** | Drawer is **not mode-dependent**. It always shows the same two peer items (**Pet Care**, Shelter) plus bottom-pinned Account — never a long per-mode list. (D38: drawer labels **Pet Care** / **Suivi** and **Shelter** / **Refuges**; legacy brief used "Guardian".) | locked | Phase 1 |
| **D6** | `org-mode-navigation-acf1` (branch `cursor/org-mode-nav-phase3-shell-acf1`, control issue #262) is **closed, not resumed**. Its only unmerged phase (router-file extraction) is superseded by Phase 3's from-scratch `organization_routes.dart` rewrite; merging then immediately rewriting wastes a review cycle. Close-out: [Phase R reconciliation (folded)](#phase-r-reconciliation-folded). | locked | Phase R |

## G (navigation) — Account and cross-org settings

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D27** | Cross-org, personal settings (profile, cross-org notification defaults, help/FAQ/contact/legal/about, sign out) live under the global **Account** area (D1's navigation model), reached independently of any single organisation. | locked | Phase 1 |

## B — Pet Care primary navigation (compact + adaptive)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v4-1** | On compact Pet Care widths (&lt;600px), a **five-tab bottom bar** exposes Today (`/pc/home`), Pets (`/pc/pets`), Care (`/pc/events`), Fostering (`/pc/fostering`), and Account (`/account`). This **supersedes** blueprint §15 anti-pattern “five-tab bottom navigation bar” and is the approved mobile primary nav for Pet Care operational work. | locked | Pet Care ops desk 2026-08 |
| **D-v4-2** | **Account entry:** On compact widths (&lt;600px), `/account` is reachable from the Pet Care bottom bar **and** the drawer while the drawer remains available. On medium+ widths where leading nav is visible (D-v4-4), Account is reachable from the leading nav footer/rail and the drawer is **retired** — dual drawer entry ends. **Shelter clause superseded (2026-09):** Shelter now has its own primary nav destinations (D-shelter-NAV-1); workspace switching stays in the shell workspace switcher on all screens (D-v5-WORKSPACE-4). | locked | Pet Care adaptive nav 2026-08; Shelter clause → [shelter-dashboard-v2-framing-decisions.md](/docs/domains/shelter/changes/shelter-dashboard-v2-framing-decisions.md) |
| **D-v4-3** | Section roots (`/pc/home`, `/o/orgs`, `/account`) show the **workspace toggle** in the shell leading area instead of a back arrow. On compact Pet Care routes the toggle sits in the app bar; on medium+ it moves to the leading nav shell header (D-v4-5). Compact Pet Care primary routes also use plum app bar + bottom bar chrome. | locked | Pet Care adaptive nav 2026-08 |
| **D-v4-4** | On Pet Care widths **≥600px**, the same five destinations as D-v4-1 appear in **leading application chrome** (navigation rail 600–839px; expanded sidebar ≥840px). This is primary shell navigation — **not** the hamburger drawer. The drawer must not duplicate these destinations. | locked | Pet Care adaptive nav 2026-08 |
| **D-v4-5** | When leading nav is visible (≥600px Pet Care workspace), the hamburger **drawer is hidden**. Workspace switcher and brand live in the leading nav shell header; Account is pinned at the bottom of expanded sidebar (≥840px) or exposed as the fifth rail destination (600–839px). | locked | Pet Care adaptive nav 2026-08 |

## H — Shell hierarchy (brand once per context)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-shell-1** | **One product identity per navigation context** — when leading nav is visible (≥600px), `AgathaTrack` appears only in leading chrome, not duplicated in the app bar on section roots. | locked | shell-hierarchy 2026-09 |
| **D-shell-2** | Section roots (`/pc/home`, `/o/orgs`, `/account`) with leading nav: **omit** app bar title when it repeats product/section identity; dashboard home uses active nav state + body. | locked | shell-hierarchy 2026-09 |
| **D-shell-3** | Contextual app bar titles on deep routes (pet name, “All pets”, “Events”, etc.). | locked | shell-hierarchy 2026-09 |
| **D-shell-4** | Workspace toggle labels **Pet Care** / **Shelter**; **Actions** stays primary nav (`/pc/events`). | locked | shell-hierarchy 2026-09 |
| **D-shell-5** | Mobile (&lt;600px): plum app bar keeps `AppLogoTitle` + workspace toggle + bell. | locked | shell-hierarchy 2026-09 |
| **D-shell-6** | Tablet rail header: compact brand above workspace toggle; no duplicate product title on section roots. | locked | shell-hierarchy 2026-09 |
| **D-shell-7** | Desktop sidebar header: brand → workspace toggle → divider → primary nav → footer Account. | locked | shell-hierarchy 2026-09 |
| **D-shell-8** | Notification bell globally accessible; on medium+ prefer content-column placement (behaviour unchanged). | locked | shell-hierarchy 2026-09 |
| **D-shell-9** | Workspace toggle visual weight below brand (scope below identity). | locked | shell-hierarchy 2026-09 |
| **D-shell-10** | Out of scope: dashboard body sections, org `/o/orgs` brand parity debt, Actions vs Events label debt. | locked | shell-hierarchy 2026-09 |

| Width | Brand | Workspace | Primary nav | App bar (section root) |
|-------|-------|-----------|-------------|------------------------|
| &lt;600px | App bar logo | App bar toggle | Bottom nav | Centered title |
| 600–839px | Rail header | Rail toggle | Navigation rail | **Suppressed** |
| ≥840px | Sidebar header | Sidebar below brand | Sidebar + Account footer | **Suppressed** |

## I — Workspace navigation simplify (2026-09)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v5-WORKSPACE-1** | Shelter workspace always visible; remove Account org-section toggle (**supersedes D-v3-VIS-1**). | locked | workspace-nav-simplify |
| **D-v5-WORKSPACE-2** | Everyone lands on `/pc/home` after login; no `last_app_section` or `/app/choose`. | locked | workspace-nav-simplify |
| **D-v5-WORKSPACE-3** | Canonical shelter root `/o/orgs`; `/o/home` redirects. | locked | workspace-nav-simplify |
| **D-v5-WORKSPACE-4** | Workspace toggle on every authenticated screen (extends D-v4-3). | locked | workspace-nav-simplify |
| **D-v5-WORKSPACE-5** | Fostering dashboard invite/thank-you copy + illustrations (`guardian-foster-invite.png`, `guardian-foster-thanks.png`). | locked | workspace-nav-simplify |

Deferred: hash→path URL migration; first-connection tour; `/g/*` legacy removal.

## J — Shelter primary navigation (2026-09)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-shelter-NAV-1** | Shelter primary destinations: **Dashboard** (`/o/orgs`), optional **pinned org** (`/o/orgs/:id`), **Discover**, **Account** (`/account`). Same breakpoints as D-v4-4. **Persistent** on org deep routes. **Supersedes** D-desk-S5 and the Shelter clause of D-v4-2. | locked | shelter-dashboard-v2-c4e8 |
| **D-shelter-NAV-2** | **One pinned org** per user (account preference, cross-device). Pin control on membership tile cover; nav slot hidden when unset; target `/o/orgs/:id`. | locked | shelter-dashboard-v2-c4e8 |
| **D-shelter-NAV-3** | **Five-slot nav geometry** aligned with Pet Care bar; inactive centre spacer when pinned org unset. | locked | shelter-dashboard-v2-c4e8 |

Full detail: [shelter-dashboard-v2-framing-decisions.md](/docs/domains/shelter/changes/shelter-dashboard-v2-framing-decisions.md). **D-v3-IA-2** amended there — Discover moves from hub body row to primary nav.

## K — Folded delivery phases (history)

Documentation-only summaries; implementation complete. Supersedes removed `changes/phase-*` files.

### Phase R reconciliation (folded)

Close conflicting work before new navigation: mark `docs/archived/navigation-v2.md` superseded (D2); close `org-mode-navigation-acf1` / issue #262 (D6); tag legacy BDD scenarios; publish domain docs. No product behaviour changes in the doc phase.

### Phase 0 foundation (folded)

Shared shell primitives and scaffolding without user-visible navigation change. Settings audit mapped Account vs org settings destinations (feeds Phase 1 routing).

### Phase 1 shell navigation (folded)

Ship drawer (Pet Care / Shelter + Account), header (hamburger/back + bell, no Home), unified notification slide-over, `/account` route; retire `/pc/notifications`, `/o/notifications`, and per-mode Settings entry points per audit. Dashboard **content** unchanged in this phase.

---

## How to use

- New navigation decision → add a row here first, then implement.
- A decision proves wrong → update the row and note the phase/PR that revised it.
- Phase docs link to decision IDs; they do not re-explain rationale.
- Related: [notifications-v2-spec §18](/docs/domains/notifications/features/notifications-v2-spec.md#18-decision-log-legacy--b--v2-supersession) (D7–D11), [delivery-decisions.md](/docs/domains/cross-domain/features/delivery-plans-index.md) (D32–D33).

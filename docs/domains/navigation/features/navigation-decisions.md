---
title: Navigation decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-26
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
| **D6** | `org-mode-navigation-acf1` (branch `cursor/org-mode-nav-phase3-shell-acf1`, control issue #262) is **closed, not resumed**. Its only unmerged phase (router-file extraction) is superseded by Phase 3's from-scratch `organization_routes.dart` rewrite; merging then immediately rewriting wastes a review cycle. See [phase-r-reconciliation.md](../changes/phase-r-reconciliation.md) for close-out steps. | locked | Phase R |

## G (navigation) — Account and cross-org settings

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D27** | Cross-org, personal settings (profile, cross-org notification defaults, help/FAQ/contact/legal/about, sign out) live under the global **Account** area (D1's navigation model), reached independently of any single organisation. | locked | Phase 1 |

## B — Pet Care primary navigation (compact + adaptive)

| ID | Decision | Status | Phase |
|----|----------|--------|-------|
| **D-v4-1** | On compact Pet Care widths (&lt;600px), a **five-tab bottom bar** exposes Today (`/pc/home`), Pets (`/pc/pets`), Care (`/pc/events`), Fostering (`/pc/fostering`), and Account (`/account`). This **supersedes** blueprint §15 anti-pattern “five-tab bottom navigation bar” and is the approved mobile primary nav for Pet Care operational work. | locked | Pet Care ops desk 2026-08 |
| **D-v4-2** | **Account entry:** On compact widths (&lt;600px), `/account` is reachable from the Pet Care bottom bar **and** the drawer while the drawer remains available. On medium+ widths where leading nav is visible (D-v4-4), Account is reachable from the leading nav footer/rail and the drawer is **retired** — dual drawer entry ends. Shelter workspace switching stays in the shell workspace switcher — not in the bottom bar or leading nav destination list. | locked | Pet Care adaptive nav 2026-08 |
| **D-v4-3** | Section roots (`/pc/home`, `/o/orgs`, `/account`) show the **workspace toggle** in the shell leading area instead of a back arrow. On compact Pet Care routes the toggle sits in the app bar; on medium+ it moves to the leading nav shell header (D-v4-5). Compact Pet Care primary routes also use plum app bar + bottom bar chrome. | locked | Pet Care adaptive nav 2026-08 |
| **D-v4-4** | On Pet Care widths **≥600px**, the same five destinations as D-v4-1 appear in **leading application chrome** (navigation rail 600–839px; expanded sidebar ≥840px). This is primary shell navigation — **not** the hamburger drawer. The drawer must not duplicate these destinations. | locked | Pet Care adaptive nav 2026-08 |
| **D-v4-5** | When leading nav is visible (≥600px Pet Care workspace), the hamburger **drawer is hidden**. Workspace switcher and brand live in the leading nav shell header; Account is pinned at the bottom of expanded sidebar (≥840px) or exposed as the fifth rail destination (600–839px). | locked | Pet Care adaptive nav 2026-08 |

---

## How to use

- New navigation decision → add a row here first, then implement.
- A decision proves wrong → update the row and note the phase/PR that revised it.
- Phase docs link to decision IDs; they do not re-explain rationale.
- Related: [notification-decisions.md](/docs/domains/notifications/features/notification-decisions.md) (D7–D11), [delivery-decisions.md](/docs/domains/cross-domain/changes/delivery-decisions.md) (D32–D33).

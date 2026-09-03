---
title: Workspace navigation simplify decisions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-03
tags: [navigation, decisions]
domain: navigation
---

# Workspace navigation simplify — locked decisions

Product decisions from UAT dual-role testing (shelter admin + pet care), 2026-09-03. Supersedes **D-v3-VIS-1** (org section visibility toggle).

Plan: `workspace-nav-simplify-8c14`.

---

## D-v5-WORKSPACE-1 — Shelter always visible

| Field | Value |
|-------|-------|
| **Decision** | Workspace switcher and drawer always expose **Shelter** for every authenticated user. Remove Account **Show shelters section** preference and `OrganisationSectionVisibility` gating. |
| **Status** | locked |
| **Supersedes** | D-v3-VIS-1 |

Non-members still open `/o/orgs` with a friendly empty state.

---

## D-v5-WORKSPACE-2 — Single login landing

| Field | Value |
|-------|-------|
| **Decision** | After login, **everyone** lands on `/pc/home` (including org-only and empty accounts). Remove `last_app_section` restore and `/app/choose` FTUE redirect. |
| **Status** | locked |

Guardian onboarding (`/pc/onboarding`) still applies when the user has no owned pets and has not completed onboarding.

---

## D-v5-WORKSPACE-3 — Canonical shelter root

| Field | Value |
|-------|-------|
| **Decision** | Canonical organisation workspace root is **`/o/orgs`**. `/o/home` redirects to `/o/orgs`. `AppExperience.organization.homePath()` returns `/o/orgs`. |
| **Status** | locked |

---

## D-v5-WORKSPACE-4 — Global workspace switcher

| Field | Value |
|-------|-------|
| **Decision** | Workspace toggle (Pet Care / Shelter) is reachable on **every authenticated screen**. Compact: toggle in app bar (back + toggle on non-root). Medium+: toggle in rail/sidebar header; content chrome shows back on non-root. |
| **Status** | locked |
| **Extends** | D-v4-3 (section-root-only placement) |

---

## D-v5-WORKSPACE-5 — Fostering dashboard copy

| Field | Value |
|-------|-------|
| **Decision** | Care dashboard fostering section uses warm invite copy when no shelter link (`Make room for one more` / Find a shelter) and thank-you copy when linked (`Thank you for being part of their journey` / Your shelters / Find another shelter). |
| **Status** | locked |

Illustrations: `assets/dashboard/guardian-foster-invite.png`, `guardian-foster-thanks.png`.

---

## Deferred

| Item | Notes |
|------|-------|
| Hash → path URL migration | Late PR after routing stable |
| First-connection tour | Future; must not block visibility fixes |
| `/g/*` legacy removal | Schedule in follow-up |

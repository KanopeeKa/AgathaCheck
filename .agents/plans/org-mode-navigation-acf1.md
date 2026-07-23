# Org mode navigation — execute plan

> **plan_id:** `org-mode-navigation-acf1`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `org-mode-navigation-acf1` |
| **title** | Org mode navigation basics |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Formalise the org-mode user journey: guardian users without org membership can enter org mode via the hamburger and the onboarding wizard; org-mode screens show a structured drawer (org list, scoped notifications, My pets, settings/help/about/contact/legal); notification lists filter owned vs foster pets; Events moves from org top nav into the drawer.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Guardian drawer | Keep current items; add **Create an organisation** anytime (switches to org mode → `/o/onboarding`) |
| Dual-role guardian | Keep **Organisation view** switch |
| Org top nav | **Home only**; Events in drawer below Org notifications |
| Foster portal drawer | Same new org drawer (org list + My pets) |
| Contact | `contact@agathatrack.com` mailto link |
| After wizard | Land on `/o/home` |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-07-22T12:31:00Z` |
| **approved_until** | `2026-07-24T12:31:00Z` |
| **control_issue** | #262 |
| **autonomy** | `active` |

## Phases

### Phase 1 — Notification scope rules

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/org-mode-nav-phase1-scope-acf1` |
| **exit_checklist** | `default` |

**Scope:** `NotificationScopeRules`, scoped unread providers, `NotificationsScreen(scope:)`.

**Exit criteria:**

- [ ] Unit tests for owned vs foster vs org-inventory filtering
- [ ] Guardian and org unread count providers

### Phase 2 — Org-mode drawer and top-nav

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/org-mode-nav-phase2-drawer-acf1` |
| **exit_checklist** | `flutter-screen-split` |

**Scope:** Split drawers; org drawer structure; guardian Create org entry; remove Events from org app bar.

### Phase 3 — Org shell coverage and Contact screen

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/org-mode-nav-phase3-shell-acf1` |
| **exit_checklist** | `flutter-screen-split` |

**Scope:** `/o/orgs/*` routes in shell; redirects from `/organizations/*`; Contact screen.

### Phase 4 — BDD and Playwright org-mode journey

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/org-mode-nav-phase4-bdd-acf1` |
| **exit_checklist** | `bdd-journey` |

**Scope:** `org_mode_navigation.feature`, Playwright spec, API seeds for notification scenarios.

## Runtime state

```yaml
autonomy: halted
current_phase: 3
last_completed_phase: 2
halt_reason: halted
next_action: "start phase 3: checkout cursor/org-mode-nav-phase3-shell-acf1"
artifact_ref:
  branch: cursor/sync-org-mode-plan-snapshot-acf1
  plan_path: .agents/plans/org-mode-navigation-acf1.md
  plan_commit: c9d1b33da490801d670955a5525770bb9d9f8447
  snapshot_path: .agents/plans/org-mode-navigation-acf1.snapshot.json
  snapshot_commit: c9d1b33da490801d670955a5525770bb9d9f8447
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

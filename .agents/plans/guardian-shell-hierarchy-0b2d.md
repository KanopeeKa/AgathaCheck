# Guardian shell hierarchy — execute plan

> **plan_id:** `guardian-shell-hierarchy-0b2d`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-shell-hierarchy-0b2d` |
| **title** | Guardian responsive shell hierarchy — brand, context, navigation |
| **author** | agent (analysis 2026-09-02; plan 2026-09-03) |
| **created** | 2026-09-03 |
| **base_branch** | `cursor/guardian-shell-hierarchy-0b2d-integration-0b2d` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Harmonize the Guardian responsive app shell so **AgathaTrack appears once per navigation context** across mobile, tablet, and desktop. Remove the desktop/tablet duplicate product title in the main app bar when persistent leading navigation already carries brand; add intentional tablet rail branding; refine visual hierarchy (brand → workspace scope → navigation → global actions) without changing dashboard content, selector behaviour, or navigation destinations.

**Parent context:** Builds on completed `guardian-adaptive-nav-7221` (rail/sidebar/bottom nav). This plan is a hierarchy refinement, not a rebrand or IA change.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Brand once per context | Desktop/tablet: brand lives in persistent leading nav only on **section roots** (`/g/home`, `/o/orgs`, `/account`). Mobile: brand stays in compact plum app bar. |
| Section roots | `DrawerMenuConfig.sectionRootPaths` — workspace toggle placement unchanged. |
| Dashboard home title | **No** large `AgathaTrack` in app bar when sidebar/rail visible. Active Dashboard nav + dashboard body establish context. |
| Context control | `ExperienceWorkspaceToggle` label remains **My Pets** / **Shelter** — not renamed to “Care”. Care stays a nav destination (`/g/events`). |
| Deep / contextual screens | App bar `screenTitle` **retained** for pet names, “All pets”, “Events”, etc. — informational, not product brand. |
| Dashboard content | **Out of scope** — no pet cards, Care Tasks, Care Team, or section title changes. |
| Selector / notifications | Behaviour unchanged; placement may shift visually in Phase 4 only. |
| Tablet rail brand | Compact treatment in rail header (logo-only or logo + wordmark) — must fit 120px rail without enlarging branding on wide screens. |
| Mobile drawer | Drawer brand header remains; low-frequency edge-swipe path. No second brand in dashboard body. |
| Org experience | **Deferred** — Guardian-only in this plan; org `/o/orgs` parity tracked as debt if needed after Phase 2. |
| Care vs Events label | Nav label “Care” vs app bar “Events” on `/g/events` — **deferred** (debt issue), not blocking hierarchy fix. |

## Design audit (`/ui-design-deep`)

Reference: `docs/design/principles.md`, `docs/design/index.md`, `.cursor/rules/design.mdc`.

### 1. Problem

On desktop (≥840px), AgathaTrack appears twice on `/g/home`: in `GuardianNavigationSidebar` (`AppLogoTitle`) and in the app bar (`usesGuardianDesktopContentHeader` → `Text(screenTitle)`). On tablet (600–839px), brand exists only in the app bar while the rail has workspace toggle but no product identity — an inverted hierarchy. Mobile is largely correct.

### 2. Why it matters

Repeated product labels compete with workspace scope and navigation, making desktop feel like a mobile header stacked beside a sidebar. Users lose the intended layers: product identity → workspace scope → destination → content.

### 3. UX impact

- **Requirement:** Desktop home should start with dashboard content, not a redundant product heading.
- **Requirement:** Tablet should read as intentional intermediate chrome, not “icons only + floating title”.
- **Recommendation:** Demote workspace toggle visual weight (currently w700 stadium pill) so it reads as scope, not a second title.

### 4. A11y impact

- **Requirement:** Suppressing duplicate visible titles must preserve screen-reader context via nav `selected` state and existing semantics identifiers (`guardian_nav_dashboard`, etc.).
- **Requirement:** Rail brand addition needs `semanticLabel` on logo; touch targets ≥48dp unchanged.

### 5. System impact

- **Requirement:** Change centres on `ExperienceShellScaffold` title routing and `GuardianNavigationRail` header — reuse `AppLogoTitle` / `LogoAssets`, no new design system.
- **Recommendation:** Extract a small `GuardianShellTitlePolicy` helper (or shell private method) so section-root vs contextual title rules are testable in one place.

### 6. Proposed fix (system order)

1. **Rule:** When `usesGuardianLeadingNav && isSectionRoot && screenTitle == l.appTitle` → omit app bar title.
2. **Component:** Compact `GuardianNavigationRailBrand` (logo-only at 120px) above workspace toggle.
3. **Screen:** `GuardianHomeScreen` may pass `screenTitle: null` on wide layouts or rely on shell policy.
4. **Flow:** Mobile unchanged; tablet/desktop gain single brand anchor in leading nav.
5. **Chrome (Phase 4):** Optional content-column app bar strip for notification bell; sidebar header spacing rhythm (brand 12px → toggle 8px → divider).

### 7. Reusable rule

> **One product identity per navigation context.** Persistent leading navigation owns brand on medium+; app bar carries contextual page titles only. Mobile app bar owns brand because there is no persistent leading nav.

### 8. Implementation notes

| File | Role |
|------|------|
| `experience_shell_scaffold.dart` | Title suppression policy; optional content-column app bar |
| `guardian_navigation_sidebar.dart` | Spacing/weight tweaks only if needed |
| `guardian_navigation_rail.dart` | Rail brand header |
| `experience_home_screens.dart` | Stop passing `appTitle` or defer to shell policy |
| `app_logo_title.dart` | `showTitle: false` variant for rail logo-only |
| `docs/e2e/navigation-contract.md` | Breakpoint expectations |
| `docs/domains/navigation/changes/shell-hierarchy-decisions.md` | Locked decisions (Phase 1) |

### 9. Acceptance checklist (plan-wide)

- [ ] Theme tokens, not scattered colors
- [ ] Focus visible; touch ≥48dp
- [ ] l10n / enum labels unchanged unless debt issue opened
- [ ] Empty, loading, error states unaffected
- [ ] Guardian experience (`/g/*`) only in implementation phases
- [ ] `./scripts/pre-push-changed.sh` per phase; `./scripts/pre-push.sh` before integration→main
- [ ] E2E/BDD updated in Phase 5 for hierarchy at 390px / 720px / 1024px

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-03T07:22:00Z` |
| **approved_until** | `2026-09-05T07:22:00Z` |
| **approved_by** | user chat 2026-09-03 (/execute-plan phases 1-4 authorization) |
| **control_issue** | #877 |
| **content_hash** | frozen at approval |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous guardian-shell-hierarchy-0b2d`

## Sanity check

**proceed** — 5 phases, Guardian Flutter shell only, no API/migrations. Cross-cutting shell + docs + E2E; integration branch. Lower risk than `guardian-adaptive-nav-7221` because IA and behaviour are locked.

## Runtime state

```yaml
autonomy: active
current_phase: "1"
last_completed_phase: null
halt_reason: null
next_action: "start phase 1: cursor/shell-hierarchy-decisions-0b2d"
artifact_ref:
  branch: null
  plan_path: .agents/plans/guardian-shell-hierarchy-0b2d.md
  plan_commit: null
  snapshot_path: .agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Shell hierarchy decisions & navigation contract

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/shell-hierarchy-decisions-0b2d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/navigation/changes/shell-hierarchy-decisions.md
docs/domains/navigation/features/navigation-decisions.md
docs/e2e/navigation-contract.md
docs/debt/refactoring-log.md
.agents/plans/guardian-shell-hierarchy-0b2d.md
.agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Add `docs/domains/navigation/changes/shell-hierarchy-decisions.md` with locked D-shell-* decisions (brand-once rule, section-root title policy, tablet rail brand, deferred org parity + Care/Events naming).
- Update `navigation-contract.md` §Guardian expanded sidebar and §leading rail with expected brand/title behaviour at each breakpoint.
- Log sprint entry in `refactoring-log.md`.

**Exit criteria:**

- [ ] Decisions doc merged; navigation contract describes one-brand-per-context at 600px / 840px / &lt;600px
- [ ] No Flutter code changes

---

### Phase 2 — Desktop single brand (≥840px)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/shell-hierarchy-desktop-0b2d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart
flutter_app/lib/features/experience/presentation/screens/experience_home_screens.dart
flutter_app/lib/features/experience/presentation/config/drawer_menu_config.dart
flutter_app/lib/core/widgets/app_logo_title.dart
flutter_app/test/features/experience/presentation/widgets/experience_shell_scaffold_test.dart
flutter_app/test/features/experience/presentation/screens/experience_home_screens_test.dart
.agents/plans/guardian-shell-hierarchy-0b2d.md
.agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_rail.dart
```

**Scope:**

- Suppress app bar product title on Guardian section roots when `GuardianNavigationSidebar` is visible.
- `GuardianHomeScreen`: do not surface `l.appTitle` in app bar at expanded breakpoint.
- Widget tests at 1024px: exactly one visible “AgathaTrack” on `/g/home`; bell still present; sidebar brand + workspace toggle unchanged.

**Exit criteria:**

- [ ] Desktop home shows AgathaTrack once (sidebar only)
- [ ] `/account` section root: no duplicate “Account” in app bar when sidebar footer shows Account (if same policy applies)
- [ ] Deep screens (e.g. `/g/pets` “All pets”) still show contextual app bar title
- [ ] `experience_shell_scaffold_test.dart` green at 1024px

---

### Phase 3 — Tablet rail brand & title suppression (600–839px)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/shell-hierarchy-tablet-0b2d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_rail.dart
flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart
flutter_app/lib/core/widgets/app_logo_title.dart
flutter_app/lib/core/branding/logo_assets.dart
flutter_app/test/features/experience/presentation/widgets/experience_shell_scaffold_test.dart
flutter_app/test/features/experience/presentation/widgets/guardian_navigation_rail_test.dart
.agents/plans/guardian-shell-hierarchy-0b2d.md
.agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Add compact brand header to `GuardianNavigationRail` (logo-only or truncated wordmark within 120px).
- Suppress app bar `l.appTitle` on section roots at medium breakpoint.
- Preserve workspace toggle in rail `leading` below brand; maintain 48dp targets.

**Exit criteria:**

- [ ] 720px home: brand in rail, not in app bar; one AgathaTrack visible
- [ ] Rail + content Row layout unchanged; bottom nav hidden
- [ ] New/updated widget tests for rail brand semantics

---

### Phase 4 — Shell chrome polish (spacing, toggle weight, notification association)

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/shell-hierarchy-chrome-0b2d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_sidebar.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_rail.dart
flutter_app/lib/features/experience/presentation/widgets/experience_workspace_toggle.dart
flutter_app/lib/core/widgets/shell_notification_bell.dart
flutter_app/test/features/experience/**
.agents/plans/guardian-shell-hierarchy-0b2d.md
.agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Demote workspace toggle visual weight (e.g. w600 / subtler border) so it reads as scope, not page title.
- Tune sidebar/rail vertical rhythm (brand → toggle → nav divider).
- **Recommendation:** Restrict app bar to content column on medium+ so notification bell associates with main area, not sidebar column — only if achievable without layout regression; otherwise document debt and keep bell in full-width bar.

**Exit criteria:**

- [ ] Brand, workspace toggle, and nav read as three distinct hierarchy layers in manual review
- [ ] Notification bell remains accessible at all breakpoints
- [ ] No dashboard content changes
- [ ] `/ui-check` pass on touched shell widgets

---

### Phase 5 — BDD/E2E hierarchy verification

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/shell-hierarchy-e2e-0b2d` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `bdd-journey` |

**allowed_paths:**

```
flutter_app/test/bdd/features/guardian_dashboard.feature
flutter_app/test/features/experience/**
e2e/playwright/tests/**
e2e/playwright/support/**
docs/e2e/navigation-contract.md
docs/quality/bdd-journey-matrix.md
.agents/plans/guardian-shell-hierarchy-0b2d.md
.agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
```

**Scope:**

- Gherkin scenarios: single brand visible at desktop and tablet home; mobile app bar brand preserved.
- Playwright viewport checks at 390px / 720px / 1024px using existing page objects.
- Final navigation-contract sync.

**Exit criteria:**

- [ ] BDD scenarios mapped; `check_bdd_coverage.js` passes
- [ ] Playwright hierarchy assertions green locally
- [ ] `@smoke-ci` canary unaffected or updated

---

## Final merge

After all phases `merged` into `cursor/guardian-shell-hierarchy-0b2d-integration-0b2d`, open **one** PR integration → `main` with `./scripts/pre-push.sh` and **/babysit-uat**.

## Revoke and resume

| Action | How |
|--------|-----|
| **Revoke** | Add `autonomous-revoked` on control issue |
| **Resume** | Remove revoke; comment `resume-plan guardian-shell-hierarchy-0b2d` |

## Checklist before `approve-autonomous`

- [ ] Snapshot validates: `node scripts/validate_execute_plan_snapshot.js .agents/plans/guardian-shell-hierarchy-0b2d.snapshot.json`
- [ ] Control issue has labels `execute-plan`, `plan:guardian-shell-hierarchy-0b2d`, `autonomous-approved`
- [ ] `default_merge_mode: auto` on snapshot
- [ ] `content_hash` frozen after approval comment

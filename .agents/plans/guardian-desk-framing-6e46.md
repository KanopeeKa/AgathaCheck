# Guardian dashboard desk framing — execute plan

> **plan_id:** `guardian-desk-framing-6e46`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-desk-framing-6e46` |
| **title** | Guardian dashboard shell framing — surfaces, section chrome, canvas |
| **author** | agent (ui-design-deep analysis 2026-09-03) |
| **created** | 2026-09-03 |
| **base_branch** | `cursor/guardian-desk-framing-6e46-integration-6e46` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Refine the Guardian Pet Care dashboard shell and content framing on web/tablet so navigation, workspace canvas, and section previews read as distinct hierarchy levels — without redesigning row/card components. Builds on completed adaptive nav (`guardian-adaptive-nav-7221`) and shell hierarchy (`guardian-shell-hierarchy-0b2d`).

**Parent context:** ui-design-deep analysis identified shell/canvas surface unification, below-content “All …” links, and tinted section card layering as the primary gaps.

## Locked product decisions

| Topic | Decision |
|-------|----------|
| Shell separation | Sidebar/rail uses raised nav surface (`surface`); main workspace canvas uses `background`. No vertical dividers or card-wrapped sidebar. |
| Section chrome | Eyebrow title + trailing “All …” on one row when a real destination exists; content below. Supersedes brief’s bottom-only “All …” placement for dashboard previews. |
| Section surfaces | Open canvas default; remove tinted `GuardianDeskSectionCard` wrappers on Care/Care Team home previews. Fostering org tint may remain. |
| Pets eyebrow | Optional — do not add PETS eyebrow if pet rail reads as hero; align “All pets” to header row when shown. |
| Max width | Canonical dashboard grid **1120px** (align `system.md`); responsive padding 16/24/32 by breakpoint. Home first; hub routes optional in phase 5. |
| Active nav | Sidebar selected state: one primary channel (prefer left bar + colour; drop or reduce fill). |
| Mobile | No desktop sidebar framing on compact; plum app bar + bottom nav unchanged. |
| Component scope | Do not redesign Pet, Care, Care Team, or Fostering row/card widgets. |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-03T16:30:00Z` |
| **approved_until** | `2026-09-05T16:30:00Z` |
| **approved_by** | user chat 2026-09-03 (/execute-plan after ui-design-deep analysis) |
| **control_issue** | #928 |
| **content_hash** | frozen at approval |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous guardian-desk-framing-6e46`

## Sanity check

**proceed** — 5 phases, Guardian Flutter shell + dashboard framing only, no API/migrations. Integration branch; builds on existing ops desk layout.

## Runtime state

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/guardian-desk-framing-shell-6e46"
artifact_ref:
  branch: cursor/guardian-desk-framing-6e46-integration-6e46
  plan_path: .agents/plans/guardian-desk-framing-6e46.md
  plan_commit: 42c380180fef22843c178d55cf1cb817ef1ada61
  snapshot_path: .agents/plans/guardian-desk-framing-6e46.snapshot.json
  snapshot_commit: 42c380180fef22843c178d55cf1cb817ef1ada61
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Framing decisions and brief amendment

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/guardian-desk-framing-decisions-6e46` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
docs/domains/pet_profile/changes/desk-framing-decisions.md
docs/domains/pet_profile/features/guardian-dashboard-brief.md
docs/design/tokens.md
docs/debt/refactoring-log.md
.agents/plans/guardian-desk-framing-6e46.md
.agents/plans/guardian-desk-framing-6e46.snapshot.json
```

**forbidden_paths:**

```
flutter_app/**
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Add `desk-framing-decisions.md` with locked D-desk-* decisions.
- Amend guardian dashboard brief: header-row “All …” pattern; note shell surface rule.
- Align `tokens.md` dashboard section note with open-canvas direction.
- Log sprint in `refactoring-log.md`.

**Exit criteria:**

- [ ] Decisions doc merged; brief amended
- [ ] No Flutter code changes

---

### Phase 2 — Shell surfaces (nav vs workspace canvas)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/guardian-desk-framing-shell-6e46` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_sidebar.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_rail.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_shell_home_content.dart
flutter_app/test/features/experience/presentation/widgets/experience_shell_scaffold_test.dart
flutter_app/test/features/experience/presentation/widgets/guardian_navigation_rail_test.dart
.agents/plans/guardian-desk-framing-6e46.md
.agents/plans/guardian-desk-framing-6e46.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Sidebar/rail → `AppColorTokens.surface`; main content column → `background`.
- Ensure `_ContentChromeBar` sits on canvas, not nav surface.
- Widget tests assert surface colours at 720px / 1024px.

**Exit criteria:**

- [ ] Nav and canvas visually distinct at medium+ without borders
- [ ] Mobile compact shell unchanged
- [ ] Widget tests green

---

### Phase 3 — Section chrome (title + “All …” row)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/guardian-desk-framing-headers-6e46` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_dashboard_section_header.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_my_pets_section.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_my_vets_section.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_fostering_section.dart
flutter_app/test/features/experience/presentation/widgets/guardian_dashboard_section_header_test.dart
.agents/plans/guardian-desk-framing-6e46.md
.agents/plans/guardian-desk-framing-6e46.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Add `GuardianDashboardSectionChrome` (title row + optional trailing link).
- Migrate Care, Care Team, Fostering, Pets overflow link to header row.
- Gate links on real destinations only; harmonize `allCare` copy if touched.

**Exit criteria:**

- [ ] All dashboard sections use consistent header-row pattern
- [ ] “All …” only when destination exists
- [ ] Widget tests for header chrome

---

### Phase 4 — Section surfaces and nav active polish

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/guardian-desk-framing-surfaces-6e46` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_operations_desk_layout.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_my_vets_section.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_fostering_section.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_navigation_sidebar.dart
flutter_app/test/features/experience/presentation/widgets/guardian_shell_home_content_test.dart
.agents/plans/guardian-desk-framing-6e46.md
.agents/plans/guardian-desk-framing-6e46.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Remove tinted `GuardianDeskSectionCard` wrappers on Care/Care Team previews (open canvas).
- Lighten sidebar active state (reduce fill or bar — one channel).
- Keep fostering org tint if justified.

**Exit criteria:**

- [ ] No unnecessary section card nesting on home
- [ ] Sidebar active reads as nav, not content card
- [ ] Home content tests still green

---

### Phase 5 — Canvas width alignment and verification

| Field | Value |
|-------|-------|
| **id** | `5` |
| **branch** | `cursor/guardian-desk-framing-canvas-6e46` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/widgets/guardian_operations_desk_layout.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_shell_home_content.dart
flutter_app/test/features/experience/presentation/widgets/guardian_shell_home_content_test.dart
flutter_app/test/features/experience/presentation/widgets/experience_shell_scaffold_test.dart
docs/design/system.md
.agents/plans/guardian-desk-framing-6e46.md
.agents/plans/guardian-desk-framing-6e46.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Align max width to 1120px; responsive horizontal padding by breakpoint.
- Update tests and `system.md` if drifted from 1180.

**Exit criteria:**

- [ ] Home dashboard anchored at 1120px with comfortable outer whitespace
- [ ] Spec and code agree on max width
- [ ] `pre-push-changed.sh` green

---

## Final merge

After all phases merged into integration branch, open **one** PR integration → `main` with `./scripts/pre-push.sh` and **/babysit-uat**.

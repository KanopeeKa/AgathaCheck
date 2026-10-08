---
title: CIM Agatha teal + Away context plum
owner: Agent
audience: agent
status: proposed
last_updated: 2026-10-08
tags: [pet_care, design, ui, plan]
---

# cim-away-colour-e376

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `cim-away-colour-e376` |
| **title** | Agatha suggestion teal + Away planning plum coherence |
| **author** | (human / agent) |
| **created** | 2026-10-08 |
| **base_branch** | `cursor/cim-away-colour-e376-integration-e376` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Align Flutter with `docs/design/tokens.md` for **Care Intelligence** and **Away planning**:

1. **Agatha suggestions** use `agathaTeal` / `agathaMessageSurface` / `agathaMessageBorder` on **profile/dashboard `CareSuggestionCard` and inbox `NotificationSuggestionCard` (For you)** — retire coral on CIM suggestion surfaces.
2. **CIM safeguards** use semantic `info` / `infoLight` (distinct from suggestions and from plum).
3. **Away planning** uses documented **away-context** plum aliases on all `/pc/away` and absence modules (user-declared trip — never Agatha teal or info blue for chrome).

Two implementation phases merge to an **integration branch**; one final PR integration → `main` with `/babysit-uat`.

**Out of scope:** E2E visual assertions; global `ThemeData.tertiary` changes.

## Canonical docs

| Doc | Phase |
|-----|-------|
| `docs/design/tokens.md` | 1, 2 |
| `docs/domains/pet_care/features/care-intelligence.md` | 1 |
| `docs/domains/notifications/features/notifications-v2-spec.md` | 1 (For you card chrome) |
| `docs/domains/pet_care/features/care-context.md` | 2 |

Optional delivery note (delete when both phases merged): `docs/domains/pet_care/changes/cim-away-colour-rollout.md` (`status: proposed`).

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | `2026-10-08T10:21:49Z` |
| **approved_until** | `2026-10-10T10:21:49Z` |
| **control_issue** | [#1791](https://github.com/KanopeeKa/AgathaCheck/issues/1791) |
| **content_hash** | `sha256:ba8b990d2f5b4ea66e238008bc34439a71e70e6c8a78b6e2ca7241820e64b178` |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous cim-away-colour-e376`

## Preflight (human, before grant)

```bash
git fetch origin main
git checkout main
git pull origin main
git checkout -b cursor/cim-away-colour-e376-integration-e376
git push -u origin cursor/cim-away-colour-e376-integration-e376
```

```bash
node scripts/validate_execute_plan_snapshot.js .agents/plans/cim-away-colour-e376.snapshot.json
node scripts/execute_plan_runtime.js init-control-issue cim-away-colour-e376
# Create issue; set control_issue in snapshot; re-validate; freeze content_hash after approve-autonomous
```

**Sanity check expectation:** `proceed` (Flutter-only, no API/migrations; medium scope).

---

## Phase 1 — Agatha teal suggestions (profile, dashboard, For you) + info safeguards

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/agatha-teal-suggestion-cards-e376` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **docs_targets** | `docs/design/tokens.md`, `docs/domains/pet_care/features/care-intelligence.md`, `docs/domains/notifications/features/notifications-v2-spec.md` |

**router_risk:** R1 (design-scoped Flutter)  
**protocols:** `accessibility`, `flutter-mobile`, `documentation`

**allowed_paths:**

```
flutter_app/lib/features/care_intelligence/**
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_dashboard_contextual_slot_section.dart
flutter_app/lib/features/experience/presentation/pet_profile/widgets/pet_profile_care_suggestion_section.dart
flutter_app/lib/features/notifications/presentation/widgets/notification_suggestion_card.dart
flutter_app/lib/features/notifications/presentation/widgets/notification_inbox_list.dart
flutter_app/test/features/care_intelligence/**
flutter_app/test/features/notifications/**
docs/design/tokens.md
docs/domains/pet_care/features/care-intelligence.md
docs/domains/notifications/features/notifications-v2-spec.md
docs/domains/pet_care/changes/cim-away-colour-rollout.md
```

**forbidden_paths:**

```
server/**
.github/workflows/**
db/**
e2e/**
flutter_app/lib/features/pet_care/context/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Add shared shell (e.g. `agatha_message_card_shell.dart`): fill `agathaMessageSurface`, border `agathaMessageBorder`, title `agathaTeal`; body `body` token.
- Refactor `care_suggestion_card.dart` off `warmAccent` / `warmAccentLight`.
- Refactor `notification_suggestion_card.dart` to use the same Agatha message shell (For you tab parity with profile/dashboard).
- Refactor `care_safeguard_card.dart` to `infoLight` + `info` title (not `primaryContainer`).
- Keep accept / primary actions **plum** (`FilledButton` / theme primary).
- Do **not** change unrelated `warmAccent` (undo, paywall, super-admin, archived pets).

**Exit criteria:**

- [ ] `CareSuggestionCard` and `NotificationSuggestionCard` use Agatha tokens only for chrome; widget tests pass (add notification widget test if none).
- [ ] Safeguard card uses info tokens; visually distinct from suggestion.
- [ ] `/canonical-docs sync` on care-intelligence + tokens anti-pattern note (coral not for CIM cards).
- [ ] `./scripts/pre-push-changed.sh` green.
- [ ] PR merged to `cursor/cim-away-colour-e376-integration-e376` (`/babysit-plus`).

---

## Phase 2 — Away context plum on all Away surfaces

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/away-context-plum-tokens-e376` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **docs_targets** | `docs/design/tokens.md`, `docs/domains/pet_care/features/care-context.md` |

**router_risk:** R1  
**protocols:** `accessibility`, `flutter-mobile`, `documentation`

**allowed_paths:**

```
flutter_app/lib/core/theme/app_color_tokens.dart
flutter_app/lib/features/pet_care/context/**
flutter_app/lib/features/experience/presentation/care_item/detail/care_item_absence_section.dart
flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_absence_section.dart
flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_planned_absence_section.dart
flutter_app/lib/features/pet_care/presentation/widgets/**
flutter_app/test/features/pet_care/context/**
flutter_app/test/features/experience/**/care_item*absence*
docs/design/tokens.md
docs/domains/pet_care/features/care-context.md
docs/domains/pet_care/changes/cim-away-colour-rollout.md
```

**forbidden_paths:**

```
server/**
.github/workflows/**
db/**
flutter_app/lib/features/care_intelligence/**
```

**allowed_exceptions:** `tests`, `docs`, `file-split`

**Scope:**

- Add token aliases: `awayContextSurface` (= `petCareLight`), `awayContextAccent` (= `petCareActive` or `petCarePrimary` for icons) in `app_color_tokens.dart`; document in `tokens.md` § Away planning context.
- Shared `AwayContextIconChip` (canonical icon: `Icons.event_busy_outlined` on list/tile surfaces; `Icons.flight_takeoff_outlined` OK inside care-item modules if documented).
- Wire: `planned_absence_entry_tile.dart`, `planned_absence_hub_card.dart`, hub empty state, optional plan summary accent, `care_item_absence_section.dart`, `occurrence_absence_section.dart`.
- `away_plan_suggestions_section.dart` planner heading → **plum** (`awayContextAccent`) or neutral + distinct copy — **not** Agatha teal.

**Exit criteria:**

- [ ] Away surfaces share chip/accent; no Agatha teal on away paths.
- [ ] `flutter test test/features/pet_care/context/` passes.
- [ ] Canonical docs synced; fold/delete `cim-away-colour-rollout.md` if fully delivered.
- [ ] Phase PR merged to integration (`/babysit-plus`).

---

## Final integration → main

After phase 2 `merged`:

1. Open PR: `cursor/cim-away-colour-e376-integration-e376` → `main`.
2. `./scripts/pre-push.sh`
3. `/babysit-uat` (pre-UAT E2E on merge SHA).
4. `node scripts/execute_plan_runtime.js complete-plan cim-away-colour-e376 --write`

**Manual evidence (PR body):** screenshot — Agatha suggestion card (teal) on profile and For you inbox; safeguard (info); dashboard away tile + hub card (plum chip).

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 2
last_completed_phase: 1
halt_reason: null
next_action: "continue phase 2 on branch cursor/away-context-plum-tokens-e376"
artifact_ref:
  branch: cursor/away-context-plum-tokens-e376
  plan_path: .agents/plans/cim-away-colour-e376.md
  plan_commit: 256dac84c3b9dc0a0a52f9534c1475fb1c46668f
  snapshot_path: .agents/plans/cim-away-colour-e376.snapshot.json
  snapshot_commit: 256dac84c3b9dc0a0a52f9534c1475fb1c46668f
open_prs: []
merge_commits: {"1":"9442c24f600186e849815fa9cb2b05b80e2b7ecd"}
debt_issue_refs: []
```

## Decision log (fold into canonical docs on delivery)

| ID | Decision |
|----|----------|
| CIM-UI-D-001 | Suggestions (profile, dashboard, For you inbox) → Agatha message tokens; safeguards → info; coral not CIM card chrome. |
| CC-UI-D-001 | Away planning → away-context plum aliases; not Agatha teal or info fills. |

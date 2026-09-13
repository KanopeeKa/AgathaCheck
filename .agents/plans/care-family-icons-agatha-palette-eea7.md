---
title: Care family icons and Agatha message palette
owner: Agent
audience: agent
status: active
created: 2026-09-13
---

# Care family icons and Agatha message palette

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `care-family-icons-agatha-palette-eea7` |
| **title** | Care family icons + Agatha message palette |
| **base_branch** | `cursor/care-family-icons-agatha-palette-eea7-integration` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Unify care-family iconography (shape-first, unified ink — Option A), introduce semantic Agatha message tokens (deep teal on soft teal surface), update the “Suggested by Agatha” card, add family icons to due-event rows, and consolidate duplicate HealthEntryType icon helpers.

Design decisions (locked):

- Nail care icon: **scissors** (Material, no custom SVG)
- Icon colour: **Option A** — unified `body`/`muted` ink on neutral chip (`surfaceAlt`)
- Agatha suggestions: **`agathaMessage*`** tokens; retire `warmAccent*` on CIM cards
- Agatha teal: **`#15586E`** (semantic `agathaTeal`)

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-13T15:57:00Z |
| **approved_by** | user-chat-grant-execute-plan-2026-09-13 |
| **approved_until** | 2026-09-15T15:57:00Z |
| **control_issue** | #1131 |
| **autonomy** | `active` |

**Grant:** user invoked `/execute-plan` after design review.

---

## Phase 1 — Agatha message tokens and suggestion card

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/agatha-message-palette-eea7` |

**allowed_paths:**

```
flutter_app/lib/core/theme/**
docs/design/tokens.md
flutter_app/lib/features/care_intelligence/presentation/widgets/care_suggestion_card.dart
flutter_app/test/features/care_intelligence/**
```

**Scope:**

- Add `agathaTeal`, `agathaMessageSurface`, `agathaMessageBorder` to `app_color_tokens.dart`
- Document tokens in `docs/design/tokens.md`
- Restyle `CareSuggestionCard` with teal surface/border/title; body on `body`; keep Accept as plum FilledButton

**Exit criteria:**

- [ ] Agatha title contrast ≥ 4.5:1 on message surface
- [ ] No `warmAccent*` on suggestion card
- [ ] Widget tests updated

---

## Phase 2 — Care family icon set (unified ink)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/care-family-icons-eea7` |

**allowed_paths:**

```
flutter_app/lib/features/pet_profile/presentation/widgets/care_family_icon.dart
flutter_app/lib/features/pet_profile/presentation/widgets/care_rhythms/**
flutter_app/test/features/pet_profile/presentation/widgets/care_family_icon_test.dart
```

**Scope:**

- Refactor `CareFamilyIcon`: neutral `surfaceAlt` chip, unified ink colour
- Icon mapping: pill, syringe, shield, stethoscope, tooth, scale, brush, **scissors** (nail), smiley outline
- Add widget tests for all nine families

**Exit criteria:**

- [ ] Nine distinct Material icon shapes at 20px
- [ ] No plum on category chips
- [ ] Tests cover all CareFamily values

---

## Phase 3 — Due rows and icon consolidation

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/care-event-row-icons-eea7` |

**allowed_paths:**

```
flutter_app/lib/features/health_tracking/presentation/widgets/care_event_row*.dart
flutter_app/lib/features/health_tracking/presentation/widgets/health_entry_card.dart
flutter_app/lib/features/pet_profile/presentation/screens/widgets/pet_event_entry_list.dart
flutter_app/test/features/health_tracking/presentation/widgets/care_event_row_test.dart
flutter_app/test/features/experience/presentation/screens/pet_care/**
```

**Scope:**

- Add `CareFamilyIcon` leading slot on `CareEventRow` (alongside pet avatar on dashboard)
- Route `health_entry_card` and `PetEventEntryList` through shared `CareFamilyIcon` / central icon helper
- Remove duplicate `_typeIcon` / `iconForType` switches

**Exit criteria:**

- [ ] Due/overdue rows show family icon
- [ ] Single icon source for list surfaces
- [ ] Existing care_event_row tests pass; update if layout keys change

---

## Final integration PR

After all phases merge to integration branch, one PR integration → `main` with `/babysit-uat`.

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/agatha-message-palette-eea7"
artifact_ref:
  branch: cursor/agatha-message-palette-eea7
  plan_path: .agents/plans/care-family-icons-agatha-palette-eea7.md
  plan_commit: 5aa7ce4e9693987bd850cb6da1de1c2e115202ed
  snapshot_path: .agents/plans/care-family-icons-agatha-palette-eea7.snapshot.json
  snapshot_commit: 5aa7ce4e9693987bd850cb6da1de1c2e115202ed
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1132"]
merge_commits: {}
debt_issue_refs: []
```

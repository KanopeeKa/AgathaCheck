# Guardian CARE ACTIONS block surface — execute plan

> **plan_id:** `guardian-care-block-surface-5d6a`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-care-block-surface-5d6a` |
| **title** | CARE ACTIONS plum-tinted block surface on guardian home |
| **author** | agent (ui-design-deep Option A, user 2026-09-03) |
| **created** | 2026-09-03 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Wrap the guardian home CARE ACTIONS preview content in `GuardianDeskSectionCard` tinted with `petCareLight`, matching the pet-detail care preview and giving the block a clear visual boundary on the open canvas dashboard.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-03T19:15:00Z` |
| **approved_until** | `2026-09-05T19:15:00Z` |
| **approved_by** | user chat 2026-09-03 ("Go with option A /execute-plan") |
| **control_issue** | #940 |
| **content_hash** | frozen at approval |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous guardian-care-block-surface-5d6a`

## Sanity check

`proceed` — single-phase, scoped Flutter + docs; reverses D-desk-5 open-canvas default for Care only (documented exception).

---

### Phase 1 — Care block surface + docs

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/guardian-care-block-surface-5d6a` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `flutter-screen-split` |

**allowed_paths:**

```
flutter_app/lib/features/experience/presentation/screens/guardian/guardian_upcoming_events_section.dart
flutter_app/lib/features/experience/presentation/widgets/guardian_care_preview/guardian_care_preview_optimistic.dart
flutter_app/test/features/experience/presentation/screens/guardian/guardian_upcoming_events_section_test.dart
docs/design/tokens.md
docs/domains/pet_profile/changes/desk-framing-decisions.md
.agents/plans/guardian-care-block-surface-5d6a.md
.agents/plans/guardian-care-block-surface-5d6a.snapshot.json
```

**forbidden_paths:**

```
server/**
.github/workflows/**
e2e/**
```

**Scope:**

- Wrap CARE ACTIONS list/empty/loading/error content in `GuardianDeskSectionCard(tint: petCareLight)`.
- Suppress top divider on first care row inside the card.
- Amend D-desk-5 and `tokens.md` to document Care as a plum-tint exception (alongside Fostering org tint).

**Exit criteria:**

- [ ] Home CARE ACTIONS block uses `petCareLight` surface
- [ ] Pet-detail care preview unchanged (already uses same token)
- [ ] Widget tests assert section card wrapper
- [ ] `pre-push-changed.sh` green

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/guardian-care-block-surface-5d6a"
artifact_ref:
  branch: cursor/guardian-care-block-surface-5d6a
  plan_path: .agents/plans/guardian-care-block-surface-5d6a.md
  plan_commit: 5d7012520ef775939fa3c2f801bbbc39473d3919
  snapshot_path: .agents/plans/guardian-care-block-surface-5d6a.snapshot.json
  snapshot_commit: 5d7012520ef775939fa3c2f801bbbc39473d3919
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/941"]
merge_commits: {}
debt_issue_refs: []
```

## Runtime state (agent-updated)

| Phase | Status | PR |
|-------|--------|-----|
| 1 | in_progress | — |

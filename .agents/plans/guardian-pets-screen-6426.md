---
title: Guardian Pets screen rework
owner: Agent
audience: agent
status: active
last_updated: 2026-09-02
tags: [design, guardian, pets]
---

# Guardian Pets screen rework (`guardian-pets-screen-6426`)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `guardian-pets-screen-6426` |
| **title** | Guardian Pets screen — list clarity, tiles, bulk share |
| **author** | Cloud agent (user design review 2026-09-02) |
| **created** | 2026-09-02 |
| **base_branch** | `cursor/guardian-pets-screen-integration-6426` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Rework the guardian `/pc/pets` screen per ui-design-deep review and user decisions (A–F): remove ownership filter chips while keeping section splits; add Shared pets subsection; fix foster grouping via dashboard helpers + API audit; harmonise tiles with dashboard cards; remove swipe-to-hide; replace top `+` and FAB with a 2:1 bottom action bar; add dedicated multi-select screen for bulk share.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-02T10:36:00Z |
| **approved_until** | 2026-09-04T10:36:00Z |
| **control_issue** | TBD |
| **autonomy** | `active` |

**Grant:** user chat 2026-09-02 — `/execute-plan` with confirmed A–F decisions.

## Design decisions (locked)

| ID | Decision |
|----|----------|
| A | Remove All/My/Fostered chips on `/pc/pets`; defer org-name chips on legacy list |
| B | Add **Shared pets** subsection matching dashboard |
| C | Group with dashboard helpers; audit `is_foster` API mapping |
| D | Bottom action bar on all breakpoints; align to content column on desktop |
| E | **Remove swipe-to-hide** for shared/fostered pets entirely |
| F | Two implementation phases → integration branch; one PR to `main` |

## Phases

### Phase 1 — List clarity and tile harmonisation

**branch:** `cursor/guardian-pets-list-clarity-6426`

**Scope:**

- Remove ownership filter chips on guardian embedded pets list
- Section splits: My pets (owned), Shared pets, Fostered pets, Passed away
- Dashboard-aligned `GuardianDashboardPetCard` grid (wider 2-col default)
- Remove Dismissible hide wrappers (pets list + dashboard shared cards)
- Verify foster `is_foster` wire from `/pets/all`

**Exit criteria:**

- [ ] No All/My/Fostered chips on `/pc/pets`
- [ ] Foster pets only under Fostered section
- [ ] Shared pets in own section
- [ ] Tiles match dashboard look; no swipe-to-hide
- [ ] Tests green via `pre-push-changed.sh`

### Phase 2 — Bottom bar and bulk share selection screen

**branch:** `cursor/guardian-pets-bulk-nav-6426`

**Scope:**

- Remove app-bar `+` on `/pc/pets`
- Sticky bottom bar: Add pet (⅔) + `…` menu (⅓) with Share pets…
- New `/pc/pets/bulk-share` selection screen (tap to select, select all toggle, Share *n* pets CTA)
- Remove inline `PetListBulkShareBar` from browse screen

**Exit criteria:**

- [ ] Single add CTA in bottom bar only
- [ ] Bulk share via dedicated screen
- [ ] l10n + a11y semantics for selection mode
- [ ] Router/tests updated

## Runtime state

| Phase | Status | PR |
|-------|--------|-----|
| 1 | in_progress | |
| 2 | pending | |

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "implement phase 1 on cursor/guardian-pets-list-clarity-6426"
artifact_ref:
  branch: cursor/guardian-pets-list-clarity-6426
  plan_path: .agents/plans/guardian-pets-screen-6426.md
  plan_commit: null
  snapshot_path: .agents/plans/guardian-pets-screen-6426.snapshot.json
  snapshot_commit: null
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

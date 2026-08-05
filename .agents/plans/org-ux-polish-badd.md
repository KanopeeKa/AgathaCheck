# Plan — org-ux-polish-badd

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `org-ux-polish-badd` |
| **title** | Org UX polish — upload fix, list IA, camera branding, grids, EN-GB |
| **author** | cloud agent |
| **created** | 2026-08-05 |
| **base_branch** | `cursor/org-ux-polish-integration-badd` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Fix org cover/logo display on UAT (static asset URL routing), refresh providers after upload, then deliver horizontal My Organisations rows, pet-style camera upload UX on edit branding, wrap-grid org pets, discover pet-tile grid, and British English locale sweep.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-08-05T10:46:00Z |
| **approved_until** | 2026-08-07T10:46:00Z |
| **control_issue** | #598 |
| **autonomy** | `active` |

**Grant:** user chat 2026-08-05 — `/execute-plan`, all phases, green pre-UAT E2E.

## Phases

### Phase 1 — Upload URL fix + refresh

**branch:** `cursor/org-ux-a0-upload-fix-badd`

- Resolve `/uploads/` → `/backend/uploads/` on web
- Invalidate `organisationProfileProvider` on photo/logo upload
- Image error placeholders in `org_image_avatar.dart`
- Unit tests + E2E regression guard

### Phase 2 — List IA + camera branding

**branch:** `cursor/org-ux-b-list-branding-badd`

- Horizontal `OrgCard` rows with chevron
- Reorder list: cards → divider → discover → invite copy; remove footer Create
- Camera FAB overlays on cover/logo (pet photo pattern)
- Dark teal default cover placeholder

### Phase 3 — Org pets wrap grid

**branch:** `cursor/org-ux-d-pets-grid-badd`

- `PetTileStrip(useWrap: true)` on org pets screen

### Phase 4 — Discover grid tiles

**branch:** `cursor/org-ux-e-discover-tiles-badd`

- Pet-tile sizing grid; logo on cover; name + 2 lines

### Phase 5 — British English + integration → main

**branch:** `cursor/org-ux-f-en-gb-badd`

- `app_en.arb` UK spelling sweep; test updates
- Final PR: integration → `main`

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/org-ux-a0-upload-fix-badd"
artifact_ref:
  branch: cursor/org-ux-a0-upload-fix-badd
  plan_path: .agents/plans/org-ux-polish-badd.md
  plan_commit: bf16e4c23274fd760c537d1b56167458abfd856d
  snapshot_path: .agents/plans/org-ux-polish-badd.snapshot.json
  snapshot_commit: bf16e4c23274fd760c537d1b56167458abfd856d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

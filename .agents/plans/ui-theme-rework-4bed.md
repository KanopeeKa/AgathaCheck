# Plan — UI theme rework

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `ui-theme-rework-4bed` |
| **title** | UI theme rework (plum guardian / teal org) |
| **author** | cloud-agent |
| **created** | 2026-07-23 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Replace purple-seed Material theme with locked AgathaTrack tokens: plum guardian primary, teal organisation primary, warm coral accent, S2 success green. `ThemeData` + `ThemeExtension` foundation first, then phased screen alignment per `docs/design/ui-rework-plan.md`.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-07-23T10:15:00Z |
| **approved_until** | 2026-07-25T10:15:00Z |
| **control_issue** | (see snapshot) |
| **autonomy** | `active` |

**Grant keyword:** `approve-autonomous ui-theme-rework-4bed`

## Locked design decisions

- Guardian full primary: plum `#755B68` on `/g/*`
- Organisation full primary: teal `#218B6C` on `/o/*`
- Landing pre-login: plum; first teal in org/shelter educational CTA (Phase 2)
- Foster: guardian side; org-guardianship pet photo border teal (Phase 3)
- Success: `#2B7A2E` (S2)
- Implementation: base `ThemeData` + `ThemeExtension` (`ExperienceColors`)

## Runtime state

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 7
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/ui-theme-phase7-closeout-4bed
  plan_path: .agents/plans/ui-theme-rework-4bed.md
  plan_commit: a40491aeb3be8cd51df94497c1c5f74646a85e6c
  snapshot_path: .agents/plans/ui-theme-rework-4bed.snapshot.json
  snapshot_commit: a40491aeb3be8cd51df94497c1c5f74646a85e6c
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

See `docs/design/ui-rework-plan.md` for screen lists. Snapshot drives allowed_paths.

---

## Sanity check

**Result:** `proceed-high-risk` — 8 phases, 48h window; phase 0 isolated and mergeable first.

# Execute-plan: docs domain sweep (wave 2)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-domain-sweep-63ad` |
| **title** | Move remaining domain-scoped docs and execution plans |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |

## Goal

Complete the domain-first migration: `git mv` experience-program delivery plans, guardian-today docs, sprint execution plans, and org-fostering-strategy into correct `docs/domains/` or `docs/plans/` locations; update indexes and links.

**Grant:** User chat 2026-08-22 — "Yes, go ahead" on full .md sweep.

## Phases

### Phase 1 — pet_profile delivery docs

Branch: `cursor/docs-domain-sweep-pet-63ad`

Move phase-2, guardian-today-*, guardian-ui-wave2 briefs to `docs/domains/pet_profile/changes/`.

### Phase 2 — organization delivery docs

Branch: `cursor/docs-domain-sweep-org-63ad`

Move organisation delivery plans and phase-3/5 org docs to `docs/domains/organization/changes/`.

### Phase 3 — fostering + cross-cutting plans + link sweep

Branch: `cursor/docs-domain-sweep-rest-63ad`

Move phase-4 foster ops, org-fostering-strategy; relocate sprint execution plans to `docs/plans/`; update experience-program README; grep-fix links; validate.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/docs-domain-sweep-pet-63ad"
artifact_ref:
  branch: cursor/docs-domain-sweep-pet-63ad
  plan_path: .agents/plans/docs-domain-sweep-63ad.md
  plan_commit: 5189b3fc2a54dce6aff08f80224ac5b046c6888d
  snapshot_path: .agents/plans/docs-domain-sweep-63ad.snapshot.json
  snapshot_commit: 5189b3fc2a54dce6aff08f80224ac5b046c6888d
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

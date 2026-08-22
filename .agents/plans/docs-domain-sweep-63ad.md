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
autonomy: completed
current_phase: null
last_completed_phase: 3
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/docs-domain-sweep-63ad.md
  plan_commit: ad509f1d124dda1f663e424bdaa400b79a1d70ba
  snapshot_path: .agents/plans/docs-domain-sweep-63ad.snapshot.json
  snapshot_commit: ad509f1d124dda1f663e424bdaa400b79a1d70ba
open_prs: []
merge_commits: {"1":"6ec7fb22c7b37ab8790a7c6d09bd4b318d39c989","2":"6ec7fb22c7b37ab8790a7c6d09bd4b318d39c989","3":"6ec7fb22c7b37ab8790a7c6d09bd4b318d39c989"}
debt_issue_refs: []
```

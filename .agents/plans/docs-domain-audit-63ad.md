# Execute-plan: docs domain audit (wave 3)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-domain-audit-63ad` |
| **title** | Full .md audit and debt migration completion |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |

## Goal

Analyse every repository `.md` file for domain-first placement. Wave 1–2 moved delivery plans; wave 3 records the full inventory, migrates debt rows into domain `changes/deferred.md`, and cleans stale index entries.

**Grant:** User chat 2026-08-22 — full code `.md` audit with execute-plan + babysit+.

## Phases

### Phase 1 — Full audit artifact

Branch: `cursor/docs-domain-audit-report-63ad`

Publish `docs/plans/docs-domain-audit-63ad.md` with categorization of all 300 tracked `.md` files.

### Phase 2 — Debt row migration

Branch: `cursor/docs-domain-audit-debt-63ad`

Migrate domain-scoped rows from `technical-debt.md` / `refactoring-debt.md` into `docs/domains/*/changes/deferred.md`; trim legacy indexes to pointers; fix organisation brief cross-links.

### Phase 3 — Index cleanup and validate

Branch: `cursor/docs-domain-audit-index-63ad`

Update `docs/README.md` legacy tables; run `validate_docs.sh`; grep-fix stale paths.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/docs-domain-audit-report-63ad"
artifact_ref:
  branch: cursor/docs-domain-audit-report-63ad
  plan_path: .agents/plans/docs-domain-audit-63ad.md
  plan_commit: 7d60926234a9753f9d4d8beee5ae627a7b745726
  snapshot_path: .agents/plans/docs-domain-audit-63ad.snapshot.json
  snapshot_commit: 7d60926234a9753f9d4d8beee5ae627a7b745726
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

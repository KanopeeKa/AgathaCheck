# Execute-plan: docs domain stubs and metadata (wave 4)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-domain-stubs-63ad` |
| **title** | Complete domain stub docs and YAML frontmatter |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |

## Goal

Finish domain-first migration leftovers: populate `specs`/`journeys`/`plans`/`lessons`/`deferred` stubs and add YAML metadata to docs flagged by `validate_docs.sh`.

**Grant:** User chat 2026-08-22 — continue docs roadmap after wave 3 audit.

## Phases

### Phase 1 — Domain stub completion

Branch: `cursor/docs-domain-stubs-content-63ad`

Fill remaining TODO stubs in `docs/domains/` (notifications, subscription, help_about, plans indexes, lessons, deferred).

### Phase 2 — YAML frontmatter wave

Branch: `cursor/docs-domain-metadata-63ad`

Add metadata headers to 46 docs flagged by `validate_docs.sh`; re-run validation.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/docs-domain-stubs-content-63ad"
artifact_ref:
  branch: cursor/docs-domain-stubs-content-63ad
  plan_path: .agents/plans/docs-domain-stubs-63ad.md
  plan_commit: ff922e297aced5218e22a03274d1b121469c0781
  snapshot_path: .agents/plans/docs-domain-stubs-63ad.snapshot.json
  snapshot_commit: ff922e297aced5218e22a03274d1b121469c0781
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

# Execute-plan: docs canonical layout (wave 5)

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-canonical-layout-63ad` |
| **title** | Canonical docs layout — features, design, debt, dissolve programs |
| **base_branch** | `cursor/docs-canonical-layout-integration-63ad` |
| **default_merge_mode** | `auto` |

## Goal

Establish canonical documentation layout: feature requirements per domain, consolidated design system (Replit Operations Desk PR as source of truth), single open-debt register, dissolve `experience-program`, rename `organization` → `shelter` in docs, platform contracts under `architecture/` and `db/`, navigation domain, documentation standards with CI enforcement.

**Grant:** User chat 2026-08-23 — approved analysis suggestions; Replit redesign PRs are canonical for design references.

## Phases

### Phase 1 — Scaffold + design system home

Branch: `cursor/docs-canonical-scaffold-63ad`

Create `docs/db/`, `docs/domains/{cross-domain,navigation,documentation}/`, move `DESIGN_SYSTEM.md` → `docs/design/system.md`, add `documentation/standards.md` + feature template. Root `DESIGN_SYSTEM.md` becomes pointer only.

### Phase 2 — Platform contracts

Branch: `cursor/docs-canonical-platform-63ad`

Move `api-reference.md` and `calendar-dates.md` to `docs/architecture/`; create `docs/db/` index; link sweep.

### Phase 3 — Design dedupe

Branch: `cursor/docs-canonical-design-63ad`

Strip duplicate colours from `principles.md`; `tokens.md` + `system.md` canonical (aligned to Replit PR); `design/plans/` for working docs; update `index.md`.

### Phase 4 — Open debt register

Branch: `cursor/docs-canonical-debt-63ad`

Consolidate OPEN debt into `docs/debt/debt.md`; retire scattered deferred indexes; keep `refactoring-log.md` as changelog only.

### Phase 5 — Shelter rename (docs)

Branch: `cursor/docs-canonical-shelter-63ad`

`docs/domains/organization/` → `shelter/`; rename briefs; dedupe `architecture/org-*.md` into domain features; link sweep.

### Phase 6 — Dissolve experience-program

Branch: `cursor/docs-canonical-dissolve-xp-63ad`

Extract `decisions-log` into domain `features/` + `navigation/`; move briefs/plans to correct domains; delete `experience-program/`.

### Phase 7 — Lessons and plans hygiene

Branch: `cursor/docs-canonical-features-63ad`

Extract durable rules from `lessons.md` into `features/`; move delivery plans to `changes/`; `j1-foster-onboarding` → `changes/`; `docs/plans/` → `cross-domain/changes/`.

### Phase 8 — Stub and legacy cleanup

Branch: `cursor/docs-canonical-cleanup-63ad`

Delete redirect stubs, `fostering-platform/`, fix remaining old-path refs.

### Phase 9 — Documentation enforcement

Branch: `cursor/docs-canonical-enforce-63ad`

Extend `validate_docs.sh` / CI: doc placement, no hex outside tokens, feature manifest.

## Runtime state

```yaml
autonomy: active
current_phase: 9
last_completed_phase: 8
halt_reason: null
next_action: "continue phase 9 on branch cursor/docs-canonical-enforce-63ad"
artifact_ref:
  branch: cursor/docs-canonical-enforce-63ad
  plan_path: .agents/plans/docs-canonical-layout-63ad.md
  plan_commit: f4c119e51982fc84eb83532acd660379a00fb840
  snapshot_path: .agents/plans/docs-canonical-layout-63ad.snapshot.json
  snapshot_commit: f4c119e51982fc84eb83532acd660379a00fb840
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/732"]
merge_commits: {}
debt_issue_refs: []
```

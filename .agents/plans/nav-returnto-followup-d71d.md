# Navigation returnTo follow-up — execute plan

> **plan_id:** `nav-returnto-followup-d71d`

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `nav-returnto-followup-d71d` |
| **title** | Navigation returnTo debt — docs, helpers, away audit, E2E, ratchet |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Close remaining returnTo / shell-back debt after PRs #1298 and #1311: align docs, consolidate vet navigation helpers, away push-only entry audit, Playwright coverage for bell-panel drill-in back, and a CI ratchet against hardcoded returnTo paths.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | `2026-09-24T12:00:00Z` |
| **approved_until** | `2026-09-26T12:00:00Z` |
| **control_issue** | (see snapshot) |
| **autonomy** | `active` |

**Grant:** user chat 2026-09-24 — implement recommended follow-up via `/execute-plan` full autonomy.

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/nav-returnto-docs-d71d"
artifact_ref:
  branch: cursor/nav-returnto-docs-d71d
  plan_path: .agents/plans/nav-returnto-followup-d71d.md
  plan_commit: 343dfaf3e24e9c41a93a58a1effb280b60bce15b
  snapshot_path: .agents/plans/nav-returnto-followup-d71d.snapshot.json
  snapshot_commit: 343dfaf3e24e9c41a93a58a1effb280b60bce15b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Phases

### Phase 1 — Docs: fallback order

Align `docs/design/system.md` §6.6 with `shellFallbackReturnPath` (`returnTo` before explicit `backPath`).

### Phase 2 — Vet helper + absence tile

`openVetDetail` / `vetDetailLocation`; dashboard absence tile uses `currentShellLocation`.

### Phase 3 — Away push-only audit

Audit/fix away entry points; forward `returnTo` on edit screen `goNamed` fallback when `!canPop`.

### Phase 4 — Notification panel E2E

BDD + Playwright: bell panel on `/pc/home` → care notification → back → home.

### Phase 5 — returnTo ratchet

Script + pre-push hook: fail on new hardcoded `encodeShellReturnTo('/…')` in `flutter_app/lib`.

## Sanity check

**proceed** — five atomic outcomes, Flutter/docs/e2e/scripts only, no schema/API breaks.

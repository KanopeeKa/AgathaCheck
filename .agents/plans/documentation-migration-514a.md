# Documentation migration — unified execute-plan (`documentation-migration-514a`)

**One plan, one `/execute-plan`:** canonical-docs consolidation for all MVP domains per the handover. No roadmap parent, no per-wave child `plan_id`s.

| Field | Value |
|-------|-------|
| **plan_id** | `documentation-migration-514a` |
| **programme** | [documentation-migration-handover.md](../docs/domains/documentation/changes/documentation-migration-handover.md) |
| **integration `base_branch`** | `cursor/documentation-migration-wave13-integration-514a` |
| **control issue** | [#1787](https://github.com/KanopeeKa/AgathaCheck/issues/1787) |
| **default_merge_mode** | `auto` (squash each phase PR into integration; phase 26 → `main` via `/babysit-uat`) |

## Goal

Each active capability has **one** canonical `docs/domains/<domain>/features/<capability>.md` (requirements, acceptance criteria, decision log). Legacy `changes/` trails and duplicate feature files are folded or trimmed to `in-delivery`; `scripts/docs-legacy-baseline.json` shrinks as capabilities complete.

## Supersedes (do not use for new work)

| Retired pattern | Replacement |
|-----------------|-------------|
| `plan_kind: roadmap` + `documentation-migration-roadmap-514a` | This plan |
| Child plans (`documentation-migration-*-514a` except this file) | Phases **1–26** in `.snapshot.json` |
| Bootstrapping a new child after each merge | `/execute-plan` advances to next `pending` phase |

Historical child PRs remain valid audit trail; runtime state lives only in this snapshot.

## Resume line (2026-10-08)

| Item | State |
|------|--------|
| On `main` | Wave **1.1–1.2**, gate warn/harden, first integration merge ([#1780](https://github.com/KanopeeKa/AgathaCheck/pull/1780)) |
| On integration only | Wave **1.3a** ([#1782](https://github.com/KanopeeKa/AgathaCheck/pull/1782)), **1.3b** ([#1784](https://github.com/KanopeeKa/AgathaCheck/pull/1784)) |
| **Next phase** | **8** — `care-progression` (1.4a) |

Before first run, ensure the integration branch exists locally:

```bash
git fetch origin cursor/documentation-migration-wave13-integration-514a
git checkout cursor/documentation-migration-wave13-integration-514a
```

## Operator bootstrap (once)

1. Review this plan + snapshot; sanity: `proceed-high-risk` (long-running, 19 phases remaining).
2. On [#1787](https://github.com/KanopeeKa/AgathaCheck/issues/1787), add labels `execute-plan`, `plan:documentation-migration-514a` (if used), and comment:
   ```
   approve-autonomous documentation-migration-514a
   ```
3. Add label `autonomous-approved` on the control issue.
4. On the integration branch, set snapshot `autonomy: active`, set `approved_at` / `approved_until` (UTC, **48h** window), set `approved_by` to the approving comment; run `node scripts/validate_execute_plan_snapshot.js .agents/plans/documentation-migration-514a.snapshot.json --fix-hash` and commit.
5. Run `/execute-plan documentation-migration-514a`.

Re-approve before `approved_until` expires, or `resume-plan documentation-migration-514a` after `session_limit` halt.

## Orchestration rules

- **Phase loop:** implement → `./scripts/pre-push-changed.sh` → PR to `base_branch` → `/babysit-plus` → merge → next `pending` phase.
- **Phase 26 only:** PR `cursor/documentation-migration-wave13-integration-514a` → `main` → `/babysit-uat` (pre-UAT E2E on merge SHA).
- **Per phase:** `/canonical-docs sync` (Mode A); AC inventory before any `changes/` delete (handover §3).
- **Wave 6** (`shelter`, `fostering`): **out of scope** unless PO approves — halt with `governance_approval_required` rather than adding phases.
- **PO forks:** vet vs People (phase 22), `care-item.md` rename (handover §8.5) — escalate on control issue if the diff requires a decision.

## Phase map (snapshot is source of truth)

| Phase | Status | Capability / work |
|-------|--------|-------------------|
| 1–4 | merged | Gate warn, CSM 1.1, care-item 1.2, gate block harden |
| 5 | merged | First integration → `main` (1.1–1.2) |
| 6–7 | merged | care-context 1.3a, carer model 1.3b |
| 8 | **next** | care-progression 1.4a |
| 9 | pending | care-intelligence 1.4b |
| 10 | pending | pet_care README 1.5 |
| 11–13 | pending | people, notifications, weight |
| 14–17 | pending | pet profile, guardian today, navigation, health_tracking |
| 18–22 | pending | auth, sharing, subscription, help_about, vet |
| 23–25 | pending | cross-domain, indexes, memory → terminology |
| 26 | pending | integration → `main` |

Regenerate snapshot after editing phases: `node scripts/generate_documentation_migration_plan_snapshot.js` (then `--fix-hash` if needed).

## Shared phase constraints

- **allowed_paths:** domain docs + `scripts/docs-legacy-baseline.json` + `scripts/docs-memory-backlog.json` + plan artifacts + reference sweep targets (`e2e/`, `AGENTS.md`, `.cursor/`, `docs/architecture/` as listed per phase in snapshot).
- **forbidden_paths:** `server/**`, `flutter_app/**`, `.github/workflows/**` (docs-only migration).
- **allowed_exceptions:** `docs`, `governance-allowlist`, `tests` (reference / link fixes only).

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 11
last_completed_phase: 10
halt_reason: null
next_action: "continue phase 11 on branch cursor/documentation-migration-people-514a"
artifact_ref:
  branch: cursor/documentation-migration-wave13-integration-514a
  plan_path: .agents/plans/documentation-migration-514a.md
  plan_commit: b31e6587bbc4deff5e502cd7fabd21cccbf7199b
  snapshot_path: .agents/plans/documentation-migration-514a.snapshot.json
  snapshot_commit: b31e6587bbc4deff5e502cd7fabd21cccbf7199b
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

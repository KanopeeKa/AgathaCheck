---
title: Canonical docs skill plan
owner: Agent
audience: agent
status: active
last_updated: 2026-10-06
tags: [execute-plan, documentation]
---

# Plan: canonical-docs-skill-2316

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `canonical-docs-skill-2316` |
| **title** | Canonical-docs skill + docs gate on all agent PR paths |
| **author** | cloud-agent |
| **created** | 2026-10-06 |
| **base_branch** | `main` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Add `/canonical-docs` (sync + consolidate) and wire documentation sync into every agent PR path (pr-hygiene, babysit, babysit-plus, babysit-uat, execute-plan). One atomic PR to `main`; no domain doc migration and no new CI gates in this plan.

## Canonical docs

| Path | Role |
|------|------|
| `docs/domains/documentation/standards.md` | Policy (updated in phase 1 under policy-doc exception) |
| `.cursor/skills/canonical-docs/SKILL.md` | Procedure (Mode A / Mode B) |

No `changes/` docs for this plan.

## Autonomy (filled at approval)

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-06T17:35:00Z |
| **approved_until** | 2026-10-08T17:35:00Z |
| **control_issue** | (set in snapshot) |
| **autonomy** | `active` |

**Grant:** user chat — create plan and `/execute-plan`

## Phases

### Phase 1 — Skill, policy, and workflow wiring

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/canonical-docs-skill-2316` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**docs_targets (strengthen):**

- `docs/domains/documentation/standards.md` — `updated`
- `docs/domains/documentation/feature-template.md` — `updated`
- `.cursor/skills/canonical-docs/SKILL.md` — `updated` (new)

**allowed_paths:**

```
.cursor/skills/canonical-docs/**
.cursor/skills/babysit-plus/SKILL.md
.cursor/skills/babysit-uat/SKILL.md
.cursor/skills/execute-plan/SKILL.md
.cursor/rules/documentation.mdc
.cursor/rules/pr-hygiene.mdc
.cursor/commands/babysit.md
.cursor/agent-kernel/protocols/documentation.md
.cursor/agent-kernel/ROUTER.md
.cursor/agent-kernel/workers/phase-implementer.md
docs/domains/documentation/**
docs/agent-efficiency/**
docs/engineering/cursor-agent-framework.md
.github/pull_request_template.md
AGENTS.md
CLAUDE.md
.agents/plans/canonical-docs-skill-2316.*
```

**forbidden_paths:**

```
server/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:** `docs`, `tests`, `governance-allowlist`

**Scope:**

- Implement revised prompt: skill, standards, template, ROUTER, protocol, all workflow wiring, PR template, entry points.
- Dogfood: update `standards.md` with decision log + `related_prs`; PR body `## Docs`.
- Open PR; run `/babysit-plus` through merge.

**Exit criteria:**

- [ ] All acceptance criteria in plan snapshot comment / PR checklist pass
- [ ] `node scripts/check_skill_frontmatter.js` passes
- [ ] `bash scripts/validate_docs.sh` passes
- [ ] `./scripts/pre-push-changed.sh` passes
- [ ] PR merged to `main`

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/canonical-docs-skill-2316"
artifact_ref:
  branch: cursor/canonical-docs-skill-2316
  plan_path: .agents/plans/canonical-docs-skill-2316.md
  plan_commit: 9f517b9b32982e3ffcef612f41d8de40be02e741
  snapshot_path: .agents/plans/canonical-docs-skill-2316.snapshot.json
  snapshot_commit: 9f517b9b32982e3ffcef612f41d8de40be02e741
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1703"]
merge_commits: {}
debt_issue_refs: []
```

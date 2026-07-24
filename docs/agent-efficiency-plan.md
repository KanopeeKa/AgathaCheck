# Agent efficiency — implementation plan

Living plan to reduce token burn, speed up agent iterations, and encode recurring
workflows. Pauses functional product sprints while infra lands on `main`.

**Status:** In progress (Sprint 8–11)  
**Owner:** Cloud agents / governance  
**Companion:** `docs/refactoring-log.md` (Sprint 8–11 entries)

---

## Goals

| Goal | How we measure success |
|------|------------------------|
| Less duplicated context per turn | Slim always-on rules; path-scoped rules + Skills |
| Faster agent iterations | `scripts/pre-push-changed.sh` default during work |
| Repeatable sprint mechanics | Six Skills under `.cursor/skills/` |
| Self-service PR hygiene | `/babysit` command + PR governance workflow |
| Autonomous multi-phase plans | `/execute-plan` + schema in `docs/agent-efficiency/` (Sprint 12+) |
| Onboarding without re-explaining | `docs/architecture/index.md` domain map |

---

## Sprint 8 — Foundation (scripts + domain map)

| # | Deliverable | Status |
|---|-------------|--------|
| 8.1 | This plan (`docs/agent-efficiency-plan.md`) | Done |
| 8.2 | `scripts/pre-push.sh` — full gate (single source of truth) | Done |
| 8.3 | `scripts/pre-push-changed.sh` — changed-files subset | Done |
| 8.4 | `docs/architecture/index.md` — domain → routes → Flutter → tests | Done |
| 8.5 | `docs/refactoring-log.md` Sprint 8 entry | Done |

**Exit:** Scripts executable; index covers all 12 Flutter features + Node domains.

---

## Sprint 9 — Skills library

Skills live in `.cursor/skills/<name>/SKILL.md`. Agents auto-discover via `description`;
invoke explicitly with `/skill-name`.

| # | Skill | `paths` scope | Status |
|---|-------|---------------|--------|
| 9.1 | `split-flutter-screen` | `flutter_app/lib/**` | Done |
| 9.2 | `add-bdd-playwright-scenario` | `e2e/**`, `flutter_app/test/bdd/**` | Done |
| 9.3 | `single-backend-route-change` | `server/routes/**`, `server/lib/**` | Done |
| 9.4 | `spawn-sprint-agents` | (global — spawn prompts) | Done |
| 9.5 | `security-error-audit` | `server/**` | Done |
| 9.6 | `pre-push-verify` | (global — before push) | Done |

**Memory cross-links:** Skills reference `.agents/memory/` where domain semantics matter
(auth refresh, health completion, localization enums, org_id validation, tool scrambling).

**Exit:** All six skills committed; `MEMORY.md` index updated.

---

## Sprint 10 — Rule scoping & doc dedup

| # | Action | Status |
|---|--------|--------|
| 10.1 | New slim `agent-core.mdc` (always-on pointers only) | Done |
| 10.2 | Remove `alwaysApply` from path-scoped rules (modularity, testing, security, single-backend, a11y) | Done |
| 10.3 | Slim `merge-policy.mdc`; move long tables to this plan + skills | Done |
| 10.4 | `agent-coordination.mdc` — scoped to spawn docs, not always-on | Done |
| 10.5 | Slim `AGENTS.md` + `CONTRIBUTING.md` → point at `scripts/pre-push.sh` | Done |

**Exit:** Always-on rule payload &lt; 5 KB; no triplicated pre-push blocks.

---

## Sprint 11 — Automations & babysit

| # | Deliverable | Status |
|---|-------------|--------|
| 11.1 | `.cursor/commands/babysit.md` — merge-ready PR loop | Done |
| 11.2 | `.github/workflows/pr-governance-hints.yml` — non-blocking PR hints (file size, BDD delta) | Done |
| 11.3 | `docs/agent-efficiency/prompt-templates.md` — copy-paste spawn prompts | Done |
| 11.4 | Update `CONTRIBUTING.md` agent workflow section | Done |

**Exit:** Babysit command available; PRs get governance hints without changing CI gates.

---

## Sprint 12 — Autonomous plan schema (Phase A)

Foundation for `/execute-plan` and `/babysit-plus` skills. Schema and policy docs only — no skills in this sprint.

| # | Deliverable | Status |
|---|-------------|--------|
| 12.1 | `docs/agent-efficiency/execute-plan-schema.md` + JSON schema | Done |
| 12.2 | `docs/agent-efficiency/plan-template.md` | Done |
| 12.3 | `docs/agent-efficiency/phase-exit-checklists.md` | Done |
| 12.4 | `docs/agent-efficiency/autonomous-pr-policy.md` | Done |
| 12.5 | `docs/agent-efficiency/github-labels.md` | Done |
| 12.6 | `.agents/plans/` example + README | Done |
| 12.7 | `scripts/validate_execute_plan_snapshot.js` | Done |

**Policy highlights:** frozen snapshot, `status` + `status_reason`, `allowed_exceptions` enum, 48h `approved_until`, halt-only revoke, debt issue dedupe, merge-done phase gate.

**Next:** See Phase D below (done).

---

## Sprint 12 — Phase B: Babysit+ skill

| # | Deliverable | Status |
|---|-------------|--------|
| 12.B.1 | `.cursor/skills/babysit-plus/SKILL.md` | Done |
| 12.B.2 | Policy cross-links updated | Done |

**Exit:** Skill operational; links to canonical policy (no duplicated prose). Plain `/babysit` unchanged.

**Next:** See Phase D below (done).

---

## Sprint 12 — Phase C: Control issue + plan artifact runtime

| # | Deliverable | Status |
|---|-------------|--------|
| 12.C.1 | `scripts/lib/execute_plan_lib.js` — shared validation + runtime | Done |
| 12.C.2 | `scripts/execute_plan_runtime.js` — gate, halt, resume, sync CLI | Done |
| 12.C.3 | `scripts/execute_plan_runtime.test.js` | Done |
| 12.C.4 | `docs/agent-efficiency/execute-plan-runtime.md` | Done |

**Exit:** Agents can gate autonomy, sync plan artifacts, render control-issue templates, and halt/resume without duplicating policy prose.

**Next:** Phase E auto/labeled merge hardening. See `docs/agent-efficiency/autonomous-pr-policy.md`.

---

## Sprint 12 — Phase D: Execute-plan skill

| # | Deliverable | Status |
|---|-------------|--------|
| 12.D.1 | `.cursor/skills/execute-plan/SKILL.md` | Done |
| 12.D.2 | `.cursor/commands/execute-plan.md` | Done |
| 12.D.3 | Policy cross-links updated | Done |

**Exit:** Orchestrator skill operational; **babysit-plus active by default with merge mode `auto`** unless snapshot overrides; phase gate = merge-done; links to canonical policy (no duplicated prose).

**Next:** Phase E merge-mode hardening → ~~Phase F spawn-within-phase~~ (documented in execute-plan skill §Phase delegation) → Phase G hardening + docs.

---

## Ongoing policy (after Sprint 11)

### During agent iteration

```bash
./scripts/pre-push-changed.sh
```

### Before integration → `main` PR (or single-agent merge)

```bash
./scripts/pre-push.sh
```

### Atomic PRs (one outcome)

- Canonical: `docs/agent-efficiency/atomic-pr-policy.md`
- One verifiable outcome per PR; cross-domain OK when serving that outcome
- Snag ladder: fix trivial same-file issues inline; else micro-PR or debt issue
- PR governance hints workflow posts **advisory** multi-area reminders (not blocking)

### Multi-agent spawn checklist

1. Read `/spawn-sprint-agents` skill (or `docs/agent-efficiency/prompt-templates.md`).
2. Create integration branch; publish ownership row in `docs/refactoring-log.md`.
3. Foundation agent merges shared fixtures (`api.ts`) first.
4. Parallel agents on **disjoint directories only**.
5. Coordinator runs `./scripts/pre-push.sh` once before final PR.

### When to escalate to human review

- Security-sensitive auth/crypto changes
- Database migrations altering production data shape
- Breaking API contract changes without version bump
- CI workflow gate changes (never weaken to pass)
- Product decisions (UX copy, pricing, legal text)

---

## Maintenance

| Trigger | Action |
|---------|--------|
| New Flutter feature | Add row to `docs/architecture/index.md` |
| New Node route domain | Same |
| New recurring agent workflow | Add Skill under `.cursor/skills/` |
| CI gate change | Update `scripts/pre-push.sh` + `agent-core.mdc` |
| Sprint parallel work | Update ownership matrix in `refactoring-log.md` |

---
title: Cursor agent framework
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-05
tags: [agent, engineering, cursor]
---
# Cursor agent framework

Engineering Router and protocol library for AgathaTrack Cloud Agents. **Consolidates** existing execute-plan, babysit, and path-scoped rules — does not replace runtime scripts or CI.

---

## User interface — five commands

Normal day-to-day workflows:

| Command | Purpose |
|---------|---------|
| `/execute-plan` | Multi-phase autonomous plans (snapshots, control issues, integration branches) |
| `/babysit-plus` | Bounded autonomous work: implement or PR triage → CI → merge |
| `/babysit-uat` | Final merge to `main` + pre-UAT E2E watch + remedial loop |
| `/e2e-debug` | Pre-UAT forensic fix on one remedial branch (hands off to babysit-uat) |
| `/ui-design-deep` | Design + production UI for flows, theme, multi-screen work |

You do **not** invoke internal protocols (`security`, `authorization`, etc.) — Tier 1 skills run the Router and load them automatically.

---

## Skill taxonomy

### Tier 1 — primary (document prominently)

The five commands above.

### Tier 2 — internal / advanced (orchestrator may invoke)

| Skill | When |
|-------|------|
| `/spawn-sprint-agents` | Parallel agents on integration branch |
| `/pre-push-verify` | Which pre-push script to run |
| `/dependabot-batch` | Weekly dependency batch |
| `/split-flutter-screen` | Screen extraction (execute-plan exit profile) |
| `/add-bdd-playwright-scenario` | New BDD journey |

### Tier 3 — merged into protocols (do not user-invoke)

| Former skill | Use instead |
|--------------|-------------|
| `/ui-check` | `protocols/accessibility.md` §Quick pass |
| `/single-backend-route-change` | `protocols/api-contract.md` + `validation.md` |
| `/security-error-audit` | `protocols/security.md` §5xx audit |

Stubs remain for compatibility; descriptions mark them internal.

---

## Architecture

```text
Five Tier 1 commands
        ↓
Engineering Router (.cursor/agent-kernel/ROUTER.md)
        ↓
Selective protocols (.cursor/agent-kernel/protocols/)
        ↓
Existing runtime (execute_plan_runtime, babysit scripts, phase exits, pre-push, CI)
```

### Rules vs protocols

| Layer | Location | Loaded by |
|-------|----------|-----------|
| **Rules** | `.cursor/rules/*.mdc` | Cursor globs / alwaysApply — ambient constraints |
| **Protocols** | `.cursor/agent-kernel/protocols/` | Router — task checklists after classification |

---

## Router workflow

1. **Inspect** (depth scales with risk; R0 = changed files only)
2. **Classify** domains and technical surfaces
3. **Assign risk** R0–R3 (default R1; escalate on facts)
4. **Resolve protocols** (cumulative trigger table in ROUTER.md)
5. **Map verification** to `./scripts/pre-push-changed.sh`, Jest, flutter test, phase exits

### Router profiles

| Profile | Skills |
|---------|--------|
| full | execute-plan phase start; babysit-plus implementation |
| diff-scoped | babysit-plus PR-only; babysit-uat |
| classify-first | e2e-debug |
| design-scoped | ui-design-deep |

Details: [router-scenarios.md](./router-scenarios.md).

---

## Risk model (summary)

| Level | Meaning |
|-------|---------|
| R0 | Non-behavioural — lightweight verification |
| R1 | Ordinary localized change |
| R2 | API, AuthZ, persisted/sensitive data, schema, sharing |
| R3 | Auth architecture, private storage, destructive migration, custody |

**Strengthen ≠ scope creep:** execute-plan annotates gaps; splits phases when new independent outcomes appear. See ROUTER.md and [atomic-pr-policy.md](../agent-efficiency/atomic-pr-policy.md).

---

## Definition of done

Work is complete when:

1. Requested outcome is met
2. Router-determined verification is green
3. Pre-PR critical self-review passed ([pr-review-cost-efficiency.md](../agent-efficiency/pr-review-cost-efficiency.md))
4. Phase exit profile satisfied (execute-plan)
5. Independent integration review for R2+ material changes

Always-on pointer: `.cursor/rules/agent-core.mdc`.

---

## Parallel workers

Shared architecture is centrally owned — domain workers consume, not redefine, auth/AuthZ/API errors/validation/session/storage.

Brief templates: `.cursor/agent-kernel/workers/`.  
Coordination: `.cursor/rules/agent-coordination.mdc`.

---

## Enforcement

| Concern | Enforcement |
|---------|-------------|
| File size, BDD gate, npm audit high+ | **CI** |
| pre-push scripts | **Scripts** (agent runs) |
| Protocol checklists, AuthZ matrix, OpenAPI | **Agent-required** (Pet Care hardening may add CI) |
| Router classification | **Agent discipline** |

---

## Adding future guidance

1. Extend trigger row in `ROUTER.md`
2. Add or extend a protocol under `protocols/`
3. Map to `phase-exit-checklists.md` if execute-plan exit profile needed
4. **Do not** add a new user-facing slash command unless truly a new workflow (e.g. future `/release-gate`)

---

## Related docs

| Doc | Role |
|-----|------|
| [compatibility-map.md](./compatibility-map.md) | v2 inventory |
| [router-scenarios.md](./router-scenarios.md) | Acceptance fixtures |
| [autonomous-pr-policy.md](../agent-efficiency/autonomous-pr-policy.md) | PR hygiene |
| [phase-exit-checklists.md](../agent-efficiency/phase-exit-checklists.md) | Phase merge gates |
| `docs/architecture/index.md` | Domain map |
| `docs/domains/pet_care/README.md` | Pet Care scope |

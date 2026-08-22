---
title: Atomic Pr Policy
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [agent-efficiency, policy]
---
# Atomic PR policy (canonical)

Single source of truth for **one-outcome PRs**, **snag handling**, and **zero untracked debt**.
All agents (Cursor, Copilot, Replit, humans) follow this document. Tool-specific files **link here** — they do not restate full policy.

| Topic | Canonical location |
|-------|-------------------|
| Merge / branch strategy | `.cursor/rules/merge-policy.mdc` |
| Autonomous PR operator | [autonomous-pr-policy.md](./autonomous-pr-policy.md) |
| Multi-phase plans | [execute-plan-schema.md](./execute-plan-schema.md) |
| Architecture domains | [../architecture/index.md](../architecture/index.md) |

---

## Core principle: one outcome

**One PR = one verifiable outcome** that can be described in a single sentence, merged independently, and reverted without leaving the product in a half-finished state.

Cross-domain changes are **expected and fine** when they serve that one outcome (e.g. login redesign touching Flutter UI, auth routes, and one E2E spec).

### Good (one outcome)

| PR title (one sentence) | Why it works |
|-------------------------|--------------|
| Redesign login screen | UI + auth route tweak + E2E — same user-visible outcome |
| Fix health entry date off-by-one | API + Flutter + one BDD scenario — same bug fix |
| Extract `HealthEntryCard` widget | Screen split + widget tests — same refactor |

### Split (multiple outcomes)

| PR content | Why to split |
|------------|--------------|
| Login redesign **and** pets list refactor | Independent outcomes; either can merge alone |
| Health bug fix **and** org adoption cleanup | Unrelated domains and intents |
| New billing feature **and** CI workflow tweak | Feature vs governance — separate PRs |

---

## Before opening or continuing a PR

Ask in order:

1. **One sentence?** Can you describe the outcome without “and also…”? → If no, split.
2. **Independent merge?** Would merging this leave anything half-done for *this* outcome? → If yes, sequence stacked PRs (prep → behavior → E2E).
3. **Independent revert?** Could you revert this PR alone without breaking unrelated features? → If no, narrow scope.
4. **Unrelated drive-by?** Any change not required for this outcome? → Micro-PR or debt issue (see §Snag ladder).

**Domain count is a hint, not a gate.** Touching auth + server + E2E for one flow is normal. Touching auth **and** org for unrelated reasons is a split signal.

---

## Stacked PRs (multi-step work)

Prefer **merge small, then continue** over one large PR:

| Step | Example | Merge before next? |
|------|---------|-------------------|
| 1. Prep | File split, extract widget, scaffold tests | Yes |
| 2. Behavior | Route + mirror + unit tests | Yes |
| 3. Journey | Gherkin + Playwright (if journey is the outcome) | Yes |

Each step = its own branch and PR. Rebase the next branch on `main` after each merge.

### Integration-branch sprints

Parallel agents use an integration branch → one PR to `main`. Atomicity applies to **each agent branch** before integration merge, not to the coordinator’s batched integration PR. See `/spawn-sprint-agents`.

---

## Snag ladder (zero untracked debt)

**Zero debt** means **no silent deferrals** — every snag is fixed, micro-PR’d, or filed.

| Situation | Action |
|-----------|--------|
| Same file, ≤15 lines, no API/behavior change (typo, lint, dead import, obvious label) | Fix in **current PR** |
| Same outcome, different file, low risk (missing semantic label, format, test mirror path) | **Micro-PR** same day (preferred) or same PR if blocking merge |
| Different outcome, or needs product/architecture decision | **Debt issue** immediately — never bundle |
| Reviewer nit, out of scope for this PR | **Debt issue** with dedupe per [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Debt issues |
| Blocker / security gap | Fix in **current PR** — never defer |

### Micro-PR conventions

- Branch: `cursor/snag-<short-description>-94a2` (or your agent suffix)
- Title: `snag: <what>` — one-line outcome
- Target: `main` directly when CI green
- Optional label: `snag` (see [github-labels.md](./github-labels.md))

### Never

- “While I’m here” refactors unrelated to the stated outcome
- Silent TODOs without a linked issue
- Bundling unrelated reviewer nits to avoid opening issues

---

## Enforcement posture

| Layer | Role |
|-------|------|
| **This document** | Normative — agents and humans follow the one-outcome + snag rules |
| **`AGENTS.md`, `CONTRIBUTING.md`, tool instructions** | Short pointers + link here |
| **PR template** | Author self-check |
| **PR governance hints** (GitHub Action) | **Advisory only** — multi-area reminder, not a block |
| **CI gates** (`pre-push.sh`, file size, BDD, tests) | Objective quality only — **not** scope/outcome judgment |

There is **no blocking CI gate** for PR scope or outcome. Trust the rule; use hints for drift awareness.

---

## PR description template

```markdown
## Outcome
<!-- One sentence: what this PR achieves -->

## Scope
<!-- Areas touched (OK if multiple — confirm they serve the outcome above) -->

## Snags
<!-- Fixed inline / micro-PR #N / issue #N — or "none" -->

## Test plan
<!-- How you verified -->
```

---

## Escalation (always stop and ask human)

- Security / crypto changes
- Breaking API without version bump
- Production data migrations
- CI workflow gate changes
- Product / legal / UX decisions outside the stated outcome

See also [autonomous-pr-policy.md](./autonomous-pr-policy.md) §Escalation.

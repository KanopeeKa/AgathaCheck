---
title: Pr Review Cost Efficiency
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-02
tags: [agent-efficiency, policy, actions-cost]
---
# PR review & cost efficiency

**Homes:** pre-PR self-review · Copilot triage · **Cloud Agent model policy** · Actions cost levers.

| Topic | Also see |
|-------|----------|
| Babysit+ workflow | `.cursor/skills/babysit-plus/SKILL.md` |
| Triage / merge gates | [autonomous-pr-policy.md](./autonomous-pr-policy.md) |
| Always-on rule | `.cursor/rules/pr-hygiene.mdc` |

**Cursor Bugbot:** Retired for this repo (user decision). Do not configure, wait on, or document active Bugbot flows.

---

## Pre-PR critical self-review (mandatory)

Before the first push that opens a PR and before any behavior-changing PR update:

1. **Correctness & impact** — Happy paths, edge cases, error handling, regressions.
2. **Risks** — Security, data integrity, migrations, API contracts, concurrency.
3. **Design quality** — Smallest change; match patterns; no drive-by refactors.
4. **Better solution** — Adopt clearer/safer approach now if equal or less scope.
5. **Documentation** — `/canonical-docs sync` when behaviour changes (`.cursor/rules/documentation.mdc`).
6. **Verification** — `./scripts/pre-push-changed.sh` after adjustments.

Then: commit → push → create or update the PR.

---

## Review stack

```
Implementation
  → pre-PR critical self-review (mandatory)
  → open PR / mark ready

Copilot PR review (when enabled) → triage when threads exist

Babysit+ (composer-2.5 for babysit steps — see below)
  → babysit_pr_reviews.js wait --pr <url>   (Copilot done → triage every thread)
  → fix + pre-push-changed.sh → reply + resolve threads → push → wait again → CI
  → babysit_pr_reviews.js gate --pr <url>   (exit 0) → pre-push.sh → merge
```

When Copilot is unavailable or posts no threads: proceed after self-review + CI green + review gate (§Copilot unavailable). Full procedure: autonomous-pr-policy §Automatic reviews.

---

## Cloud Agent model policy

Usage data showed thinking models on babysit-scale work burn disproportionate tokens. **Babysitting stays on Composer 2.5.**

| Work | Model |
|------|--------|
| Feature implementation, refactors, execute-plan workers | `composer-2.5` default |
| Deep architecture / ambiguous product trade-offs | Thinking models **only when explicitly needed**; switch back after |
| `/babysit`, `/babysit-plus`, `/babysit-uat`, triage, CI loop, merge | **`composer-2.5` only** |

Controls: this section (SSOT), `.cursor/rules/pr-hygiene.mdc` pointer, dashboard default, separate cloud agent for babysit-only sessions. During execute-plan gate `0`, model mismatch alone is not a chat stop — autonomous-pr-policy §Execute-plan overrides.

---

## Cost levers (summary)

| Lever | Effect |
|-------|--------|
| Pre-PR self-review | Fewer fix iterations after open |
| `composer-2.5` for babysit | Avoid thinking-model burn on triage/CI |
| Copilot once per PR (dashboard) | Automatic review off agent pool |
| Push batching | Fewer `ci.yml` runs (`AGENTS.md` §Autonomy and merging) |
| Pre-UAT cancel superseded runs | Stale E2E grids stop when `main` advances |

---

## GitHub Actions minutes (Linux runners)

Copilot credits and Actions minutes are separate meters. Levers: batch pushes, integration programmes, merge-lease, ≤4 open `cursor/**` PRs with full CI — autonomous-pr-policy § CI cost.

### Decision log

| ID | Decision | Status |
|----|----------|--------|
| AEC-D-001 | Oct 2026 Actions spike mainly `ci.yml` volume, not Copilot runners | Live |
| AEC-D-002 | Trim triggers, push batching, Pre-UAT cancel-in-progress, PR E2E max 2 legs | Live |
| AEC-D-003 | Babysit skills wait for Copilot before triage, re-check reviews after every push and gate merge on `babysit_pr_reviews.js gate` (PR #2017 merged 1 s before Copilot's 3 threads; `collect` also failed under the `repo`-only bot token) | Live |

---

## Copilot unavailable

1. Do not request Copilot reviewer without credits.
2. Self-review + CI + `./scripts/pre-push.sh` before merge to `main`.
3. `wait --pr` timed out with Copilot still pending, or Copilot absent — triage any existing threads; `collect --pr` must show zero unresolved threads before merge.
4. Optional PR comment: Copilot unavailable; CI + pre-push only.

---

## Related

[autonomous-pr-policy.md](./autonomous-pr-policy.md) · [atomic-pr-policy.md](./atomic-pr-policy.md)

# Protocol: e2e

**When:** E2E failures, journey changes, locator drift, pre-UAT remedial work.

**Workflow owner:** `/e2e-debug` skill — this file is **principles only**.

**Memory:** `.agents/memory/uat-live-e2e-triage.md`, `docs/e2e/uat-deploy-tiers.md`.

---

## 1. Classification-first (mandatory)

Before changing tests, classify:

`PRODUCT BUG` · `TEST BUG` · `TEST DATA BUG` · `ENVIRONMENT BUG` · `RACE/SYNC` · `SELECTOR FRAGILITY` · `INFRASTRUCTURE` · `UNKNOWN`

Load other protocols **only if** root cause reaches those layers (e.g. 403 → `authorization`, `api-contract`).

## 2. Procedure

1. Reproduce exact failure (screenshot, trace, network, server logs)
2. Establish expected behaviour from BDD/spec/implementation
3. Find **earliest divergence** — timeout may be symptom not cause
4. Fix root cause
5. Rerun failing test → related spec → domain shard → lower-level tests if shared infra

## 3. Hard anti-patterns

Do not fix by default: longer timeout, arbitrary sleep, weaker assertion, overly broad selector, skip/flaky mark, retry — unless evidence proves correctness.

## 4. Locator hygiene

- Assert visibility, not DOM absence (Flutter web)
- Scope to target control, not parent container
- Semantics groups vs text — see drift checklist in e2e-debug skill

## 5. Conditional Router

| Class | Action |
|-------|--------|
| ENVIRONMENT / INFRASTRUCTURE | Fix env; minimal test change |
| SELECTOR FRAGILITY | Update locator with stable semantics |
| PRODUCT BUG | Fix product; may need api-contract, authorization, etc. |
| UNKNOWN | Gather evidence before edits |

---
title: GitHub Actions cost control programme
status: proposed
canonical_target: docs/agent-efficiency/pr-review-cost-efficiency.md
integration_branch: cursor/github-actions-cost-integration-aa0a
related_prs: []
tags: [agent-efficiency, ci, cost]
last_updated: 2026-10-12
---

# GitHub Actions cost control programme

Delivery plan: **six atomic PRs** merge into **`cursor/github-actions-cost-integration-aa0a`**, then **one PR** integration → `main` via **`/babysit-uat`**.

Evidence base: billing export Oct 1–12 2026; Actions API verification Oct 4–6 (`ci.yml` 455 runs/2d, ~29% cancelled, `cursor[bot]` ~60%, up to 8 concurrent CI workflows; Pre-UAT ~71 billed job-minutes/run, max 3 concurrent workflows Oct 5–6).

---

## Feasibility on integration branch (confirmed)

| Gate | Integration phase | Final → `main` |
|------|-------------------|----------------|
| **`ci.yml` on PRs** | Yes — `pull_request.branches` includes `cursor/*-integration-*` ([ci-cd-gates.md](../docs/pipelines/ci-cd-gates.md) §Path-scoped PR CI) | Yes |
| **`auto-babysit` / `docs-validation`** | Yes — `pull_request` without branch filter | Yes |
| **`docs-gate`** | Yes — all PRs | Yes |
| **Path scope / E2E selector (PR D)** | Validate via PRs into integration (workflow + e2e-only PR smoke) | Yes |
| **`pre-uat-e2e` cancel (PR F)** | **Not exercised** until push to `main` | Validate in **babysit-uat** watch after merge |
| **`/babysit-uat`** | **Do not use** on phase PRs (babysit-uat skill: intermediate → `/babysit-plus` only) | **Mandatory** on integration → `main` PR |

**Branch name:** `cursor/github-actions-cost-integration-aa0a` matches `cursor/*-integration-*`.

**Conclusion:** Programme is valid. Phases 1–2 and 4 (docs/policy) are fully testable on integration PRs; Pre-UAT concurrency behaviour is validated only after the final merge.

---

## Integration setup (once, before PR 1)

```bash
git fetch origin main
git checkout -b cursor/github-actions-cost-integration-aa0a origin/main
git push -u origin cursor/github-actions-cost-integration-aa0a
```

Optional: add a one-line row to `docs/debt/refactoring-log.md` (programme name, integration branch, file ownership: `.github/workflows/*`, `AGENTS.md`, `docs/agent-efficiency/*`, `e2e/scripts/select-affected-specs.mjs`).

**Ownership:** Single agent/session — all six PRs touch workflows and agent policy; do not parallelize.

---

## PR sequence (all target integration, not `main`)

Merge order is fixed (each branch rebases onto integration tip before open).

| # | Branch | Base | One-sentence outcome |
|---|--------|------|----------------------|
| **1** | `cursor/gh-cost-pr-a-triggers-aa0a` | integration | PR metadata edits no longer fire babysit/docs-validation |
| **2** | `cursor/gh-cost-pr-b-agent-policy-aa0a` | integration | Cloud Agents batch pushes; babysit+ defers micro-pushes |
| **3** | `cursor/gh-cost-pr-c-ci-dispatch-aa0a` | integration | `workflow_dispatch` on `ci.yml` defaults to path scope |
| **4** | `cursor/gh-cost-pr-f-preuat-cancel-aa0a` | integration | Superseded Pre-UAT runs cancel (`cancel-in-progress: true`) |
| **5** | `cursor/gh-cost-pr-d-e2e-cap-aa0a` | integration | PR affected E2E: **2 legs** max (was 3); 720s budget unchanged |
| **6** | `cursor/gh-cost-pr-e-merge-policy-aa0a` | integration | Document max open `cursor/**` PRs + merge-lease (no YAML platform cap) |

**Note:** PR F before D so Pre-UAT YAML lands before E2E tuning; policy PR last.

### PR 1 — Workflow triggers (A)

**Files**

- `.github/workflows/auto-babysit.yml` — `types: [opened, synchronize, reopened]` only
- `.github/workflows/docs-validation.yml` — drop `edited`

**Verify on integration PR**

- Edit PR title → babysit + docs-validation **do not** run
- Empty commit push → **do** run

**Docs:** `Docs: N/A — workflow trigger only`

---

### PR 2 — Agent push batching (B)

**Files**

- `AGENTS.md` — § CI cost (Cloud Agents): batch commits, one push per logical fix, local `pre-push-changed.sh`, no push for triage-only
- `.cursor/skills/babysit-plus/SKILL.md` — CI loop: accumulate fixes before push
- `docs/agent-efficiency/pr-review-cost-efficiency.md` — cost lever row + pointer to this programme (fold on delivery)

**Verify**

- `./scripts/pre-push-changed.sh` (docs-only diff)
- Manual review of skill wording

**Docs:** Mode A touch `pr-review-cost-efficiency.md` (partial; fold programme on final delivery)

---

### PR 3 — CI dispatch default (C)

**Files**

- `.github/workflows/ci.yml` — `force_full` default `false`; input description documents when to enable

**Verify on integration**

- `workflow_dispatch` without `force_full` → scope summary shows narrow stack on docs-only test PR

---

### PR 4 — Pre-UAT cancel superseded (F)

**Files**

- `.github/workflows/pre-uat-e2e.yml` — `cancel-in-progress: true`
- `docs/e2e/uat-deploy-tiers.md` — one paragraph: newest run wins; gate SHA check unchanged

**Verify on integration**

- `actionlint` / YAML review only
- **Full verify:** after final merge to `main` (babysit-uat): two quick merges or pushes → older Pre-UAT run shows `cancelled`

**Docs:** Mode A `uat-deploy-tiers.md`

---

### PR 5 — E2E leg cap (D)

**Decision:** **2 parallel affected legs** (not 3); keep **720s** budget in `select-affected-specs.mjs`.

**Files**

- `e2e/scripts/select-affected-specs.mjs` — default `maxLegs = 2` (CLI `--max-legs` still overridable)
- `scripts/ci/resolve-ci-scope.sh` or emitter if max legs duplicated — keep in sync
- `docs/pipelines/ci-cd-gates.md` — “≤2 legs” where it says ≤3
- Tests if present for selector JSON shape

**Verify on integration**

- PR that touches multiple E2E areas → CI matrix shows ≤2 `ci-e2e-affected` legs + canary
- `node e2e/scripts/select-affected-specs.mjs` unit behaviour if covered

**Docs:** Mode A `ci-cd-gates.md`

---

### PR 6 — Concurrency policy (E)

**Files**

- `docs/agent-efficiency/autonomous-pr-policy.md` — § CI cost / merge coordination: target **≤4 open `cursor/**` PRs** with CI; use integration branch for programmes; merge-lease before merge
- `docs/agent-efficiency/github-issue-workflow.md` — optional cross-link

**Verify**

- Docs validation workflow on integration PR

**Docs:** Mode A autonomous-pr-policy

---

## Per-PR hygiene (integration targets)

1. Rebase: `git fetch origin cursor/github-actions-cost-integration-aa0a && git rebase origin/cursor/github-actions-cost-integration-aa0a`
2. `/canonical-docs sync` when behaviour changes (PR 4, 5)
3. `./scripts/pre-push-changed.sh`
4. Open PR: **base = `cursor/github-actions-cost-integration-aa0a`**
5. **`/babysit-plus`** on each phase PR (not babysit-uat)
6. Squash merge to integration when CI green

---

## Final PR — integration → `main`

| Field | Value |
|-------|--------|
| **Branch** | `cursor/github-actions-cost-integration-aa0a` |
| **Base** | `main` |
| **Title** | `GitHub Actions cost control (integration programme)` |
| **Skill** | **`/babysit-uat`** |

### Babysit-uat checklist (final PR only)

**Phase 1 — Babysit+**

- Pre-PR critical self-review + canonical-docs **sync** (fold this `changes/` doc into `pr-review-cost-efficiency.md`; delete this file when fully delivered)
- §0–7: triage, CI loop, `./scripts/pre-push.sh`, squash merge to `main`
- Record `merge_sha`

**Phase 2 — Shard risk**

```bash
node scripts/babysit_uat_shard_risk.mjs --pr <n>
```

- Programme is mostly workflows/docs — expect `merge_action: wait`, poll pre-UAT only

**Phase 3–4**

- Only if pre-UAT fails → `/e2e-debug` → remedial PR → babysit-uat again

**Watch**

```bash
./scripts/babysit_uat_watch_preuat.sh <merge_sha> --json --timeout-min 90
```

**Post-merge manual check (PR F)**

- Actions: two pushes to `main` in succession → first Pre-UAT **cancelled**, second completes or fails on merit

---

## Success metrics (30 days after merge)

| Metric | Target |
|--------|--------|
| `ci.yml` runs on busy agent days | < 80/day |
| Cancelled `ci.yml` share | < 15% |
| Pre-UAT success rate | > 70% |
| Weekly gross Linux minutes (export) | < 5,000 unless declared integration week |

---

## Rollback

- Final merge is one squash — revert the integration merge commit on `main` if needed
- Per-lever: revert individual commits on integration before final PR if a phase regresses CI signal

---

## Out of scope (this programme)

- Disabling `ci.yml` or required checks
- Org-wide GitHub Actions spending limits (document only in PR 6)
- Copilot billing changes (separate meter; see `pr-review-cost-efficiency.md`)

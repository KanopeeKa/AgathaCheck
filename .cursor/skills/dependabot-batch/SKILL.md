---
name: dependabot-batch
description: >-
  Inventory open Dependabot PRs, drop unmergeable bumps, assemble one batch branch,
  run forced pre-merge E2E (shard-risk blind spot), babysit PR CI, merge via babysit-uat,
  and close superseded Dependabot PRs. Use weekly or when multiple dependency PRs queue.
paths:
  - .github/dependabot.yml
  - flutter_app/pubspec.yaml
  - flutter_app/pubspec.lock
  - server/package.json
  - server/package-lock.json
  - e2e/package.json
  - e2e/package-lock.json
  - scripts/babysit_uat*.sh
  - scripts/babysit_uat*.mjs
  - scripts/e2e_debug*.mjs
---

# Dependabot batch

Batch **open Dependabot PRs** into **one agent PR to `main`** to avoid N queued `pre-uat-e2e.yml` runs and lockfile conflict churn.

**Builds on:** `/babysit-plus` (PR CI) · `/babysit-uat` (merge + pre-UAT) · `/e2e-debug` (remedial)  
**Policy:** `docs/agent-efficiency/autonomous-pr-policy.md` · `docs/e2e/uat-deploy-tiers.md`  
**Config:** `.github/dependabot.yml`

---

## Why batch (not individual merges)

| Individual Dependabot PR | Batch PR |
|--------------------------|----------|
| N full PR CI cycles | 1 PR CI cycle |
| N pushes to `main` → N queued pre-UAT runs | 1 pre-UAT run |
| Lockfile conflicts across Flutter bumps | Resolve once |
| `babysit_uat_shard_risk` → `wait` (lockfile-only) | Skill **forces** preventive E2E |

`babysit_uat_shard_risk.mjs` returns **zero shards** for manifest/lockfile-only diffs — `/babysit-uat` will not proactive `/e2e-debug`. This skill **overrides** that for dependency merges.

---

## Model

**`composer-2.5` only** for inventory, babysit, E2E replay, and merge.

---

## Phase 0 — Inventory

```bash
gh pr list --author app/dependabot --state open \
  --json number,title,headRefName,mergeable,statusCheckRollup,files
```

Classify each PR:

| Bucket | Criteria | Action |
|--------|----------|--------|
| **Drop** | CI red for SDK/constraint conflict (e.g. `intl` vs `flutter_localizations` pin) | Close with reason; add `dependabot.yml` `ignore` |
| **Include** | CI green; patch/minor semver | Cherry-pick into batch branch |
| **Defer** | Major bump, migration-heavy (`go_router`, etc.) | Leave open or close with defer comment |
| **Group** | Same ecosystem / related packages | Merge together (e.g. `purchases_flutter` + `purchases_ui_flutter`) |

Record: PR numbers, branches, ecosystems, CI status.

---

## Phase 1 — Drop unmergeable PRs

For each **Drop** PR:

1. Comment explaining why (SDK pin, breaking change, etc.).
2. `gh pr close <n> --comment "…"`.
3. Add matching `ignore` entry in `.github/dependabot.yml` when the bump will recur.

---

## Phase 2 — Assemble batch branch

```bash
git fetch origin main
git checkout -b cursor/deps-batch-<YYYY-MM-DD>-6409 origin/main
```

For each **Include** PR:

```bash
git fetch origin <dependabot-head-branch>
git merge --no-edit origin/<dependabot-head-branch>
# or: git cherry-pick <dependabot-commit-sha>
```

Resolve `pubspec.lock` / `package-lock.json` conflicts once.

Commit message:

```text
chore(deps): batch weekly dependabot (<packages>) (supersedes #746, #747, …)
```

**Do not** close Dependabot PRs until the batch PR is merged.

---

## Phase 3 — PR CI (`/babysit-plus`)

1. Pre-PR critical self-review (`.cursor/rules/pr-hygiene.mdc`).
2. `./scripts/babysit_sync_base.sh --pr <url> --push`
3. `./scripts/pre-push-changed.sh`
4. Open/update PR to `main`; `gh pr ready`.
5. `node scripts/babysit_pr_reviews.js collect --pr <url>` — triage threads.
6. CI loop until `ci-gate / CI passed` + CodeQL green.
7. `./scripts/pre-push.sh` before merge attempt.

---

## Phase 4 — Preventive E2E (mandatory override)

Shard risk is empty for lockfile-only deps — **always** run local pre-UAT replay before merge:

```bash
./scripts/babysit_uat_bootstrap_stack.sh
cd e2e && npx playwright install chromium --with-deps   # fresh pods only
```

**Full batch (default — Flutter or e2e deps touched):**

```bash
for s in $(seq 1 13); do
  ./scripts/babysit_uat_run_shard.sh "$s" || exit 1
done
```

**Server-only batch** (only `server/package*.json` changed): minimum shards `1,3,9,11,12,13` plus any CI `@smoke-ci` failures.

On failure: fix on the **same batch branch** (test/locator drift first; rollback a dep only when proven cause).

```bash
./scripts/pre-push-changed.sh --e2e-shards <comma-separated failed shards>
```

---

## Phase 5 — Merge + pre-UAT (`/babysit-uat`)

1. Squash-merge batch PR when PR CI green and Phase 4 passed.
2. Record `merge_sha`.
3. `./scripts/babysit_uat_watch_preuat.sh <merge_sha> --json --timeout-min 90`
4. On failure → **/e2e-debug** (reactive) → remedial PR → **/babysit-uat** Phase 4 (max 3 rounds).

---

## Phase 6 — Cleanup

After batch PR merged and pre-UAT green:

```bash
for n in <superseded-pr-numbers>; do
  gh pr close "$n" --comment "Superseded by #<batch-pr> — merged in weekly dependabot batch."
done
```

---

## Execute-plan integration

| Phase type | Babysit skill |
|------------|---------------|
| Skill + `dependabot.yml` ignore only | `/babysit-plus` |
| Batch deps PR → `main` | `/babysit-uat` (includes Phase 3–6 here) |

Recommended snapshot:

1. **Phase 1** — skill + config (`allowed_paths`: skill, `dependabot.yml`, plan artifacts)
2. **Phase 2** — batch branch (`allowed_paths`: `flutter_app/pubspec.*`, `server/package*`, `e2e/package*`)

---

## Avoid wasting time

| Do first (cheap) | Defer (expensive) |
|------------------|-------------------|
| Inventory + drop bad PRs | Full 13-shard replay |
| Batch assembly + PR CI | Bootstrap stack |
| `pre-push-changed.sh` | Remedial loop on `main` |

| Rule | Why |
|------|-----|
| **Drop before batch** | Don't merge SDK conflicts into batch |
| **One batch PR** | Pre-UAT queues per `main` push |
| **Force E2E** | Shard risk blind spot for lockfiles |
| **Close after merge** | Keep Dependabot PRs open until batch lands |
| **composer-2.5 only** | Babysit policy |

---

## Related

| Skill | When |
|-------|------|
| `/babysit-plus` | PR CI on batch branch |
| `/babysit-uat` | Merge batch to `main` + pre-UAT watch |
| `/e2e-debug` | Pre-UAT remedial after merge |
| `/pre-push-verify` | Before push; `--e2e-shards` after E2E fixes |
| `/execute-plan` | Orchestrate skill + batch phases |

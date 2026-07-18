# Promotion contract

Canonical reference for **auto-promotion** on `KanopeeKa/AgathaCheck`: merge to
`main` → UAT tag → UAT deploy → prod stub/release tag.

Implementation phases: PR **#A** (ci-gate) through **#F** (doc cleanup). Phase **#D**
(prod stub + auto semver) is implemented in `deploy-prod.yml`. Phase **#E**
(UAT DB migrations) is implemented in `deploy-uat.yml`. Phase **#F** (legacy
`release/uat-*` doc cleanup → tag-first model) is complete. Gate names
and branch rules: [ci-cd-gates.md](./ci-cd-gates.md).

---

## Tag formats

| Kind | Pattern (regex) | Example | Created by |
|------|-----------------|---------|------------|
| **UAT** | `^uat-[0-9]{6}-[0-9]+$` | `uat-260716-170` | `promote-uat.yml` on merge to `main` |
| **Prod (stable)** | `^v[0-9]+\.[0-9]+\.[0-9]+$` | `v1.0.3` | `deploy-prod.yml` when `PROD_DEPLOY_ENABLED=true` |
| **Prod (stub / pre-infra)** | `^v[0-9]+\.[0-9]+\.[0-9]+-rc\.[0-9]+$` | `v1.0.3-rc.1` | `deploy-prod.yml` when `PROD_DEPLOY_ENABLED` is not `true` |

**UAT tag composition:** `uat-` + `YYMMDD` (UTC) + `-` + PR number.

Malformed refs must be rejected in workflow validation via
[`scripts/ci/assert-uat-tag.sh`](../scripts/ci/assert-uat-tag.sh) (added in Phase 1)
before any deploy or tag push.

GitHub tag rulesets (repository settings):

- **UAT tag** — `refs/tags/uat-*`, immutable
- **PROD tag** — `refs/tags/v*.*.*` (fnmatch; matches `v1.0.3`, `v1.0.3-rc.1`, etc.),
  immutable, requires successful **UAT** environment deployment before tag creation

  **Operator note:** ruleset **PROD tag** (id `19066125`) must use `refs/tags/v*.*.*`.
  If the UI shows `refs/tags/v**.**.*` (double-star typo), correct it — that pattern
  is not the intended semver glob.

---

## PR-only promotion

Every UAT tag must map to exactly one merged pull request.

| Condition | Behaviour | `promotion_block_reason` |
|-----------|-----------|--------------------------|
| 0 associated PRs | **Fail** — no tag, no deploy | `no_pr` |
| 2+ associated PRs | **Fail** — ambiguous | `ambiguous_pr` |
| 1 associated PR | Proceed | — |
| Direct push to `main` | Promotion fails (`no_pr`) | `no_pr` |

**Branch protection:** `main` must disallow direct pushes for all roles except
break-glass admins (`Main protection` ruleset). Promotion failure alone is not
sufficient if an admin can push untested commits.

PR resolution: GitHub REST
`GET /repos/{owner}/{repo}/commits/{sha}/pulls` (or equivalent). Emit
`promotion_block_reason` and related fields to `GITHUB_OUTPUT` and the Actions
step summary for alerting (`PROMOTION_WEBHOOK_URL` optional).

---

## Accepted trade-off: no CI re-run on `main`

After merge, **`promote-uat.yml`** does not re-run CI on the merge commit.

**Tag push → deploy chain:** `promote-uat.yml` creates `uat-*` tags with the default
`GITHUB_TOKEN`. GitHub does **not** fire `on: push: tags` workflows for those refs
(to prevent recursive runs). **`deploy-uat.yml`** therefore also listens for
`workflow_run` after **Promote UAT** completes and resolves the tag for the merge
commit. Manual tag pushes (non-`GITHUB_TOKEN`) still trigger `deploy-uat` via tag push.

We rely on:

- `ci-gate / CI passed` + `Analyze JavaScript` on the PR
- **Require branches to be up to date before merging** (`strict_required_status_checks_policy`)

Squash/rebase merge SHAs may differ from the last PR head SHA. Residual risk is
**accepted** in exchange for fast auto-promotion. See [ci-cd-gates.md](./ci-cd-gates.md).

---

## Idempotency

### UAT tag (`uat-YYMMDD-PR#`)

| State | Action |
|-------|--------|
| Tag absent | Create tag on merge commit, push, build artifact |
| Tag exists, **same SHA** | Exit **success** — `already_promoted=true` |
| Tag exists, **different SHA** | **Fail** — `promotion_block_reason=tag_sha_collision` |

### Prod stable tag (`vX.Y.Z`)

| State | Action |
|-------|--------|
| Tag absent | Create after green UAT `prod-ready` |
| Tag exists, **same SHA** as promoted UAT commit | **Success** — `already_released=true`, skip create |
| Tag exists, **different SHA** | Bump patch deterministically until free or same SHA |

### Prod stub tag (`vX.Y.Z-rc.N`)

While `PROD_DEPLOY_ENABLED` is not `true`, create **`-rc.N`** tags only (not
stable `vX.Y.Z`). Increment `N` per UAT promotion on the same base version.
Stable `v*` tags begin when prod infra is live and `PROD_DEPLOY_ENABLED=true`.

---

## Semver source of truth

| Phase | Rule |
|-------|------|
| **Stub** (`PROD_DEPLOY_ENABLED` ≠ `true`) | Latest `v*.*.*` (exclude `-rc`) → next patch → append `-rc.1`, or increment `-rc.N` on reruns |
| **Live prod** | Latest stable `v*.*.*` → patch +1; bootstrap `v1.0.0` if none (matches `pubspec.yaml` `1.0.0+1`) |

No manual version input at deploy time.

---

## Prod deploy behaviour

| `PROD_DEPLOY_ENABLED` | FTP/SSH deploy | Release tag | Workflow conclusion |
|-----------------------|----------------|-------------|---------------------|
| unset / `false` | **Skipped** | `vX.Y.Z-rc.N` | **Success** — job `Production deploy skipped (intentional)` |
| `true` | Full `deploy-prod.yml` path | Stable `vX.Y.Z` | Success after smoke |

Step summary must state explicitly:

> Prod deployment skipped intentionally (`PROD_DEPLOY_ENABLED` is not `true`).
> No FTP/SSH steps ran.

---

## Concurrency

| Workflow | Group | `cancel-in-progress` | Rationale |
|----------|-------|----------------------|-----------|
| `promote-uat.yml` | `promote-uat-main` | `false` | Queue promotions — no lost tags |
| `deploy-uat.yml` | `deploy-uat` | **`false`** | **Queue** — preserve full E2E run as audit evidence; freshness via queue order |
| `deploy-prod.yml` | `deploy-prod` | `false` | One prod promotion at a time |

To prefer **freshness over audit continuity**, set repo variable
`UAT_CANCEL_IN_PROGRESS=true` (optional; default queue).

---

## Traceability

### `build-manifest.json` (inside web artifact)

Existing fields via `scripts/ci/write-build-manifest.sh`. Promotion phases add:

- `pr_number`
- `uat_tag`
- `promote_run_id`

### `promotion-manifest.json` (Actions artifact)

Written by `promote-uat.yml`; updated downstream with run IDs:

```json
{
  "commit_sha": "full40charsha",
  "pr_number": 170,
  "uat_tag": "uat-260716-170",
  "artifact_name": "web-build-abc1234",
  "promote_run_id": "12345678",
  "uat_deploy_run_id": "",
  "prod_run_id": ""
}
```

---

## UAT database migrations (phased)

| Stage | `UAT_AUTO_MIGRATE` | Behaviour |
|-------|-------------------|-----------|
| 5a | unset | `node scripts/migrate.js status` in summary; warn if pending |
| 5b | `true` | `node scripts/migrate.js up` over SSH (mirror prod) |
| 5c | enforce | Fail `prod-ready` if pending and auto off |

---

## Machine-readable promotion outcomes

`promote-uat.yml` exports to `GITHUB_OUTPUT` and step summary:

| Field | Values |
|-------|--------|
| `promotion_status` | `promoted` \| `already_promoted` \| `blocked` |
| `promotion_block_reason` | `no_pr` \| `ambiguous_pr` \| `tag_sha_collision` \| `invalid_tag` \| `ci_gate_missing` (reserved) |
| `uat_tag` | e.g. `uat-260716-170` |
| `commit_sha` | merge commit |
| `pr_number` | integer |

Use these fields for webhooks and dashboards.

---

## Maintenance

- Any new **blocking** job added to `ci.yml` must be listed in `ci-gate` `needs:` —
  see [ci-cd-gates.md §1](./ci-cd-gates.md#1-blocking--pull-request-to-main).
- Tag regex or semver policy changes require updates to this file and
  [`scripts/ci/assert-uat-tag.sh`](../scripts/ci/assert-uat-tag.sh) (Phase 1).

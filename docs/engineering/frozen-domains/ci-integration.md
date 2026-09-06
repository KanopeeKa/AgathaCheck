---
title: Frozen domains — CI integration
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-07
tags: [engineering, frozen-domains, ci]
---

# CI integration (active vs frozen)

Minimal changes — no archived GitHub workflow (D-MVP-10).

## Active CI excludes

| Layer | Mechanism |
|-------|-----------|
| Flutter unit | Remove `org` shard from `ci.yml`; `run_tests_ci_shard.sh` skips `test/features/organization` |
| Jest | `jest.config.active.cjs` ignores `manifest.testRoots` + frozen server test globs by behaviour |
| E2E pre-UAT | `shard-files.mjs` lists **active specs only** (frozen specs stay on disk, not in manifest) |
| BDD gate | `check_bdd_coverage.js` skips `bddFeaturePatterns` |
| Smoke-ci | No org/foster/shelter scenarios |
| Analyze | `analysis_options.yaml` excludes `sourceRoots` after router disconnect |

## Blocking governance (active)

- `scripts/check_frozen_domain_boundaries.sh` — no active imports of frozen roots
- File size, smoke-tag invariants (active specs), `assert-ci-gate.sh`

## Not built

- Monthly archived workflow
- Manifest generator
- `_frozen/` test directory moves
- Exhaustive per-file Jest catalog

## Manual only

```bash
./scripts/test-frozen-domains.sh   # after phase 2
ENABLE_FROZEN_DOMAINS=true …      # local API rehydration
```

See [docs/pipelines/ci-cd-gates.md](../../pipelines/ci-cd-gates.md) after phase 4 merge.

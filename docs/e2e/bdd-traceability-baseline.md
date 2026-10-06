---
title: BDD traceability vs execution baseline (Batch J phase 3)
owner: Engineering
audience: agent
status: active
last_updated: 2026-10-06
tags: [e2e, bdd, baseline]
---

# BDD traceability vs execution baseline

Batch **J.3** separates three figures from `e2e/scripts/check_bdd_coverage.js`. Only **traceability** (mapped active scenarios) is blocking at **68% of gated active scenarios**; execution and quality are report-only in this batch.

Regenerate live counts:

```sh
node e2e/scripts/check_bdd_coverage.js --report-only
```

## Recorded figures (2026-10-06, integration @ phase 2 merge)

| Figure | Metric | Value | Blocking |
|--------|--------|------:|:--------:|
| **(a) Traceability** | Gated active scenarios mapped to `@bdd` specs | **145 / 182** (79.7%) | Yes — gate **123** mapped (68%) |
| **(b) Execution** | Mapped scenarios scheduled in Pre-UAT shards (`shard-files.mjs`) | **145 / 145** scenarios; **31 / 31** spec files | Report-only |
| **(c) Quality** | Active specs with skeleton/orphan signals (`no-bdd-scenario`, `no-expect`, `skip-or-fixme`) | **14** spec files | Report-only |
| — | Header-only `@bdd` mappings (phantom traceability) | **52** mappings (51 gated phantom excluded from denominator) | Informational |

Exclusions match `docs/engineering/frozen-domains/manifest.json` (`bddFeaturePatterns`, `@frozen` / `@legacy` tags) and `e2e/scripts/frozen-e2e-specs.mjs`.

Canonical gate universe row: `docs/engineering/active-codebase-baseline/README.md` §Measured universes (BDD blocking gate).

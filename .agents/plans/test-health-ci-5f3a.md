# Test health & CI gates — coverage, speed, pre-merge E2E, WAF-proof UAT, new test types

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `test-health-ci-5f3a` |
| **title** | Test coverage, CI gate and test-type overhaul (keep PR CI short) |
| **author** | Claude Code (cloud session) |
| **created** | 2026-09-30 |
| **base_branch** | `main` |
| **work branch** | `claude/relaxed-einstein-jqecfg` (one commit per phase: `phase(<n>/7): …`) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

Each phase is one verifiable outcome (atomic-pr policy).

## Landings and coordination

This programme is **TEST** in [parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md)
(landing order §4, area ownership §3, rules §5, TEST deltas §6, broadcast template §7).

| Landing | Content | Branch | Lands |
|---|---|---|---|
| TEST 1a | plan bootstrap + phase 1 (fixes #1453) | `claude/relaxed-einstein-jqecfg` | right after ARCH D, or before it if green first (human decision 2026-09-30) |
| TEST 1b | phases 2–3 | `claude/test-health-ci-p2-3-5f3a` (rebased on `main` after 1a) | after 1a |
| TEST 2 | phases 4, 6, 7 (+5 once CARE's BDD disposition has landed) | new branch after 1b | §4 row 6 |

After each landing, post the §7 broadcast on every open programme control issue / PR.

**§6 deltas applied:**

- Phases 2–3 also run the short PR CI tier for PRs into integration branches
  (`cursor/*-integration-*`, plus the CARE and TEST work branches), within the same budgets.
- Phase 4 takes the 70 % domain-gate doc alignment from ARCH D.3 (no re-do) and owns the KPI
  generator ARCH J reuses.
- Phase 5 runs after CARE's BDD/Playwright disposition has landed, or excludes care features.
- Phase 7's migrations-vs-canonical-schema check enforces §5.5 (numbered at landing; manifest and
  canonical schema in the same PR); the IDOR matrix gets People and Care routes appended when
  those programmes land.

---

## Goal

Make the test pyramid trustworthy and fast again, based on the 2026-09-29 review
(Mistral plan + critique + live-tree/workflow-run verification):

1. **No silent coverage holes** — 33 active Flutter test files (`test/core` 28, `people` 3,
   `care_taxonomy` 2) run in no CI shard and not in `pre-push.sh`; 6 active Playwright tests
   tagged `@smoke-uat`/`@smoke-a11y` run only in the WAF-blocked live UAT job.
2. **PR CI stays short** — full-stack PR CI is 7.7–8.9 min; long pole is the `health` shard
   (379 s) because `run_tests_ci_shard.sh` spawns one `flutter test` process per file
   (~5.7 s/file) and every shard pays ~50–60 s setup (Flutter + apt `lcov`).
3. **E2E verified before merge, within a time budget** — 38 of 117 commits on `main` since
   2026-09-17 are post-merge E2E remediation; Pre-UAT E2E green 8/30 runs. `e2e/*` changes force
   the full Flutter stack (8 min) but never run the spec they fix.
4. **KPIs generated, not typed** — `docs/quality/scorecard.md` is stale (449/544/79+/65 %); docs
   say 65 % domain coverage while scripts enforce 70 %.
5. **BDD drift visible** — 12 active-spec drifts, ~99 frozen-spec orphans drowning the report,
   40 active scenarios uncovered.
6. **Live UAT signal that works around the WAF** — `uat-live-e2e.yml` failed 20/20 nights;
   Tiger Protect blocks GitHub runner auth traffic and **will not be fixed** (no CI IP
   whitelist). Validate UAT from *inside* the host over SSH instead, and never treat a WAF
   block as a product failure.
7. **New test types** — authz/IDOR, migration-vs-canonical schema, DAST (ZAP), load (k6),
   web bundle budget — each off the PR critical path unless it is cheap.

### CI time budget (non-negotiable)

| PR type | Target wall-clock | How |
|---|---|---|
| Docs / plan only | ≤ 1 min | unchanged scope rules |
| Backend only | ≤ 2.5 min | unchanged |
| Flutter (any domain) | **≤ 5 min** | batched `flutter test`, prep job, no apt lcov, rebalanced shards |
| `e2e/`-only | ≤ 6 min | skip Flutter unit stack; reuse `main` web build (cache); run affected specs |
| UI + affected E2E | ≤ 8 min worst case | affected specs capped at **12 min spec time over ≤ 3 legs**, overflow deferred to Pre-UAT |

New heavy suites (ZAP, k6, cross-tenant sweep over the full stack) run **weekly / on demand**,
never on PRs.

---

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-30T00:00:00Z |
| **approved_until** | 2026-10-02T00:00:00Z |
| **approved_by** | user chat 2026-09-29: "Go ahead, write up a plan such as execute-plan and then implement all of the above" (+ WAF constraint: work around, do not assume it can be fixed; keep CI reasonably short) |
| **control_issue** | [#1449](https://github.com/KanopeeKa/AgathaCheck/issues/1449) |
| **autonomy** | `active` |

---

## Phases

### Phase 1 — Flutter shard manifest + exhaustive test ownership

| Field | Value |
|-------|-------|
| **id** | `1` |
| **exit_checklist** | `governance` |

**Scope:**

- `flutter_app/test/ci_shards.json` — single source of truth for shard ids → test roots,
  excluded roots (integration dir, frozen roots from `docs/engineering/frozen-domains/manifest.json`).
- `scripts/ci/flutter-shards.mjs` — `list`, `roots <id>`, `files <id>`, `classify <paths…>`,
  `check` (every `*_test.dart` owned by exactly one shard, or frozen/excluded). Node unit tests.
- Add orphan roots: `test/core/**`, `test/features/people/**`, `test/features/care_taxonomy/**`.
- `run_tests_ci_shard.sh`, `merge_flutter_coverage.sh`, `scripts/pre-push.sh`, `ci-scope-lib.sh`
  read the manifest instead of hard-coded lists.
- `ci.yml` / `ci-full-audit.yml`: the per-shard jobs become one matrix job `flutter-test`
  (`matrix.shard` from ci-scope `run_shards`); `ci-gate` + `assert-ci-gate.sh` + tests track one
  job. Umbrella required check `ci-gate / CI passed` unchanged.
- Governance job runs `node scripts/ci/flutter-shards.mjs check`.

**Exit criteria:**

- [ ] `flutter-shards.mjs check` reports 0 unowned active test files
- [ ] Adding a shard = editing `ci_shards.json` only (+ docs)
- [ ] `ci-scope` / `assert-ci-gate` test suites green

### Phase 2 — Flutter CI speed (≤ 5 min full-stack PR)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **exit_checklist** | `governance` |

**Scope:**

- Batched shard runner: one `flutter test <files…> --concurrency=N --coverage` per shard with a
  JSON file reporter; on failure re-run only non-passing suites in isolation (per-file) to keep the
  historic segfault/hang protection; on batch timeout fall back to the full per-file loop.
- `scripts/ci/merge-lcov.mjs` (pure Node) replaces apt `lcov` in shards and in the coverage job
  (removes `setup-lcov` from the critical path).
- New `flutter-prep` job (codegen + legal sync + prep artifact); `flutter-analyze`, shards,
  integration and build-web depend on prep, so shards no longer wait for format + analyze.
- Rebalance shard roots from measured batched timings (target ≤ ~90 s of test time per shard).

**Exit criteria:**

- [ ] All active Flutter tests pass under the batched runner locally
- [ ] Estimated critical path ≤ 5 min (scope → prep → slowest shard → coverage → gate)
- [ ] Domain coverage gate still enforced at 70 % on full runs

### Phase 3 — Pre-merge E2E within budget + Pre-UAT balance

| Field | Value |
|-------|-------|
| **id** | `3` |
| **exit_checklist** | `governance` |

**Scope:**

- `e2e/scripts/spec-durations.json` (measured from Pre-UAT run 36611087844) +
  `e2e/scripts/spec-domains.mjs` (Flutter feature → specs map).
- `e2e/scripts/select-affected-specs.mjs`: changed paths → affected active specs, bounded by a
  spec-time budget (12 min) and ≤ 3 legs (LPT balanced); directly changed specs first; overflow is
  reported and left to Pre-UAT. Unit tested.
- `ci-scope`: `e2e/`-only PRs no longer force the Flutter unit stack; they run build-web (cache
  hit on the `main` build when Flutter inputs are unchanged) + affected specs.
- `ci.yml`: `ci-e2e-affected` matrix job (blocking via `ci-gate`, skipped when nothing selected).
- `_reusable-build-web.yml`: `actions/cache` of `build/web` keyed on Flutter build inputs; saved
  from `main` (Pre-UAT), restored by PRs.
- Pre-UAT shards computed by LPT from `spec-durations.json` (`shard-files.mjs`).
- PR CI tier also runs for PRs into integration branches (`cursor/*-integration-*`, CARE and TEST
  work branches) — parallel-programmes §6 TEST.2.
- Playwright `full` project stops excluding `@smoke-uat` / `@smoke-a11y` (6 active tests incl. axe
  scans finally run on localhost).
- Testing rule + e2e README: semantics-contract widget test for every page-object locator
  (pattern from #1235).

**Exit criteria:**

- [ ] `e2e/`-only PR scope: no Flutter unit shards, affected specs selected
- [ ] Selector unit tests cover budget/cap/overflow
- [ ] Max Pre-UAT shard estimate ≤ max(single spec) + 10 %

### Phase 4 — KPI generator + docs reconciliation

| Field | Value |
|-------|-------|
| **id** | `4` |
| **exit_checklist** | `governance` |

**Scope:**

- `scripts/quality/generate-scorecard-metrics.mjs`: live counts (Flutter active/frozen/unowned,
  Jest active/frozen, Playwright active/frozen, BDD mapped/active/gate/drift/uncovered, smoke tags,
  thresholds) → JSON / markdown; `--write-scorecard` refreshes a marked block in
  `docs/quality/scorecard.md`; `--check` enforces invariants (0 unowned tests, 0 active BDD drift,
  documented thresholds == script thresholds). Unit tests.
- `scripts/quality/ci-health-kpis.mjs` + weekly `quality-kpis.yml`: PR CI p50/p90, Pre-UAT pass
  rate, share of post-merge E2E remediation commits → job summary (advisory).
- Fix 65 %→70 % in `CONTRIBUTING.md`, `docs/pipelines/ci-cd-gates.md`, scorecard.

**Exit criteria:**

- [ ] Governance runs `--check`; scorecard numbers generated
- [ ] No doc states a threshold different from the enforcing script

### Phase 5 — BDD hygiene

| Field | Value |
|-------|-------|
| **id** | `5` |
| **exit_checklist** | `default` |

**Scope:**

- `check_bdd_coverage.js`: skip specs in `frozen-e2e-specs.mjs`; report active drift separately.
- Fix the 12 active drifts (rename header/feature or mark `@frozen`).
- `docs/quality/bdd-uncovered-triage.md`: decision per uncovered active scenario (implement /
  not-web / defer with issue).

**Exit criteria:**

- [ ] Active drift = 0; frozen spec titles not reported
- [ ] Every uncovered active scenario has a recorded decision

### Phase 6 — WAF-proof UAT verification

| Field | Value |
|-------|-------|
| **id** | `6` |
| **exit_checklist** | `governance` |

**Constraint:** Tiger Protect will keep blocking GitHub runner traffic (no CI IP whitelist). Work
around it; never classify a WAF block as a product failure.

**Scope:**

- `server/scripts/uat-inhost-smoke.mjs`: runs **on the UAT host over SSH** — starts the deployed
  app in-process on `127.0.0.1:<ephemeral>` with the UAT env and DB, then signup → pet → health
  entry → dashboard read → share link public view → account delete; checks 0 pending migrations.
  No request crosses Apache/Tiger Protect.
- `uat-live-e2e.yml` → nightly + after successful UAT deploy: SSH whitelist runner IP (existing
  `o2switch-ssh-whitelist.sh`), bundle + run the in-host smoke, always remove the runner IP;
  serialized with deploy via a shared concurrency group. External browser suite becomes manual
  (`workflow_dispatch` input) and WAF-classified as *inconclusive*, not red.
- Remove frozen organisation tests from `@smoke-uat`.
- Docs: `uat-deploy-tiers.md`, `uat-waf-queue-lessons.md`, memory.

**Exit criteria:**

- [ ] In-host smoke passes against a local stack (same script, `--base-app` mode)
- [ ] Nightly workflow no longer depends on any request passing the WAF

### Phase 7 — Security, performance and risk tests

| Field | Value |
|-------|-------|
| **id** | `7` |
| **exit_checklist** | `governance` |

**Scope:**

- Jest: unauthenticated route matrix — every mounted `/api` route rejects anonymous calls unless
  allow-listed as public (PR CI, fast).
- PG integration (`server/test/db`): cross-tenant IDOR tests (user B vs user A resources) and
  migrations-from-scratch vs canonical schema diff.
- Weekly `security-dast.yml`: OWASP ZAP baseline vs localhost stack (advisory, report artifact).
- Weekly `perf-weekly.yml`: k6 API load (p95 / error-rate thresholds) vs localhost (advisory).
- `scripts/ci/web-bundle-budget.json` + check in `_reusable-build-web.yml` (ratchet).
- Remove root clutter `new-key.asc` (PGP public key) and `gpg-check.txt`.

**Exit criteria:**

- [ ] New Jest + PG tests green locally
- [ ] Weekly workflows lint clean (actionlint) and documented in `ci-cd-gates.md`

---

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 6
last_completed_phase: 4
halt_reason: null
next_action: "continue phase 6 on branch claude/relaxed-einstein-jqecfg"
artifact_ref:
  branch: cursor/test-health-ci-phase6-edcb
  plan_path: .agents/plans/test-health-ci-5f3a.md
  plan_commit: bbb03c1f96cb22080c7a0dbf235ae8a429ef3e34
  snapshot_path: .agents/plans/test-health-ci-5f3a.snapshot.json
  snapshot_commit: bbb03c1f96cb22080c7a0dbf235ae8a429ef3e34
open_prs: []
merge_commits: {"2":"e89d8c4d7d4ef905b616dd4881bfda87028ae14b","3":"e89d8c4d7d4ef905b616dd4881bfda87028ae14b","4":"a436175f8c55caba2a8cd031b9450cef5f9ab6d5"}
debt_issue_refs: []
```

---

## Sanity check

- Every phase has paths, exceptions and an exit checklist (snapshot).
- Overlap: phases 1–3 all touch `ci.yml` / `ci-scope-lib.sh` / `ci-cd-gates.md` — sequential by
  design (no parallel spawn).
- Risk: CI workflow changes (escalation class) — explicitly granted by the human in chat; each
  phase validated with actionlint + ci-scope / ci-gate test suites before commit.
- No migrations, no auth or API behaviour changes (tests only on the server).

**Result:** `proceed-high-risk` (CI plumbing) — mitigated by local verification per phase.

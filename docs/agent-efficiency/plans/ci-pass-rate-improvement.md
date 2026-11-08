---
title: CI pass-rate improvement — specs
owner: Documentation Team
audience: both
status: in_delivery
status_since: 2026-11-08
last_updated: 2026-11-08
tags: [ci, agent-efficiency, e2e, pre-push]
folds_into: [docs/pipelines/ci-cd-gates.md, docs/agent-efficiency/autonomous-pr-policy.md, .cursor/agent-kernel/protocols/e2e.md]
---

# CI pass-rate improvement — specs

**Status:** proposed — no code. Four specs (S1–S4) plus shared measurement. Each spec is one PR outcome
(`atomic-pr-policy.md`) except S4, which is a short sequence.

**Owner decisions needed before delivery:** S2 (new non-blocking workflow) and S3 (change to a
`ci-gate` job) touch CI workflows — §Escalation in `autonomous-pr-policy.md` ("CI workflow gate
changes"). S1 and S4 need no escalation.

**Programme coordination:** S3 and S4 touch shared E2E infrastructure owned by the TEST programme —
follow [parallel-programmes.md](../parallel-programmes.md) §4–§6 before delivery. Measurement extends the
TEST programme's phase-4 KPI generator (#1468), not a second report.

**Review:** 2026-11-08 review folded in (existing registries reused, exit code, detector edge cases,
PR split, metric caveats).

## 1. Evidence (baseline)

**Window:** last 300 runs of workflow `CI` (`ci.yml`, all `pull_request`), 2026-11-03 22:31 →
2026-11-08 18:26 UTC, 79 head branches. Job-level detail: the **first failed run of every branch
whose first completed run was red** (25 runs, full census) plus 8 later failed runs (7 on the three
worst branches) — 33 of 118 failed runs. Playwright logs read: 4 jobs.

| Metric | Baseline |
|--------|----------|
| Runs: success / failure / cancelled / running | 110 / 118 / 70 / 2 |
| Raw pass rate (success ÷ success+failure) | 48% |
| Raw pass rate excluding the 3 worst branches | 71% |
| Branches green on first completed run | 53 / 78 (68%) |
| Median time first push → first green | 6 min (p75 18 min) |
| Longest red streak on one branch | 46 consecutive failed pushes |
| Failures from the 3 worst branches | 74 / 118 (63%) |

### 1.1 First-push failures (25 branches, full census)

| Class | Branches | Failing steps |
|-------|----------|---------------|
| **Cheap, locally checkable only** | 12 | `Check Dart format` (8), `Cross-feature import gate (D6)` (3), `BDD priority tags` (2), `File size gate` (2), `Documentation validation (strict)` (1) |
| **Shared base broken** | 6 | `PR startup smoke` + `Backend (Node.js Jest)` + `Backend integration (PostgreSQL)` together, all on `care-status-model-*` branches (5 within one minute on 2026-11-06 00:19) |
| **Substantive** (tests / E2E / bundle) | 7 | Playwright affected specs (5), Flutter shard tests (3), web bundle budget (1), plus backend Jest / integration / coverage on single branches; 5 of the 7 *also* failed a cheap check |

`Check Dart format` failed in **12 of 25** first failures and was the **only** failure in 4.

**Local parity gaps** (CI step vs `scripts/pre-push-changed.sh`, the script agents run while iterating):

| CI step | CI command | In `pre-push-changed.sh`? | In `pre-push.sh`? |
|---------|-----------|---------------------------|-------------------|
| Check Dart format | `dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test` | **No** | Yes (l.67) |
| BDD priority tags | `node scripts/check_bdd_priority_tags.js` | **No** | Yes (l.43) |
| Documentation validation | `bash scripts/validate_docs.sh --strict` | Non-strict, only when `docs/**` touched | — |
| Cross-feature import gate | `node scripts/check_feature_imports.js` | Yes (governance) | — |
| File size gate | `node scripts/check_file_size.js` | Yes | Yes |
| Web bundle budget | `node scripts/ci/check-web-bundle-budget.mjs` (needs release web build) | No | No |

Of the 12 cheap-only branches: **7** failed only on steps the script does not run (one of them, the
docs failure, counts only if it was strict-only — not verified), **3** on a mix, **2** only on steps
it does run (so the script was not run, or not re-run after the last edit).

### 1.2 Long red streaks (63% of all failures)

| Branch | Runs | Failures | First → green | Failing test(s) seen |
|--------|------|----------|---------------|----------------------|
| `cursor/tech-debt-reliability-8640-dev` (light-plan) | 49 | 46 | 24 h | `veterinarian.spec.ts:122` "user can edit a vet phone number" |
| `cursor/care-status-model-p6` | 31 | 14 | 3.5 h | `care.agenda.spec.ts:133` "Closed care link…" |
| `cursor/away-plans-e2e-13e3` | 17 | 14 | 15 h | `away.plans.journeys.spec.ts:121` (add/remove pets) |

- Every failure was a **new commit**: 46 distinct SHAs; from 14:52 on 2026-11-06 to 00:40 the next day,
  one push roughly every 12–15 min.
- Light-plan already says "same check red on **3 pushes** → stop" (`.cursor/skills/light-plan/SKILL.md`
  l.43, l.75). `autonomous-pr-policy.md` §CI retry budget says 5 / 3 iterations (an "iteration" is not
  defined). `e2e-debug` says max 3 full remedial loops per feature PR (l.266, inherited by
  `babysit-uat`). `babysit` has no number. The rule existed in four forms and nothing enforced it.
- The vet failures were **not mainly flakiness**. 2026-11-06 10:38: route mismatch (app on
  `/pc/people/<id>`, test expected the list). 2026-11-07 00:40: phone value empty in the edit form.
  #2114 (the streak's own PR) changed the test's expected route **and** added product-side "roster
  refetch" workarounds. #2123 then reverted those workarounds and fixed the detail phone a11y in the
  product. #2140 (2026-11-08) hardened `expectVetVisible` again. Real defects were found **one per
  run**, and the CI loop shipped workarounds that had to be undone.
- All E2E legs run `--max-failures=1` with `retries: 0` (`_reusable-e2e-local.yml:161`,
  `e2e/playwright.config.ts` project `full`). Logs show "4 did not run" and "12 did not run" after the
  first failure.

## 2. Goals and success metrics

**Outcome:** fewer PRs fail the CI gate, and none sits red for hours through blind CI iteration —
without weakening `ci-gate / CI passed`.

| ID | Metric (weekly, `CI` workflow, `pull_request`) | Baseline | Target |
|----|-----------------------------------------------|----------|--------|
| CIPR-M1 | Branches green on first completed run | 68% | ≥ 85% |
| CIPR-M2 | First failures caused only by cheap checks | 12 / 25 (48%) | ≤ 10% |
| CIPR-M3 | Longest consecutive red-push streak on one branch | 46 | ≤ 5 |
| CIPR-M4 | Raw pass rate (secondary — may lag M1–M3 if remaining failures are substantive) | 48% | ≥ 75% |
| CIPR-M5 | p90 time first push → first green | measure first | trend down |

**Non-goals:** making CI faster per run; changing which jobs `ci-gate` requires; base-branch health
(see §7 gaps).

## 3. S1 — Local pre-push parity with cheap CI checks

**Problem:** `pre-push-changed.sh` skips 2 cheap CI checks (format, BDD priority tags) and runs docs
validation non-strict. An agent following the rules still fails CI.

### Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| CIPR-R-001 | When Flutter paths are in scope (`needs_flutter`), `pre-push-changed.sh` runs the **same** format command as CI: `dart format --output=none --set-exit-if-changed flutter_app/lib flutter_app/test`. It runs **before** `flutter analyze` and tests (fail fast; CI step takes 3–5 s). | Planned |
| CIPR-R-002 | `run_governance` runs `node scripts/check_bdd_priority_tags.js`. | Planned |
| CIPR-R-003 | When `docs/**` is touched, local docs validation uses `--strict`, matching `_reusable-test.yml:62`. | Planned |
| CIPR-R-004 | Extend the existing registry `scripts/ci/governance-blocking-steps.mjs` (already consumed by `assert-ci-gate` tests and `governance-gates.md`) — **no new manifest or wrapper**. Add entries for `dart format` (CI: `_reusable-flutter-analyze.yml`) and `check_bdd_priority_tags.js` (CI: `_reusable-test.yml`), and a `prepush` field on every entry: `changed` (run by `pre-push-changed.sh`), `full-only`, or `exempt` with a reason ≥ 10 chars. `pre-push-changed.sh` runs the registry's `command` strings rather than restating them. "Cheap" = ≤ 60 s, no services, build or browser. | Planned |
| CIPR-R-005 | Extend `scripts/ci/governance-blocking-steps.test.mjs`: fails when a cheap `run:` step in `_reusable-test.yml` or `_reusable-flutter-analyze.yml` has no registry entry, or when an entry marked `prepush: changed` is not invoked by `pre-push-changed.sh`. Drift cannot come back silently. | Planned |
| CIPR-R-006 | Known exemption, recorded in the registry: web bundle budget (needs a release web build; 1 / 25 first failures). | Planned |
| CIPR-R-007 | On success the script prints `parity: <n>/<n> cheap CI gates run for <HEAD sha>`, which agents paste into the PR body as evidence (`AGENTS.md` §Reporting). | Planned |
| CIPR-R-008 | The same PR updates `.cursor/skills/pre-push-verify/SKILL.md`, `docs/agent-efficiency/governance-gates.md` and `.cursor/rules/testing.mdc` so they point at the registry instead of listing gates. | Planned |

### Acceptance criteria

| ID | Given / when / then |
|----|---------------------|
| CIPR-AC-001 | Given a branch with one unformatted `.dart` file, when `./scripts/pre-push-changed.sh` runs, then it exits non-zero at the format step with the same file list CI would print. |
| CIPR-AC-002 | Given a `.feature` scenario without `@P0/@P1/@P2`, when the script runs, then it fails in governance. |
| CIPR-AC-003 | Given a new cheap `run:` step added to `_reusable-test.yml` with no registry entry, when governance runs (locally or CI), then the registry test fails and names the step. |
| CIPR-AC-004 | Replaying the 12 cheap-only first-failure SHAs from §1.1: the script fails locally on every one of them. This proves detection only; whether agents run it is measured by CIPR-M2 (2 of the 12 already failed on gates the script runs). |
| CIPR-AC-005 | On a Flutter-touching change, the script takes ≤ 15 s longer than before. |

**Out of scope:** forcing agents to run the script. S2 covers the loop and R-007 the evidence line. A
git `pre-push` hook is deferred (CIPR-D-006): Cursor Cloud pushes go through the Cursor GitHub App.

**Expected effect (from data):** an upper bound of 12 / 25 first-push failures. 7 would be caught by
the parity changes alone; the other 5 also need the script actually run. CIPR-M1 rises from 68%
toward ~83% if nothing else fails on those branches — an upper bound, not a success criterion.

## 4. S2 — CI loop breaker (one budget, enforced)

**Problem:** agents iterate by pushing to CI. The retry budget exists in three different forms
(light-plan 3, policy 5 / 3, babysit none) and nothing enforces it. "Same check" was ambiguous: the
required check (`ci-gate / CI passed`) stayed the same while the symptom changed.

### Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| CIPR-R-010 | **One definition** in `autonomous-pr-policy.md` §CI retry budget. `light-plan`, `babysit`, `babysit-plus`, `execute-plan` and `e2e-debug` skills link to it instead of restating numbers. | Planned |
| CIPR-R-011 | Definitions. **Red push**: a push whose `CI` run concludes `failure` (`cancelled` does not count). **Streak**: consecutive red pushes on one PR head branch, reset by a green run. **Same signature**: the same failing job name, or for Playwright the same test id (`file:line › title`). | Planned |
| CIPR-R-012 | Streak **2** with a Playwright failure: before the next push, the agent must reproduce locally against the localhost stack with the same project and specs as CI, and record the classification (`.cursor/agent-kernel/protocols/e2e.md` §1) in the PR. | Planned |
| CIPR-R-013 | Streak **3** on the same signature, or streak **5** on any signature: **halt**. This **replaces** the 5 / 3 table in `autonomous-pr-policy.md` §CI retry budget, the light-plan "3 pushes" rule and the `e2e-debug` "max 3 full loops" line (which keeps its own scope: remedial loops after merge, linked to the same section). The agent stops pushing, posts one summary comment (failing tests, classification, hypotheses tried) and hands off: `/e2e-debug` for E2E, otherwise `**Needs you:**`. | Planned |
| CIPR-R-014 | `pre-push-changed.sh --e2e-specs <spec ...>` runs the named specs against `localhost:3000` exactly as CI does (`--project=full`). This is the documented local reproduction path for CIPR-R-012. | Planned |
| CIPR-R-015 | Mechanical detection: a **non-blocking** workflow (`ci-loop-detector.yml`, on `workflow_run` of `CI` completed) computes the streak for the PR. At threshold it adds label `ci-loop` and creates or updates **one** marker comment (`<!-- ci-loop -->`) with the streak and signatures. It removes the label on green. It never fails or blocks a check. Edge cases: one streak **per PR** (not per branch name) when several PRs share a head branch; fork PRs are skipped (no write token); permissions limited to `pull-requests: write` and `issues: write`; signatures from `results.json` test ids (S3), falling back to failing job names. | Planned |
| CIPR-R-016 | `pre-push-changed.sh` checks the PR for the `ci-loop` label. **Fail-open:** if `gh` is missing, unauthenticated or no open PR matches the branch, it warns and continues. **Block** only when the label is found: exit `4` (distinct from exit `3`, already used by `babysit_pr_reviews.js` for Copilot unavailable and by execute-plan `tick` / `init`), unless run with `--ci-loop-override "<reason>"`; the reason is echoed for the PR body. | Planned |

### Acceptance criteria

| ID | Given / when / then |
|----|---------------------|
| CIPR-AC-010 | Replaying the `tech-debt-reliability-8640-dev` run history from a **committed fixture** captured from this window (not live API calls, so the test cannot rot): the detector labels the PR no later than red push 5 (instead of 46). |
| CIPR-AC-011 | Replaying `care-status-model-p6`: labelled at push 3 or 5 depending on signatures; never later than push 5. |
| CIPR-AC-012 | A cancelled run between two red runs does not reset or advance the streak. |
| CIPR-AC-013 | A green run removes `ci-loop` and edits the marker comment to "resolved". |
| CIPR-AC-014 | After R-010, no skill under `.cursor/skills/` and no rule under `.cursor/rules/` states its own numeric CI push or retry budget; each links to `autonomous-pr-policy.md` §CI retry budget. Checked by a governance test that searches for push / retry / loop counts outside that section. |

**Expected effect (from data):** halting the 3 worst branches at push ≤ 5 removes up to ~60 of the 118
failures (51%). Upper bound: pushes after the halt (once the fix is found locally) can still fail. It does **not** by itself make the failing test pass. The time saved comes from local
iterations (one spec in 2–6 min with a trace, versus 8–10 min CI round trips that show one failure
each).

**Escalation:** CIPR-R-015 adds a workflow. It is non-blocking, but needs owner sign-off under §Escalation.

## 5. S3 — PR E2E diagnostics (gate strength unchanged)

**Problem:** `--max-failures=1` shows one failing test per run, and a red E2E leg doesn't say whether
the failure is deterministic or flaky. Agents spend one CI round trip per defect and cannot classify
without reproducing.

### Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| CIPR-R-020 | PR legs (`test_suite == specs`) use `--max-failures=3` instead of `1`. Extra time only on red runs: the rest of the selected specs run (already inside the ≤ 720 s per-leg selection budget) plus up to 2 more failing tests at the 90 s test timeout. Green runs are unchanged. | Planned |
| CIPR-R-021 | On failure, a following step reruns **only the failed tests** once (`npx playwright test --project=full --last-failed`). The job still fails whatever the rerun result. The job summary tags each failed test `deterministic` (failed twice) or `flaky-suspect` (passed on rerun). | Planned |
| CIPR-R-022 | Add a JSON reporter (`playwright-report/results.json`) alongside `list` and `html`. It is uploaded in the existing report artifact and is the machine-readable input for CIPR-R-015 signatures and the S4 ledger. | Planned |
| CIPR-R-023 | `ci-canary` (`@smoke-ci`) keeps `retries: 0` and `--max-failures` unchanged. | Planned |
| CIPR-R-024 | No automatic retries on the `full` project (`retries` stays `0`). See decision CIPR-D-003. | Planned |
| CIPR-R-025 | Out of scope, unchanged: `e2e/scripts/run-ci-shard.mjs` (Pre-UAT shards) and `run-org-e2e.mjs` (org journey) keep `--max-failures=1`. They run after merge, not in the PR iteration loop. | Planned |
| CIPR-R-026 | The job summary states that `deterministic` / `flaky-suspect` tags are diagnostics only; a `flaky-suspect` result never counts toward merge readiness. | Planned |

### Acceptance criteria

| ID | Given / when / then |
|----|---------------------|
| CIPR-AC-020 | Given 2 deterministic failing tests in one leg, the job runs both and the summary lists both as `deterministic`; `ci-gate` is red. |
| CIPR-AC-021 | Given a test that fails then passes on rerun, `ci-gate` is still red and the summary shows `flaky-suspect`. |
| CIPR-AC-022 | Given an all-green leg, wall time is within ±5% of baseline. |
| CIPR-AC-023 | `results.json` is in the artifact and lists test id, status and error message for every executed test. |
| CIPR-AC-024 | Before owner approval, a trial PR on the heaviest affected-spec leg with 3 forced failures shows the red-leg wall time; the owner approves on that number. |

**Escalation:** changes `_reusable-e2e-local.yml`, a `ci-gate` dependency → owner sign-off.

## 6. S4 — Flutter-web E2E stabilisation (evidence first)

**Problem:** the long streaks sit on Flutter-web E2E helpers that wait up to 30–45 s and time out:
`PeoplePage.expectLoaded` / `expectPhoneVisible` (`e2e/playwright/pages/people.page.ts`),
`AwayPlanningPage.pickAddPetCandidate` (`pages/away-planning.page.ts:890`) and
`CareItemPage.expectCareDetailsScreenTitle` (`pages/care-item.page.ts:41`). Only 4 logs were read, so
the full failure population is unknown.

### Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| CIPR-R-030 | **Ledger first.** Build a failure ledger of E2E failures on PR CI and Pre-UAT for the last 14 days (from `results.json` once S3 lands; from the HTML report artifacts before that): test id × error signature × helper × classification × fixing PR. Tracked as one `tech-debt` issue, not a new doc. | Planned |
| CIPR-R-031 | Classify each signature with ≥ 2 occurrences per `protocols/e2e.md` §1 **before** any test edit. Known so far: vet route mismatch = TEST BUG vs navigation contract (#2114); vet empty phone = RACE / product a11y (#2123); away-plan picker and care-details title = UNKNOWN. | Planned |
| CIPR-R-032 | Fix the top signatures by root cause, one PR each (`atomic-pr-policy.md`). Fixes that only lengthen a timeout, add sleeps or add `force: true` are rejected unless the evidence shows them correct (protocol §3). | Planned |
| CIPR-R-033 | Helper rule, report-only first: no inner `toBeVisible({ timeout: T })` inside `expect(...).toPass({ timeout: U })` with `U < 2T`. That pattern allows at most one effective attempt (e.g. 30 s inside 45 s in `pickAddPetCandidate`). Checker: `e2e/scripts/check_nested_waits.mjs`; it becomes blocking once the baseline reaches zero. | Planned |
| CIPR-R-034 | Post-action navigation helpers assert the destination from `docs/e2e/navigation-contract.md` (e.g. People edit save → detail, not list). A contract change updates the doc and the helper in the same PR. | Planned |
| CIPR-R-035 | Stability bar for any PR that edits a spec or page object: run the changed specs locally with `--repeat-each=5` against the localhost stack, with the result in the PR body. | Planned |

### Acceptance criteria

| ID | Given / when / then |
|----|---------------------|
| CIPR-AC-030 | The ledger exists. Before S3 it is built from HTML report artifacts and records its own coverage; after S3 (`results.json`) it covers ≥ 90% of E2E failures in the window. |
| CIPR-AC-031 | Each of the top 3 signatures has a classification and a fixing PR, or a debt issue with evidence. |
| CIPR-AC-032 | Each fixed signature: 0 recurrences across PR CI and Pre-UAT for 14 days after merge, and `--repeat-each=20` passes locally. |
| CIPR-AC-033 | `check_nested_waits.mjs` baseline count is recorded and shrinks only. |

## 7. Double-check against data and intent

This section rechecks each spec against the run data (not just the first-pass analysis) and against
the goal in §2.

### 7.1 Corrections to the first-pass analysis

| # | First-pass claim | Rechecked fact | Effect on specs |
|---|------------------|----------------|-----------------|
| 1 | "BDD priority tags and docs validation are in `pre-push-changed.sh`" | Priority tags are only in `pre-push.sh`; docs validation runs non-strict locally | S1 gains CIPR-R-002 / R-003 and a parity test (R-005) |
| 2 | Format failed in "10 of 20 sampled" runs | Full census: in 12 of 25 first failures; the only failure in 4 | S1 priority confirmed |
| 3 | Long streaks look like flaky tests | The vet streak was real defects found one per run (#2114 test + workarounds, #2123 product fix and revert) | S3 drops automatic retries (R-024) and adds diagnostics instead |
| 4 | "No escalation rule stopped the loop" | Light-plan already stops at 3 red pushes; policy says 5 / 3 | S2 is about one definition plus enforcement, not a new rule |

### 7.2 Coverage of observed failures

| Spec | Failures in window it addresses | What it does **not** fix |
|------|---------------------------------|--------------------------|
| S1 | Up to 12 / 25 first-push failures (cheap only); format present in 12, the sole cause in 4 | Branches where the script isn't run (needs S2 / evidence line) |
| S2 | Caps the 3 streaks at ≤ 5 → removes up to ~60 / 118 failures (upper bound) | Does not make a failing test pass; post-halt pushes can still fail |
| S3 | Cuts round trips per defect (vet: ≥ 2 defects surfaced one per run) | Needs owner sign-off; does not reduce defect count |
| S4 | Root causes behind the streaks | Slow (evidence first); success measured over 14 days |

### 7.3 Gaps not covered by the four specs

- **Shared-base breakage** (6 / 25 first failures, all on the `care-status-model` line, one waited
  35 h). None of S1–S4 address it. Candidate follow-up: check the integration branch is green before
  fanning out phase PRs. Not specified here.
- **Cancelled runs** (70 / 300, 23%) are superseded pushes, not failures. S2's one-push-per-batch
  helps a little.
- **Evidence limits:** 33 of 118 failed runs inspected at job level; 4 Playwright logs read. S4 starts
  with a ledger for this reason.

### 7.4 Intent check

- **Fewer red gates:** S1 (first push) and S2 (streak cap) carry most of it — together up to ~71 of
  118 observed failures (~60%; 12 + 59, no overlap since the 12 cheap-only branches exclude the worst 3).
- **Less time stuck red:** S2 moves the loop off CI; S3 shows every failing test and classifies each.
  S4 removes the causes.
- **No weakening of the gate:** none of S1–S4 removes a required check, adds retries or lowers a
  threshold. S3 keeps `ci-gate` red on any failure.

## 8. Delivery order

| # | PR | Depends on | Escalation |
|---|----|------------|------------|
| 1 | S1 parity (R-001…R-008) + KPI extension | — | No |
| 2 | S2 policy unification (R-010…R-013) — docs and skills only, can land **in parallel** with 1 | — | No |
| 3 | S2 local repro path (R-014) — touches `pre-push-changed.sh`, so after 1 | 1 | No |
| 4 | S3 diagnostics (R-020…R-026) | — | **Yes** — CI workflow |
| 5 | S2 detector workflow + label check (R-015, R-016) | 3, 4 (JSON signatures) | **Yes** — new workflow |
| 6 | S4 ledger + nested-wait checker (R-030, R-033) | 4 for full fidelity | No |
| 7+ | S4 one PR per signature (R-031, R-032, R-034) | 6 | No |

No row combines S1 with S3 or S4: escalation boundaries and one outcome per PR stay clean.

Measurement (CIPR-M1…M5): **extend** `scripts/quality/ci-health-kpis.mjs` (already weekly in
`quality-kpis.yml`; TEST programme phase 4, #1468) with first-run-green, cheap-only first failure and
streak metrics — no second report. Lands with row 1. Recheck after 2 weeks with the §1 method (last 300
`CI` runs, `pull_request`) for comparability, alongside the rolling 14-day view.

## Decisions

| ID | Decision | Rationale | Status | Date |
|----|----------|-----------|--------|------|
| CIPR-D-001 | Local parity is enforced by the governance registry test, not by convention | Format and BDD tags drifted out of `pre-push-changed.sh` unnoticed | **Delivered** (S1) | 2026-11-08 |
| CIPR-D-002 | One CI retry budget, defined once, enforced by label | Three conflicting statements; light-plan rule ignored over 46 pushes | Proposed | 2026-11-08 |
| CIPR-D-003 | No automatic Playwright retries on PR legs; diagnostic rerun only | Vet streak was real defects; retries would hide signal; protocol §3 | Proposed | 2026-11-08 |
| CIPR-D-004 | E2E stabilisation starts from a ledger, not helper rewrites | Only 4 logs inspected; classification-first is mandatory | Proposed | 2026-11-08 |
| CIPR-D-005 | Reuse `governance-blocking-steps.mjs` and `ci-health-kpis.mjs` instead of new manifests or reports | A third gate list or second KPI job would drift; both registries already have tests and consumers | Proposed | 2026-11-08 |
| CIPR-D-006 | No git `pre-push` hook for now | Cursor Cloud pushes go through the Cursor GitHub App; parity + registry test + evidence line suffice | Proposed | 2026-11-08 |

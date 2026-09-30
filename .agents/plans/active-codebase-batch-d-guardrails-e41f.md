---
title: Active codebase Batch D — Guardrails
owner: Agent
audience: agent
status: proposed
last_updated: 2026-09-29
---

# active-codebase-batch-d-guardrails-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-batch-d-guardrails-e41f` |
| **roadmap** | [`active-codebase-completion-e41f`](./active-codebase-completion-e41f.md) |
| **base_branch** | `cursor/active-codebase-d-integration-e41f` |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Make the programme's real status visible, and stop architecture regressions **before** further refactoring. Stale docs are fixed, a block-new cross-feature import gate lands (D6), `server/lib`/`server/services` size reporting starts in report-only mode (D7), and the Flutter coverage threshold becomes a single consistent number (D23). This batch makes no runtime behaviour changes.

## Autonomy (filled at bootstrap)

| Field | Value |
|-------|-------|
| **approved_by** | standing grant — roadmap `active-codebase-completion-e41f` |
| **approved_at / approved_until** | set at bootstrap (+48h) |
| **control_issue** | set at bootstrap |

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 4
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/arch-d-g-handover-26ff
  plan_path: .agents/plans/active-codebase-batch-d-guardrails-e41f.md
  plan_commit: ce702c0927134416858a5aa7cac17f45d7795289
  snapshot_path: .agents/plans/active-codebase-batch-d-guardrails-e41f.snapshot.json
  snapshot_commit: ce702c0927134416858a5aa7cac17f45d7795289
open_prs: []
merge_commits: {"1":"6f7a59b600ca8ce906929f21fea8c7415b56d3a7","2":"0232029e517e40487a89ca63932ef550019b36bc","3":"d7a77fde92cef5ea4fc711e6eec19903fc3b849e","4":"ce702c0927134416858a5aa7cac17f45d7795289"}
debt_issue_refs: []
```

## Phases

### Phase 1 — Programme status and baseline refresh

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/active-codebase-d1-status-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-d-guardrails-e41f.*
.agents/plans/active-codebase-completion-e41f.*
docs/architecture/reviews/active-codebase-review.md
docs/architecture/index.md
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
server/**
flutter_app/**
e2e/**
.github/workflows/**
```

**allowed_exceptions:**

```
docs
```

**Scope:**

- Add an **Implementation status** section to the review doc: one row per package (1–12) giving status (Done / Partial / Not started), merged PRs, open items, and the owning child plan from the roadmap. Note that the copy on `replit/preuat-adoption-pets-e7d3d1d` is historical.
- Record Package 2 as done: frozen org-transfer and family-event writes return JSON 404 when `ENABLE_FROZEN_DOMAINS` is off (`server/lib/frozenDomains.js`), which is equivalent to not being mounted for clients.
- Refresh the baseline README command matrix to current behaviour (A2 runtime rejection; weight completion transaction owner; `files_removed` semantics; account erasure still synchronous).
- Regenerate `metrics-headline.md` and `baseline-metadata.json` at the phase base commit; add a metrics history table.

**Acceptance criteria:**

- [ ] **D.1-1** The review doc has an Implementation status table covering Packages 1–12. Every row gives status, PR links, open items and the owning child `plan_id`. No row says Done while the roadmap traceability matrix lists open items for that package.
- [ ] **D.1-2** Every command-matrix row in the baseline README names the current code path and test file. No row says "fix in A2/B/C" for work that has already merged.
- [ ] **D.1-3** `metrics-headline.md` is regenerated with the documented command; `baseline-metadata.json` records the commit SHA used. A history table shows unique edges / directives / SCC feature count for `a8c7db1` (50 / 466 / 12) and the new SHA (at least 59 / 536 / 13).
- [ ] **D.1-4** `bash scripts/validate_docs.sh` and `node scripts/check_doc_placement.js` green; the diff contains no runtime file.

---

### Phase 2 — Cross-feature import gate (D6 block-new)

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/active-codebase-d2-import-gate-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-d-guardrails-e41f.*
scripts/check_feature_imports.js
scripts/check_feature_imports.test.js
scripts/feature-import-baseline.json
scripts/test/fixtures/feature-imports/**
scripts/pre-push.sh
scripts/pre-push-changed.sh
.github/workflows/_reusable-test.yml
docs/architecture/modularity.md
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
server/**
flutter_app/lib/**
flutter_app/test/**
e2e/**
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:**

- Add a Node checker, `scripts/check_feature_imports.js`, that scans `flutter_app/lib`. It excludes generated files (`.g.dart`, `.freezed.dart`, `.mocks.dart`, `l10n/`) and frozen roots read from `docs/engineering/frozen-domains/manifest.json`. It resolves `package:<pubspec name>/…` and relative `import`/`export`/`part` directives.
- Rules, each producing stable identities of the form `rule|importer|target`:
  - **R1 `domain-to-experience`**: any feature other than `experience` imports `features/experience/**` (D5).
  - **R2 `cross-feature-data`**: a feature imports another feature's `data/**`.
  - **R3 `cross-feature-presentation`**: a feature imports another feature's `presentation/**`. Exempt: the D5 composition entrypoints `lib/features/experience/**` and `lib/core/router/**`.
  - **R4 `new-feature-edge`**: a `from → to` feature edge that is not in the baseline edge set.
  - **SCC report**: print the feature-level strongly connected components (informational until I2 adds R5).
- The baseline file `scripts/feature-import-baseline.json` stores the base SHA, the identity list and the edge list. `--update-baseline` may **only remove** identities. Adding one requires `--accept-new "<reason>"`, which records the reason and date; it is used only for human-approved exceptions.
- Wire the checker into `scripts/pre-push.sh`, `scripts/pre-push-changed.sh` (when `flutter_app/lib/**` changes) and the CI governance job as a **blocking** step, plus a `node --test scripts/check_feature_imports.test.js` step (D9b).

**Acceptance criteria:**

- [ ] **D.2-1** `node scripts/check_feature_imports.js` exits 0 on the phase head. The baseline was generated at the phase base SHA and contains identities, not just counts.
- [ ] **D.2-2** Fixture tests (`node --test scripts/check_feature_imports.test.js`) prove that each of R1–R4 fails on a deliberate violation, and that removing one baselined violation while adding a **different** one still fails, because comparison is by identity rather than by count. `package:`, relative, `export` and `part` directives are all detected; frozen roots and generated files are ignored.
- [ ] **D.2-3** Stale baseline entries (violations no longer present) fail the check with a message telling the author to run `--update-baseline`, so the baseline ratchets down in the same PR that fixes a violation.
- [ ] **D.2-4** The checker runs in `pre-push.sh`, `pre-push-changed.sh` and the CI governance job as blocking steps. `node --test scripts/ci/assert-ci-gate.test.js` is updated and passes if it enumerates governance steps.
- [ ] **D.2-5** `docs/architecture/modularity.md` documents the rules, the D5 composition entrypoints, how to update the baseline, and the rule that the baseline may only shrink without a recorded, human-approved exception.
- [ ] **D.2-6** The initial R1/R2/R3 counts and edge count are recorded in the baseline README and the PR body.

---

### Phase 3 — Server size report (D7) and coverage threshold consistency (D23)

| Field | Value |
|-------|-------|
| **id** | `3` |
| **branch** | `cursor/active-codebase-d3-size-coverage-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
.agents/plans/active-codebase-batch-d-guardrails-e41f.*
scripts/check_file_size.js
scripts/check_file_size.test.js
scripts/check_coverage_threshold_consistency.test.js
scripts/test/fixtures/file-size/**
.github/workflows/_reusable-test.yml
CONTRIBUTING.md
docs/engineering/active-codebase-baseline/**
```

**forbidden_paths:**

```
server/**
flutter_app/lib/**
e2e/**
scripts/file-size-allowlist.json
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:**

- `check_file_size.js` also scans `server/lib` and `server/services` in **report-only** mode (D7). It lists files over 500 lines under a "Report-only (D7)" heading and never changes the exit code for them.
- Publish `docs/engineering/active-codebase-baseline/size-report.md` with every report-only offender, marked frozen or active, plus owner, reason, review date (≤ 90 days) and planned action (for example: split in K.1, or frozen: leave).
- Align the Flutter domain coverage threshold (D23 = 70%) across `CONTRIBUTING.md`, `flutter_app/scripts/run_tests_ci.sh`, `flutter_app/scripts/merge_flutter_coverage.sh` and the `check_domain_coverage.js` default. Only the doc should need to change today; add a consistency test.
- Add CI governance steps for the two new `node --test` files (D9b).

**Acceptance criteria:**

- [ ] **D.3-1** A fixture test proves that a 501-line file under `server/routes` still **fails**, while a 501-line file under `server/lib` passes and appears in the report-only section.
- [ ] **D.3-2** `size-report.md` lists every current report-only offender. Today these are `server/lib/orgPeople.js` (538), `server/lib/orgPermissions.js` (523) and `server/lib/care/schedule/projectSchedule.js` (502), each with frozen/active classification, owner, reason, review date and action.
- [ ] **D.3-3** `node --test scripts/check_coverage_threshold_consistency.test.js` passes, asserting that all four locations state the same threshold (70).
- [ ] **D.3-4** `scripts/file-size-allowlist.json` is unchanged and no existing size check is loosened.

---

### Phase 4 — Integration → main + pre-UAT

| Field | Value |
|-------|-------|
| **id** | `4` |
| **branch** | `cursor/active-codebase-d-integration-e41f` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |

**allowed_paths:**

```
**
```

**forbidden_paths:**

```
.github/workflows/deploy-*.yml
```

**allowed_exceptions:**

```
tests
docs
```

**Scope:** open one PR from `cursor/active-codebase-d-integration-e41f` into `main`; coordinator runs `./scripts/pre-push.sh`; `/babysit-uat` to merge; watch pre-UAT on the merge SHA; `complete-plan`; `roadmap-set-child … --status merged`.

**Acceptance criteria:**

- [ ] **D.4-1** Phases 1–3 are `merged` into the integration branch, and the integration → `main` PR is merged by `/babysit-uat`.
- [ ] **D.4-2** Pre-UAT E2E is green on the merge SHA (`./scripts/babysit_uat_watch_preuat.sh <sha> --timeout-min 90`).
- [ ] **D.4-3** `complete-plan` has run and the roadmap child status is `merged`, with the PR URL and merge commit recorded.

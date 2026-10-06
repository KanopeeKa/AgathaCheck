---
title: Documentation CI gates (canonical enforcement)
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-06
tags: [documentation, ci, execute-plan]
---

# Plan — docs-ci-gates-a496

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `docs-ci-gates-a496` |
| **title** | Documentation CI gates — warn rollout then blocking enforcement |
| **author** | Cloud agent (Cursor) |
| **created** | 2026-10-06 |
| **base_branch** | `cursor/docs-ci-gates-a496-integration-a496` (final PR integration → `main`) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Ship machine-checkable documentation governance aligned with merged #1703/#1709: PR `## Docs` declaration, `changes/` lifecycle, canonical doc shape, append-only IDs, and acceptance-criteria trace to BDD/tests. Phase 1 delivers the checker, baseline, workflows (including weekly hygiene), and **warn-only** CI. Phase 2 flips checks to **blocking** after one observation week (operator still marks required checks on `main`).

**Spec (in-delivery):** `docs/domains/documentation/changes/docs-ci-gates.md` → folds into `docs/domains/documentation/standards.md` §Enforcement when complete.

## Canonical docs

| Path | Phase |
|------|-------|
| `docs/domains/documentation/standards.md` | 1 (Enforcement + conventions); fold change doc on plan complete |
| `docs/domains/documentation/feature-template.md` | 1 (Coverage wire formats) |
| `.cursor/skills/canonical-docs/SKILL.md` | 1 (`## Docs`, validate, troubleshooting rule IDs) |

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | (snapshot) |
| **approved_until** | `approved_at + 48h` |
| **control_issue** | (snapshot) |
| **grant** | User chat 2026-10-06 — create plan and `/execute-plan` on docs CI gates v2 |

---

## Acceptance criteria (plan-level)

These are the verifiable outcomes for the **whole programme**. Phase exit criteria reference subsets. Implementation tests live in `scripts/check_docs_canonical.test.js` and workflow actionlint.

### A. PR body — Gate A (`--pr-body`)

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| A-1 | Given a PR diff touches `server/routes/foo.js` and the body has no `## Docs` heading, when Gate A runs in `block` mode, then the job fails with **R-A1** and the documented fix message. | `test: scripts/check_docs_canonical.test.js` (R-A1) |
| A-2 | Given `## Docs` contains `N/A — refactor, no contract change` (reason ≥10 chars after `N/A —`), when Gate A runs, then it passes. | test R-A2 pass |
| A-3 | Given `## Docs` lists `docs/domains/pet_care/features/care-item-evolution.md` but that path is not in the diff, when Gate A runs in `block` mode, then **R-A3** fails. | test R-A3 |
| A-4 | Given multiple canonical paths listed under `## Docs` (bullets or commas) and each path is modified in the diff, when Gate A runs, then it passes. | test multi-doc |
| A-5 | Given the diff deletes a `changes/` file whose base `folds_into` target is not modified, when Gate A runs, then **R-A4** fails. | test R-A4 |
| A-5b | Given a legacy `changes/` file with no `folds_into` is deleted and some `docs/domains/<same-domain>/features/*.md` is modified in the same PR, when Gate A runs, then deletion is allowed (**R-A4b**). | test R-A4b |
| A-6 | Given a PR only changes `flutter_app/test/**` or `e2e/**` or `scripts/**` (no behaviour paths), when Gate A runs, then **R-A1** does not apply (no `## Docs` required). | test behaviour exclusions |
| A-7 | Given author `renovate[bot]` or `dependabot[bot]` or `github-actions[bot]`, when Gate A runs, then exemptions apply. | test exemptions |
| A-8 | Given behaviour paths change, `## Docs` says N/A, and `.arb` or `server/migrations/**` changes, when Gate A runs, then **R-A5** warns. | test R-A5 |
| A-9 | Given a behaviour PR modifies a canonical feature doc but `## Docs` says N/A, when Gate A runs, then **R-A6** warns (new rule). | test R-A6 |
| A-10 | Given `pull_request` event type `edited` on the PR body, when the workflow runs, then Gate A re-evaluates (workflow `types` includes `edited`). | actionlint + manual |
| A-11 | Given `DOCS_GATE_MODE=warn`, when any BLOCK rule would fire, then the job annotates, exits 0. | test mode |
| A-12 | Given `node scripts/check_docs_canonical.js --pr-body --body-file /tmp/body.md` with env diff SHAs, when run locally, then output matches CI Gate A. | test CLI |

**Behaviour paths (normative):** `flutter_app/lib/**` (excl. `*.g.dart`, `*.mocks.dart`, `*.freezed.dart`), `flutter_app/lib/l10n/*.arb`, `server/routes/**`, `server/lib/**`, `server/migrations/**`, `server/bin/**`. **Excluded from behaviour:** `flutter_app/test/**`, `e2e/**`, `scripts/**`.

### B. Change docs — Gate B (`--changes`)

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| B-1 | Given a new `changes/x.md` with `status: completed`, when Gate B runs on the diff, then **R-B1** blocks (in `block` mode). | test R-B1 |
| B-2 | Given an unmodified baseline `changes/` file with `status: frozen`, when Gate B runs on an unrelated PR, then no failure (P1). | test R-L4 + diff-scope |
| B-3 | Given new `changes/foo-decisions.md`, when Gate B runs, then **R-B4** blocks. | test R-B4 |
| B-4 | Given `status: in-delivery` without `plan` or invalid `status_since`, when modified, then **R-B3** blocks. | test R-B3 |
| B-5 | Given `status: proposed` and `status_since` 45 days ago (injected clock), when PR job runs, then **R-B5** warns only; scheduled job lists it in the tracking issue. | test R-B5 + scheduled fixture |
| B-6 | Given baseline `changes/**/archive/**` entries, when weekly job runs, then they are **not** listed in R-B5/B6 reports. | test archive exclude |

### C. Canonical shape — Gate C (`--shape`)

Headers match **main** template: `| ID | Rule | Status |`, `| Given / When / Then | Requirement | Coverage |`, decision log six columns.

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| C-1 | Given a new non-baseline feature doc missing `## Decision log`, when Gate C runs, then **R-C1** blocks. | test R-C1 |
| C-2 | Given a baseline feature doc missing sections, when untouched, then Gate C does not block (**R-L3**). | test R-L3 |
| C-3 | Given non-baseline doc with phase row `CSM-7` + `Shipped`, when Gate C runs, then **R-C6** blocks. | test R-C6 phase |
| C-4 | Given requirement row `| X-R-001 | … | In delivery |`, when scanned, then **R-C6** does not flag. | test R-C6 negative |
| C-5 | Given `feature_id: people_care_team` and ID `CARE-TEAM-R-001`, when Gate C runs, then **R-C3** blocks (prefix `PEOPLE-CARE-TEAM`). | test R-C3 |
| C-6 | Given a **modified** baseline feature doc with a phase/shipped table, when Gate C runs, then **R-C6** warns only (**R-C6-legacy**). | test R-C6 legacy warn |
| C-7 | Given decision `Status` not `Live` or `Superseded by <ID>`, when Gate C runs on non-baseline doc, then **R-C4** blocks. | test R-C4 |

**R-C6 fixtures (mandatory):** phase table positive; requirement `In delivery` negative; banned H2 `## Phasing`; amendment banner line — four cases in `scripts/test/fixtures/docs-canonical/`.

### D. ID stability — Gate D (`--ids`)

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| D-1 | Given a requirement row removed at HEAD, when Gate D runs, then **R-D1** blocks; `Retired` status instead passes. | test R-D1 |
| D-2 | Given decision row `Rationale` edited, when Gate D runs, then **R-D2** blocks; `Status` → `Superseded by X-D-004` only passes. | test R-D2 |
| D-3 | Given git rename with IDs preserved, when Gate D runs, then **R-D4** suppresses false **R-D1**. | test R-D4 |
| D-4 | Given duplicate requirement IDs already on `main` in two files, when an unrelated PR runs, then no block; weekly job reports duplicates (**R-D3-report**). | test + scheduled |

### E. AC trace — Gate E (`--trace`)

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| E-1 | Given new AC row `Coverage: TBD — consolidate`, when Gate E runs, then **R-T2** blocks. | test R-T2 |
| E-2 | Given legacy AC row unchanged with `TBD — consolidate`, when Gate E runs, then pass. | test R-T2 legacy |
| E-3 | Given `bdd: away_care_planning.feature#Wrong title`, when Gate E runs, then **R-T3** fails; exact title (whitespace/apostrophe normalised) passes; `@tag` form passes when tag exists. | test R-T3 |
| E-4 | Given `test: path/to/file_test.dart#exact test name`, when the name matches exactly (Dart `test(` / Jest `it(`), then pass; partial substring does not pass. | test R-T3 test |
| E-5 | Given `none — #42` on closed issue, when **scheduled** job runs, then **R-T4** warns in tracking issue only. | scheduled test |
| E-6 | Given `--report` on repo HEAD, when job runs after BDD coverage script, then per-domain table appears in step summary and `--json` is valid for KPI workflow. | test report |

### F. Baseline and wiring

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| F-1 | Given initial `scripts/docs-legacy-baseline.json` listing ~47 features + ~90 changes (incl. `archive/`), when PR 1 merges, then counts recorded in PR description match generator output. | manual + test |
| F-2 | Given PR adds a baseline entry, then **R-L1** blocks; stale path → **R-L2**. | test R-L1, R-L2 |
| F-3 | Given `bash scripts/validate_docs.sh` with `origin/main` fetched, when diff touches `docs/**`, then `pre-push-changed.sh` invokes canonical checker. | integration |
| F-4 | Given `.github/workflows/docs-gate.yml` on a scratch PR (route change, no `## Docs`), when `DOCS_GATE_MODE=warn`, then R-A1 appears in summary without failing the job. | dry run |
| F-5 | Given Phase 2 merged (`DOCS_GATE_MODE=block`), when same scratch PR would run, then job fails until `## Docs` fixed. | post-phase-2 manual |

### G. Policy alignment (docs)

| ID | Given / When / Then | Coverage |
|----|---------------------|----------|
| G-1 | Given implementation PR, when merged, then `standards.md` lists gate rule IDs; `Retired` requirement status documented; `related_prs` / `related_bdd` optional (WARN only). | review |
| G-2 | Given implementation PR, when merged, then skill step 1 uses `## Docs` + `N/A — reason`; troubleshooting maps rule IDs. | review |
| G-3 | Given plan **complete**, when Phase 2 merged, then `changes/docs-ci-gates.md` folded into `standards.md` and deleted (**R-A4** guard). | complete-plan checklist |

---

## Phases

### Phase 1 — Implement gates (warn mode + weekly hygiene)

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/docs-ci-gates-implement-a496` |
| **spawn_allowed** | `false` |
| **exit_checklist** | `default` |
| **docs_targets** | `standards.md`, `feature-template.md`, `canonical-docs/SKILL.md`, `changes/docs-ci-gates.md` (authoritative spec) |

**allowed_paths:**

```
docs/domains/documentation/**
.cursor/skills/canonical-docs/**
.github/workflows/docs-gate.yml
.github/workflows/docs-validation.yml
.github/workflows/quality-kpis.yml
.github/pull_request_template.md
scripts/check_docs_canonical.js
scripts/check_docs_canonical.test.js
scripts/lib/docs-canonical/**
scripts/test/fixtures/docs-canonical/**
scripts/docs-legacy-baseline.json
scripts/validate_docs.sh
scripts/pre-push-changed.sh
.agents/plans/docs-ci-gates-a496.*
```

**forbidden_paths:**

```
flutter_app/lib/**
server/routes/**
server/lib/**
```

**allowed_exceptions:** `docs`, `governance-allowlist`, `tests`

**Scope:**

- Land v2 spec at `docs/domains/documentation/changes/docs-ci-gates.md`
- `scripts/lib/docs-canonical/*` + thin `check_docs_canonical.js` (≤500 lines entry)
- Baseline JSON generated from current tree
- `docs-gate.yml` with `DOCS_GATE_MODE=warn`
- Weekly docs-hygiene job on `quality-kpis.yml` (tracking issue pattern)
- Policy/template/skill updates per spec §10
- PR template checkbox comment (CI reads section not box)

**Exit criteria:**

- [ ] All plan AC rows A-1–A-12, B-1–B-6, C-1–C-7, D-1–D-4, E-1–E-6, F-1–F-4 satisfied
- [ ] `node scripts/check_docs_canonical.test.js` green; `./scripts/pre-push-changed.sh` green on branch
- [ ] actionlint passes on new workflow
- [ ] PR merged to `main` via babysit-plus

### Phase 2 — Blocking mode

| Field | Value |
|-------|-------|
| **id** | `2` |
| **branch** | `cursor/docs-ci-gates-block-a496` |
| **docs_targets** | `standards.md` (rollout note), fold + delete `changes/docs-ci-gates.md` |

**allowed_paths:**

```
.github/workflows/docs-gate.yml
docs/domains/documentation/**
.agents/plans/docs-ci-gates-a496.*
```

**Scope:**

- Set `DOCS_GATE_MODE=block` (or equivalent) in workflow
- Fold spec into `standards.md` §Enforcement; delete `changes/docs-ci-gates.md`
- Document operator step: mark "Docs declaration" and "Docs canonical" required on `main`

**Exit criteria:**

- [ ] F-5 satisfied; G-3 satisfied
- [ ] Plan `complete-plan` run; control issue closed

---

## Sanity check

**proceed** — Two atomic PRs; no product behaviour change; CI workflow change explicitly granted in user request.

## Runtime state (agent-updated)

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: implement phase 1 on cursor/docs-ci-gates-implement-a496
artifact_ref:
  branch: cursor/docs-ci-gates-implement-a496
  plan_path: .agents/plans/docs-ci-gates-a496.md
  plan_commit: pending
  snapshot_path: .agents/plans/docs-ci-gates-a496.snapshot.json
  snapshot_commit: pending
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

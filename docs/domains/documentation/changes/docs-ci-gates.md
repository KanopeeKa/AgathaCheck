---
title: Documentation CI gates (v2)
owner: Documentation Team
audience: agent
status: in-delivery
last_updated: 2026-10-06
tags: [documentation, ci, governance]
---

# Documentation CI gates (v2)

`domain: documentation` · `feature_id: docs_ci_gates` · `plan: docs-ci-gates-a496` · `folds_into: docs/domains/documentation/standards.md` · `status_since: 2026-10-06`

Machine-checkable governance for PR `## Docs`, `changes/` lifecycle, canonical feature shape, append-only IDs, and acceptance-criteria trace. **Phase 1:** `DOCS_GATE_MODE=warn` (annotate, exit 0). **Phase 2:** `block` on `main` required checks.

**Checker:** `node scripts/check_docs_canonical.js` · **Baseline:** `scripts/docs-legacy-baseline.json` · **Tests:** `scripts/check_docs_canonical.test.js`

## Requirements

| ID | Rule | Status |
|----|------|--------|
| DOCS-CI-GATES-R-001 | Gate A (`--pr-body`) enforces `## Docs` on behaviour PRs per rules R-A1–R-A6 | In delivery |
| DOCS-CI-GATES-R-002 | Gate B (`--changes`) enforces `changes/` frontmatter and naming per R-B1–R-B5 | In delivery |
| DOCS-CI-GATES-R-003 | Gate C (`--shape`) enforces main template tables and R-C1–R-C6 on touched non-baseline docs | In delivery |
| DOCS-CI-GATES-R-004 | Gate D (`--ids`) enforces append-only requirement/decision rows per R-D1–R-D4 | In delivery |
| DOCS-CI-GATES-R-005 | Gate E (`--trace`) enforces coverage wire formats per R-T2–R-T4 | In delivery |
| DOCS-CI-GATES-R-006 | Legacy baseline entries skip shape blockers until modified (R-L3); modified baseline phase noise warns (R-C6-legacy) | In delivery |
| DOCS-CI-GATES-R-007 | Weekly hygiene job reports R-B5, R-D3-report, R-T4 via tracking issue `<!-- docs-hygiene -->` | In delivery |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given a behaviour PR without `## Docs`, when Gate A runs in block mode, then R-A1 fails with fix text | DOCS-CI-GATES-R-001 | test: scripts/check_docs_canonical.test.js#R-A1 blocks behaviour PR without ## Docs |
| Given `DOCS_GATE_MODE=warn`, when a BLOCK rule would fire, then the job annotates and exits 0 | DOCS-CI-GATES-R-001 | test: scripts/check_docs_canonical.test.js#DOCS_GATE_MODE=warn exits 0 on R-A1 |
| Given four R-C6 fixture docs, when Gate C runs, then phase/shipped, `## Phasing`, and amendment banner block; `In delivery` does not | DOCS-CI-GATES-R-003 | test: scripts/check_docs_canonical.test.js#R-C6 fixtures |
| Given `bash scripts/validate_docs.sh` after fetch, when docs change locally, then canonical checker runs (warn by default) | DOCS-CI-GATES-R-001 | none — #1728 |

## Behaviour paths (Gate A)

**In scope:** `flutter_app/lib/**` (excl. `*.g.dart`, `*.mocks.dart`, `*.freezed.dart`), `flutter_app/lib/l10n/*.arb`, `server/routes/**`, `server/lib/**`, `server/migrations/**`, `server/bin/**`.

**Excluded (no `## Docs` required):** `flutter_app/test/**`, `e2e/**`, `scripts/**`.

**Bots exempt:** `renovate[bot]`, `dependabot[bot]`, `github-actions[bot]`.

## Coverage wire formats (Gate E)

| Form | Example |
|------|---------|
| BDD scenario | `bdd: away_care_planning.feature#Scenario title` |
| BDD tag | `bdd: away_care_planning.feature@smoke` |
| Dart/Jest test | `test: flutter_app/test/foo_test.dart#exact test name` |
| Tracked debt | `none — #42` |

Legacy unchanged rows may keep `TBD — consolidate`.

## Rule index

| ID | Severity | Summary |
|----|----------|---------|
| R-A1 | BLOCK | Missing `## Docs` on behaviour PR |
| R-A2 | — | N/A with reason ≥10 chars passes |
| R-A3 | BLOCK | Listed canonical path not in diff |
| R-A4 | BLOCK | `changes/` delete without `folds_into` target updated |
| R-A4b | BLOCK | Legacy `changes/` delete without same-domain `features/*.md` edit |
| R-A5 | WARN | N/A docs with `.arb` or migrations |
| R-A6 | WARN | Canonical doc changed but N/A declared |
| R-B1 | BLOCK | New `changes/` with `status: completed` |
| R-B3 | BLOCK | `in-delivery` missing `plan` / `status_since` |
| R-B4 | BLOCK | New `*-decisions.md` under `changes/` |
| R-B5 | WARN | `proposed` older than 45 days |
| R-C1 | BLOCK | Missing `## Decision log` (non-baseline) |
| R-C3 | BLOCK | ID prefix ≠ `feature_id` |
| R-C4 | BLOCK | Decision status not `Live` or `Superseded by <ID>` |
| R-C6 | BLOCK | Delivery noise (phase/shipped, `## Phasing`, amendment banners) |
| R-C6-legacy | WARN | Baseline doc modified but still has delivery noise |
| R-D1 | BLOCK | Requirement/decision row removed |
| R-D2 | BLOCK | Decision rationale edited in place |
| R-D4 | — | Git rename suppresses false R-D1 |
| R-T2 | BLOCK | New/changed AC missing valid coverage |
| R-T3 | BLOCK | BDD/test reference not found or inexact |
| R-L1 | BLOCK | Ad-hoc baseline JSON growth |
| R-L2 | BLOCK | Stale baseline path removed incorrectly |
| R-L3 | — | Untouched baseline exempt from shape block |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| DOCS-CI-GATES-D-001 | Warn-first CI rollout | One observation week before blocking required checks | Live | 2026-10-06 | (phase 1) |
| DOCS-CI-GATES-D-002 | Baseline JSON lists all current feature + change paths | Grandfather legacy shape until touched | Live | 2026-10-06 | (phase 1) |
| DOCS-CI-GATES-D-003 | Requirement status `Retired` allowed instead of row delete | Preserves audit trail per standards | Live | 2026-10-06 | (phase 1) |

## Still open

- Phase 2: flip `DOCS_GATE_MODE=block` and fold this doc into `standards.md` §Enforcement.

## Related

| Kind | Link |
|------|------|
| Plan | `.agents/plans/docs-ci-gates-a496.md` |
| Policy | `docs/domains/documentation/standards.md` |
| Skill | `.cursor/skills/canonical-docs/SKILL.md` |

---
title: Documentation standards
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-07
tags: [documentation, standards, policy]
---

# Documentation standards

**Policy doc:** `feature_id: documentation-standards` (prefix `DOCUMENTATION-STANDARDS` for new IDs). **related_prs:** #1703.

## Two axes

| Axis | Location | Holds |
|------|----------|-------|
| **Product domain** | `docs/domains/<domain>/` | Features (canonical), changes (proposals / in-delivery), journeys |
| **Type / platform** | `docs/architecture/`, `docs/design/`, `docs/pipelines/`, etc. | Contracts, CI, design tokens |

## Canonical vs working docs

| Kind | Folder | Lifecycle |
|------|--------|-----------|
| **Feature requirement (canonical)** | `domains/<domain>/features/<capability>.md` | **Current state** only — not a history trail |
| **Proposal / delivery** | `domains/<domain>/changes/` | `status: proposed \| in-delivery` until folded into canonical doc |
| **Open debt** | `docs/debt/debt.md` | OPEN items only; close = remove row |
| **Historical** | `docs/archived/` or delete after link sweep | Never link from agent entry points |

`changes/` is a **historical name** — treat it as proposals and in-delivery work only.

On the PR that **fully** delivers the work: fold requirements, acceptance criteria, and decisions into the canonical doc, then delete the change doc (subject to the deletion guard in the skill). Git history and `related_prs` are the audit trail.

Standalone `*-decisions.md` under `features/` or `changes/` is **legacy**; do not create new ones. Migrate via `/canonical-docs consolidate`.

## Feature doc rules

1. **One file per capability** (not per sprint or PR).
2. **YAML frontmatter:** `title`, `domain`, `feature_id`, `status`, `related_prs` (advisory convenience — `git log --follow` is authoritative), `related_bdd` (recommended), `last_updated`.
3. **Decision log** lives in a `## Decision log` section **inside** the canonical doc — never a separate decisions-only file for new work. Append-only; superseded rows stay with `Superseded by <ID>`. Decision `Status`: `Live` or `Superseded by <ID>` (legacy `Agreed` → `Live` on consolidate).
4. **Requirements:** table or list with stable IDs and status on every row:
   - ID format: `<PREFIX>-R-###` where `PREFIX` = `feature_id` from frontmatter, uppercased, underscores → hyphens (e.g. `feature_id: care-item-evolution` → `CARE-ITEM-EVOLUTION-R-014`). IDs are stable for life; never reuse.
   - Status: `Live` | `In delivery` | `Planned` | `Retired`.
5. **Acceptance criteria:** Given/When/Then; each cites a requirement ID and BDD/test coverage (see skill for coverage scope on legacy rows).
6. **New decision IDs:** `<PREFIX>-D-###` using the same prefix rule. **Keep** existing IDs when consolidating (e.g. `D-CSM-019`).
7. **No delivery history** in canonical body (no phase/shipped tables, “amended on …” banners).
8. `related_prs` is advisory — append the PR number when convenient; `git log --follow` is the audit trail.
9. **No duplicate colour values** — link to `docs/design/tokens.md` and `docs/design/system.md`.
10. **`.agents/memory/`** may not be the sole source of a product rule — promote to the canonical doc when the rule changes.

**Policy-doc exception:** meta docs under `docs/domains/documentation/` and `docs/agent-efficiency/` follow the template where it applies (`related_prs`, decision log, `## Docs` on PRs) but do not need a Requirements row for every policy paragraph.

## Design canonical sources (Replit Operations Desk direction)

| Topic | Canonical file |
|-------|----------------|
| Full system spec | `docs/design/system.md` |
| Token tables / hex | `docs/design/tokens.md` only |
| True North (why) | `docs/design/true-north.md` |
| Visual principles | `docs/design/principles.md` — no hex |
| Copy / tone | `docs/design/copy-tone.md` |
| Terminology | `docs/design/terminology.md` |
| Re-skin procedure | `docs/design/skin-change-guide.md` |

## Placement rules

- No new loose files under `docs/*.md` except `CHANGELOG.md` and `README.md`.
- Redirect stubs: delete after in-repo link sweep (do not accumulate).
- `lessons.md`: extract durable rules into `features/`, then delete or move remainder to `changes/`.

## Enforcement

- **Procedure:** `.cursor/skills/canonical-docs/SKILL.md` (Mode A `sync` / Mode B `consolidate`).
- **Local:** `bash scripts/validate_docs.sh` — links, placement/manifest, plus `check_docs_canonical.js` (diff vs `origin/main`; `DOCS_GATE_MODE` defaults to `warn` locally).
- **CI (blocking):** `.github/workflows/docs-gate.yml` — jobs **Docs declaration** (Gate A) and **Docs canonical** (Gates B–E + trace report). `DOCS_GATE_MODE=block` in that workflow.
- **Weekly hygiene:** `quality-kpis.yml` job `docs-hygiene` — expired `changes/`, duplicate IDs, closed-issue `none — #n` rows; tracking issue marker `<!-- docs-hygiene -->`.
- **Legacy baseline:** `scripts/docs-legacy-baseline.json` — shrink-only; untouched paths skip Gate C (**R-L3**). Migrate with `/canonical-docs consolidate`.

### Gate A — PR `## Docs`

Behaviour paths (require `## Docs` unless exempt bot): `flutter_app/lib/**` (excl. `*.g.dart`, `*.mocks.dart`, `*.freezed.dart`), `flutter_app/lib/l10n/*.arb`, `server/routes/**`, `server/lib/**`, `server/migrations/**`, `server/bin/**`. **Excluded:** `flutter_app/test/**`, `e2e/**`, `scripts/**`.

Declare canonical path(s) updated or `N/A — <reason>` (≥10 characters after `N/A —`). Rules **R-A1**–**R-A6** (multi-doc list, `changes/` delete guard **R-A4** / legacy **R-A4b**).

### Gates B–E (diff-scoped)

| Gate | Mode | Rules (summary) |
|------|------|-----------------|
| B `changes/` | `--changes` | **R-B1**–**R-B5** — `proposed` \| `in-delivery` only; no new `*-decisions.md` |
| C shape | `--shape` | **R-C1**–**R-C6** — template tables; **R-C6-legacy** WARN on touched baseline docs |
| D IDs | `--ids` | **R-D1**–**R-D4** — append-only; use `Retired` not row delete |
| E trace | `--trace` | **R-T2**–**R-T4** — `bdd:` / `test:` / `none — #n` on new/changed AC rows |

**Coverage wire formats:** `bdd: file.feature#Scenario title` or `bdd: file.feature@tag`; `test: path#exact test name`; `none — #n`; legacy untouched rows may keep `TBD — consolidate`.

**Checker:** `node scripts/check_docs_canonical.js` · **Tests:** `scripts/check_docs_canonical.test.js` · Rule fix text: skill Troubleshooting.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| DOCUMENTATION-STANDARDS-D-001 | Decision logs live inside canonical feature docs | Single source of truth; append-only supersession | Live | 2026-10-06 | #1703 |
| DOCUMENTATION-STANDARDS-D-002 | Agent workflow enforces sync before PR open | Skill + pr-hygiene/babysit/execute-plan wiring; CI gates deferred | Superseded by DOCUMENTATION-STANDARDS-D-004 | 2026-10-06 | #1703 |
| DOCUMENTATION-STANDARDS-D-003 | Requirement/decision ID prefix from `feature_id` | One prefix per doc; uppercase kebab from YAML | Live | 2026-10-06 | #1703 |
| DOCUMENTATION-STANDARDS-D-004 | Documentation CI gates block on PR | `docs-gate.yml` Gates A–E; baseline shrink-only; plan docs-ci-gates-a496 | Live | 2026-10-07 | TBD |

## Still open

(none)

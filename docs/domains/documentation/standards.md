---
title: Documentation standards
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-10-06
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
2. **YAML frontmatter:** `title`, `domain`, `feature_id`, `status`, `related_prs` (optional — **R-A6** warns if behaviour PR omits doc sync), `related_bdd` (optional), `last_updated`.
3. **Decision log** lives in a `## Decision log` section **inside** the canonical doc — never a separate decisions-only file for new work. Append-only; superseded rows stay with `Superseded by <ID>`.
4. **Requirements:** table or list with stable IDs and status on every row:
   - ID format: `<PREFIX>-R-###` where `PREFIX` = `feature_id` from frontmatter, uppercased, underscores → hyphens (e.g. `feature_id: care-item-evolution` → `CARE-ITEM-EVOLUTION-R-014`). IDs are stable for life; never reuse.
   - Status: `Live` | `In delivery` | `Planned` | `Retired` (use `Retired` instead of deleting rows — gate **R-D1**).
5. **Acceptance criteria:** Given/When/Then; each cites a requirement ID and BDD/test coverage (see skill for coverage scope on legacy rows).
6. **New decision IDs:** `<PREFIX>-D-###` using the same prefix rule. **Keep** existing IDs when consolidating (e.g. `D-CSM-019`).
7. **No delivery history** in canonical body (no phase/shipped tables, “amended on …” banners).
8. On merge to `main`, append the PR number to `related_prs` when the feature doc changed.
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

- **Procedure:** `.cursor/skills/canonical-docs/SKILL.md` (Mode A `sync` / Mode B `consolidate`). This section links to it and does not repeat the steps.
- `bash scripts/validate_docs.sh` — links, frontmatter, placement/manifest gates, plus `node scripts/check_docs_canonical.js` (canonical gates).
- **CI:** `.github/workflows/docs-gate.yml` (warn mode: **R-A1**–**R-T4** — see `docs/domains/documentation/changes/docs-ci-gates.md`). Weekly hygiene: `quality-kpis.yml` job `docs-hygiene` (tracking issue marker `<!-- docs-hygiene -->`).
- Legacy domain docs: migrate **one capability at a time** with `/canonical-docs consolidate`; baseline paths in `scripts/docs-legacy-baseline.json` (**R-L3** exempt until touched).

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| DOCUMENTATION-STANDARDS-D-001 | Decision logs live inside canonical feature docs | Single source of truth; append-only supersession | Live | 2026-10-06 | #1703 |
| DOCUMENTATION-STANDARDS-D-002 | Agent workflow enforces sync before PR open | Skill + pr-hygiene/babysit/execute-plan wiring; CI gates deferred | Live | 2026-10-06 | #1703 |
| DOCUMENTATION-STANDARDS-D-003 | Requirement/decision ID prefix from `feature_id` | One prefix per doc; uppercase kebab from YAML | Live | 2026-10-06 | #1703 |

## Still open

(none)

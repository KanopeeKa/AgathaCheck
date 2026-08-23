---
title: Documentation standards
owner: Documentation Team
audience: agent
status: active
last_updated: 2026-08-23
tags: [documentation, standards, policy]
---

# Documentation standards

## Two axes

| Axis | Location | Holds |
|------|----------|-------|
| **Product domain** | `docs/domains/<domain>/` | Features (canonical), changes (delivery), journeys |
| **Type / platform** | `docs/architecture/`, `docs/design/`, `docs/pipelines/`, etc. | Contracts, CI, design tokens |

## Canonical vs working docs

| Kind | Folder | Lifecycle |
|------|--------|-----------|
| **Feature requirement** | `domains/<domain>/features/<feature>.md` | Evolves with product; always current truth |
| **Delivery / plan** | `domains/<domain>/changes/` or `design/plans/` | Archive or delete when merged; extract rules into features first |
| **Open debt** | `docs/debt/debt.md` | OPEN items only; close = remove row |
| **Historical** | `docs/archived/` or delete after link sweep | Never link from agent entry points |

## Feature doc rules

1. One file per capability (not per sprint).
2. YAML frontmatter: `title`, `domain`, `feature_id`, `status`, `related_prs`, `related_bdd`.
3. Body: behaviour, acceptance criteria, links to BDD — no sprint checklists.
4. On merge to `main`, append PR number to `related_prs` when the feature doc changed.
5. **No duplicate colour values** — link to `docs/design/tokens.md` and `docs/design/system.md`.

## Design canonical sources (Replit Operations Desk direction)

| Topic | Canonical file |
|-------|----------------|
| Full system spec | `docs/design/system.md` |
| Token tables / hex | `docs/design/tokens.md` only |
| Principles (why) | `docs/design/principles.md` — no hex |
| Copy / tone | `docs/design/copy-tone.md` |
| Re-skin procedure | `docs/design/skin-change-guide.md` |

## Placement rules

- No new loose files under `docs/*.md` except `CHANGELOG.md` and `README.md`.
- Redirect stubs: delete after in-repo link sweep (do not accumulate).
- `lessons.md`: extract durable rules into `features/`, then delete or move remainder to `changes/`.

## Enforcement

- `bash scripts/validate_docs.sh` — links, frontmatter
- Phase 9 of `docs-canonical-layout-63ad` adds placement and colour-duplicate gates in CI

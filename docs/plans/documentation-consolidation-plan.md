# Documentation Consolidation & Improvement Plan

*Comprehensive execution plan for Agatha Track documentation overhaul*
*Version: 1.0*
*Date: 2026-08-21*

---

## Executive Summary

**Objective**: Resolve disjointed documentation by consolidating redundant content, improving navigation, standardizing formatting, and establishing maintenance processes.

**Scope**: 126 markdown files across root, `docs/`, `.cursor/`, and `.agents/` directories.

**Strategy**: Execute in **3 phased PRs** to balance coherence with reviewability.

| PR | Phase | Focus | Files Changed | Risk |
|----|-------|-------|----------------|------|
| #1 | Foundation | Structure, navigation, metadata | ~100+ (headers) + 5 new | Low |
| #2 | Consolidation | Root-level docs, deduplication | ~10 major | Medium |
| #3 | Quality | Validation, cross-references, changelog | ~5 new + updates | Low |

---

## Phase Breakdown

---

### Phase 1: Foundation (PR #1)
**Goal**: Establish documentation structure and navigation backbone.

#### Deliverables

| # | Task | Files | Effort | Validation |
|---|------|-------|--------|------------|
| 1.1 | Create `docs/README.md` (master TOC) | +1 new | 1h | Manual review |
| 1.2 | Add metadata headers to all `docs/*.md` | ~82 updated | 30m (scripted) | Script test |
| 1.3 | Add metadata headers to root `.md` files | ~6 updated | 15m | Manual check |
| 1.4 | Create `docs/archived/` directory | +1 new | 5m | Directory exists |
| 1.5 | Create `docs/archived/README.md` | +1 new | 15m | Manual review |
| 1.6 | Archive superseded docs | ~3 moved | 30m | Link validation |
| 1.7 | Update cross-references to archived docs | ~20 updated | 1h | Link validation |

#### Files Created/Modified
- `docs/README.md` - Master table of contents
- `docs/archived/README.md` - Archived docs index
- `docs/archived/navigation-v2.md` - Moved from `docs/design/navigation-v2.md`
- `docs/archived/experience-split-plan.md` - Moved from `docs/experience-split-plan.md`
- `docs/archived/quality-review-2026-07-08.md` - Moved from `docs/quality/review-2026-07-08.md`
- All `.md` files in `docs/` - Added metadata headers
- All `.md` files in root - Added metadata headers
- All `.md` files in `e2e/` - Added metadata headers
- `.cursor/skills/ui-design-deep/SKILL.md` - Updated reference to archived doc

---

### Phase 2: Consolidation (PR #2)
**Goal**: Eliminate redundancy in root-level documentation.

#### Deliverables

| # | Task | Files | Effort | Validation |
|---|------|-------|--------|------------|
| 2.1 | Move `API.md` -> `docs/api-reference.md` | 1 moved + 1 updated | 30m | Link validation |
| 2.2 | Refactor `README.md` | 1 updated | 1h | Manual review |
| 2.3 | Refactor `AGENTS.md` | 1 updated | 1h | Manual review |
| 2.4 | Refactor `CONTRIBUTING.md` | 1 updated | 1h | Manual review |
| 2.5 | Update all cross-references | ~50 updated | 2h | Link validation |

#### Content Redistribution

**README.md** (Keep):
- Project overview (first paragraph)
- Architecture diagram
- Tech stack table
- Getting Started (frontend/backend)
- Features list
- License
- Documentation links section

**README.md** (Remove -> move elsewhere):
- Detailed modular structure -> `docs/architecture/modularity.md`
- Testing structure -> `docs/architecture/modularity.md`
- CI/CD table -> `docs/ci-cd-baseline.md`

**AGENTS.md** (Keep):
- Cursor Cloud specific instructions
- Toolchain setup
- PostgreSQL setup
- Running the backend
- Pre-push workflows
- Agent workflow shortcuts

**AGENTS.md** (Remove):
- Project description (link to README)
- Architecture overview (link to docs/architecture)
- Tech stack details (link to README)

**CONTRIBUTING.md** (Keep):
- Branch strategy
- Avoiding branch conflicts
- Pull request expectations
- E2E and UAT
- Debt and deferrals

**CONTRIBUTING.md** (Remove):
- Agent workflow (-> AGENTS.md)
- Detailed pre-push commands (keep reference to scripts)

---

### Phase 3: Quality (PR #3)
**Goal**: Improve maintainability and add automation.

#### Deliverables

| # | Task | Files | Effort | Validation |
|---|------|-------|--------|------------|
| 3.1 | Standardize all cross-references | ~100 updated | 2h | Script validation |
| 3.2 | Add `docs/CHANGELOG.md` | +1 new | 30m | Manual review |
| 3.3 | Create `scripts/validate_docs.sh` | +1 new | 1h | Test execution |
| 3.4 | Create `scripts/add_metadata_headers.sh` | +1 new | 1h | Test execution |

#### Cross-Reference Standardization Rules

1. Use absolute paths from repo root: `/docs/file.md`
2. Use consistent "Related" section format
3. Use `[description](path)` format consistently

#### Validation Script

`scripts/validate_docs.sh` will:
- Check for broken markdown links
- Verify metadata headers exist
- Detect potential duplicate content
- Run as part of pre-push checks

---

## File Change Summary

| Category | PR 1 | PR 2 | PR 3 | Total |
|----------|------|------|------|-------|
| New files | 5 | 1 | 3 | 9 |
| Updated files | ~110 | ~60 | ~100 | ~270 |
| Moved files | 3 | 1 | 0 | 4 |
| Deleted files | 0 | 0 | 0 | 0 |

**Total lines changed**: ~3,000-4,000 (estimated)

---

## Timeline

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Phase 1 | 1 day | Immediate | Day 1 |
| Phase 2 | 1 day | Day 1 | Day 2 |
| Phase 3 | 1 day | Day 2 | Day 3 |
| **Total** | **3 days** | | |

---

## Success Criteria

| Criteria | Measurement |
|----------|-------------|
| Navigation improved | Time to find any doc <= 3 clicks from `docs/README.md` |
| Redundancy reduced | No duplicate content between README, AGENTS, CONTRIBUTING |
| Links validated | `validate_docs.sh` passes with 0 errors |
| Maintenance enabled | Metadata headers on all docs, changelog updated |
| Agent compatibility | All agent workflows still functional |
| Human compatibility | All human workflows still functional |

---

## PR Templates

### PR #1: docs: Add foundation structure and metadata

```markdown
## Summary
- Add `docs/README.md` as master table of contents
- Add YAML metadata headers to all documentation files
- Create `docs/archived/` for superseded documentation
- Archive initial set of superseded docs

## Changes
- Added: `docs/README.md`, `docs/archived/README.md`
- Added: `docs/archived/navigation-v2.md`, `docs/archived/experience-split-plan.md`, `docs/archived/quality-review-2026-07-08.md`
- Updated: All files in `docs/**/*.md` (metadata headers)
- Updated: Root `.md` files (metadata headers)
- Updated: `e2e/*.md` files (metadata headers)
- Updated: `.cursor/skills/ui-design-deep/SKILL.md` (reference fix)

## Validation
- All links validated
- Metadata headers added to ~110 files
- Archived docs have deprecation notices
```

### PR #2: docs: Consolidate root-level documentation

```markdown
## Summary
- Move `API.md` to `docs/api-reference.md`
- Refactor `README.md` to focus on project overview
- Refactor `AGENTS.md` to focus on agent workflows
- Refactor `CONTRIBUTING.md` to focus on human workflows
- Update all cross-references

## Changes
- Moved: `API.md` -> `docs/api-reference.md`
- Updated: `README.md`, `AGENTS.md`, `CONTRIBUTING.md`
- Updated: ~50 files with new cross-references

## Validation
- All links validated
- No redundant content between root docs
- Agent workflows still functional
```

### PR #3: docs: Add quality checks and standardization

```markdown
## Summary
- Standardize all cross-references to use absolute paths
- Add `docs/CHANGELOG.md` for documentation changes
- Add `scripts/validate_docs.sh` for automated checks
- Add `scripts/add_metadata_headers.sh` for header management

## Changes
- Added: `docs/CHANGELOG.md`, `scripts/validate_docs.sh`, `scripts/add_metadata_headers.sh`
- Updated: ~100 files (standardized cross-references)

## Validation
- `validate_docs.sh` passes on all markdown files
- All links use consistent format
```

---

## Notes

This plan is a living document and may be updated as the execution progresses.

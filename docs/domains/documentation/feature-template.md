---
title: Feature requirement template
owner: Documentation Team
audience: both
status: active
last_updated: 2026-10-06
tags: [template, documentation]
---

# Feature requirement template

Copy to `docs/domains/<domain>/features/<capability>.md`.

**Frontmatter (required on real docs):** `title`, `domain`, `feature_id`, `status`, `related_prs`, `related_bdd`, `last_updated`.

Policy: `docs/domains/documentation/standards.md` · Procedure: `.cursor/skills/canonical-docs/SKILL.md`

# &lt;Feature title&gt;

## Summary / scope

- **Owns:** …
- **Does not own:** …
- **Depends on:** …

## Vocabulary

EN/FR terms — link `docs/design/terminology.md` and domain vocabulary docs when present.

## Requirements

| ID | Rule | Status |
|----|------|--------|
| EXAMPLE-R-001 | Example requirement text | Live |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
|---------------------|-------------|----------|
| Given … When … Then … | EXAMPLE-R-001 | `flutter_app/test/bdd/features/….feature` — Scenario: … |

## States & data

Summary plus links to schema, API, or architecture docs.

## UX surfaces

Screens, routes, or hubs where this capability appears.

## Out of scope

Explicit non-goals.

## Still open

Open questions; product conflicts (code vs spec) require a linked GitHub issue (see skill).

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
|----|----------|-----------|--------|------|-----|
| EXAMPLE-D-001 | Example decision | Why we chose this | Live | YYYY-MM-DD | #… |

## Related

| Kind | Link |
|------|------|
| BDD | `flutter_app/test/bdd/features/….feature` |
| Design | `docs/design/tokens.md`, `docs/design/system.md` |
| API | `docs/architecture/api-reference.md` |

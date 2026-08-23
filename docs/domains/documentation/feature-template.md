---
title: Feature requirement template
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [template, documentation]
---

# Feature requirement template

Copy this file when creating `domains/<domain>/features/<feature>.md`.

Optional frontmatter fields for real feature docs: `domain`, `feature_id`, `related_prs`, `related_bdd`.

# &lt;Feature title&gt;

## Summary

One paragraph: what this feature does for the user.

## Requirements

- [ ] Requirement 1
- [ ] Requirement 2

## Acceptance criteria

- Given … When … Then …

## Related

| Kind | Link |
|------|------|
| BDD | `flutter_app/test/bdd/features/….feature` |
| Design | `docs/design/tokens.md` (colours), `docs/design/system.md` (components) |
| API | `docs/architecture/api-reference.md` |

## Change history (PRs)

| PR | Summary |
|----|---------|
| #___ | Initial spec |

---
name: pre-push-verify
description: Run the correct pre-push verification before git push — changed-files subset during iteration, full suite before merge to main. Use when ready to push, before creating PR, or when CI failed locally.
---

# Pre-push verify

## Which script?

| Situation | Command |
|-----------|---------|
| **During agent iteration** (most pushes) | `./scripts/pre-push-changed.sh` |
| **Before integration→main PR** or single-agent merge | `./scripts/pre-push.sh` |
| **Unsure / touched many domains** | `./scripts/pre-push.sh` |

## Before any push

```bash
git fetch origin main
git rebase origin/main   # or rebase onto integration parent
```

## UI-touching changes (automatic reminder)

When `./scripts/pre-push-changed.sh` detects edits under `flutter_app/lib/features/*/presentation/**`, theme, or router files, it prints a **UI touch reminder**. Treat that as mandatory: run the **`/ui-check`** checklist before opening or updating the PR (read `.cursor/skills/ui-check/SKILL.md` §Steps). Escalate to **`/ui-design-deep`** for theme, landing/auth, or multi-screen work.

## Changed-files script logic

`pre-push-changed.sh` diffs vs `origin/main` and runs:

| Changed paths | Runs |
|---------------|------|
| `server/routes/**`, `server/test/**` | Targeted or full Jest |
| `server/lib/**` | Jest |
| `flutter_app/lib/features/<x>/**` | analyze + `test/features/<x>/` (domain-scoped) |
| `e2e/**` | BDD coverage + file size gates |
| `scripts/**`, `.github/**` | Governance gates |

**Local vs PR CI:** `pre-push-changed.sh` targets **feature domains** touched in the diff. PR CI currently runs **all Flutter test shards** whenever the Flutter stack runs — Phase F2 of `ci-test-depth-abc9` will align PR shards with changed domains.

## Full script includes

- `check_file_size.js`, `check_bdd_coverage.js`, `check_bdd_priority_tags.js`
- `npm audit --audit-level=high` + full Jest
- `build_runner`, `flutter analyze`, full `flutter test`
- `dart format` check (Flutter code only)

## CI is authoritative

Local changed-files run saves time; CI on PR to `main` runs the full reusable test workflow. Do not skip `./scripts/pre-push.sh` before final merge PR.

## Tool tip

When copying strings for edits, use the `read` tool — grep output may scramble tokens (see `.agents/memory/tool-output-token-scrambling.md`).

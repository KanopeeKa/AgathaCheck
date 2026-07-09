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

## Changed-files script logic

`pre-push-changed.sh` diffs vs `origin/main` and runs:

| Changed paths | Runs |
|---------------|------|
| `server/routes/**`, `server/test/**` | Targeted or full Jest |
| `server/lib/**` | Jest + `dart analyze lib` |
| `flutter_app/lib/features/<x>/**` | analyze + `test/features/<x>/` |
| `e2e/**` | BDD coverage + file size gates |
| `scripts/**`, `.github/**` | Governance gates |

## Full script includes

- `check_file_size.js`, `check_bdd_coverage.js`, `check_bdd_priority_tags.js`
- `npm audit --audit-level=high` + full Jest
- `build_runner`, `flutter analyze`, full `flutter test`
- `dart analyze lib`, `dart format` check

## CI is authoritative

Local changed-files run saves time; CI on PR to `main` runs the full reusable test workflow. Do not skip `./scripts/pre-push.sh` before final merge PR.

## Tool tip

When copying strings for edits, use the `read` tool — grep output may scramble tokens (see `.agents/memory/tool-output-token-scrambling.md`).

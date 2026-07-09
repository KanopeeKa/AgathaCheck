---
name: babysit
description: Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop.
---

# Babysit PR

Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. **Sync:** `git fetch origin main && git rebase origin/main` on your branch.
2. **Merge conflicts:** Intelligently resolve, preserving intent of both sides. If intents conflict, stop and ask.
3. **Comments:** Review active unresolved comments (including Bugbot). Filter resolved threads. Validate Bugbot findings — fix only valid issues; explain false positives.
4. **CI:** Fix failures caused by this PR's scope. Never weaken CI gates to pass. If failure seems unrelated, rebase on latest `main` first.
5. **Verify locally:** `./scripts/pre-push-changed.sh` for scoped fix; `./scripts/pre-push.sh` before final push when near merge.
6. **Push** scoped fixes and re-watch CI until mergeable + green + comments triaged.

Escalate to human when: security/crypto changes, breaking API contracts, migration risk, or product/legal decisions.

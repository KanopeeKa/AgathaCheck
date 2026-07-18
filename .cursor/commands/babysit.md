---
name: babysit
description: Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop.
---

# Babysit PR

Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. **Sync:** `git fetch origin main && git rebase origin/main` on your branch.
2. **Merge conflicts:** Intelligently resolve, preserving intent of both sides. If intents conflict, stop and ask.
3. **Ready for review:** If the PR is still a draft, mark it ready (`gh pr ready <url>`). Automatic reviewers (e.g. Copilot, Bugbot) only run after the PR is ready — not while draft.
4. **Wait for automatic reviews (mandatory):** After marking ready, poll until bot reviews land or the budget expires. Do **not** triage, merge, or declare done while reviews are still pending.
   - Fetch reviews: `gh api repos/{owner}/{repo}/pulls/{n}/reviews`
   - Fetch review comments: `gh api repos/{owner}/{repo}/pulls/{n}/comments`
   - Poll every 30–60s for up to **15 minutes** (reviews often arrive after CI is already green).
   - Treat Copilot / Bugbot / other configured bots as blocking until their review exists or the wait budget expires.
   - On timeout: comment on the PR listing pending reviewers and halt — do not skip review triage.
5. **Comments:** Review active unresolved threads from automatic and human reviews. Filter resolved threads. Validate Bugbot findings — fix only valid issues; explain false positives.
6. **CI:** Fix failures caused by this PR's scope. Never weaken CI gates to pass. If failure seems unrelated, rebase on latest `main` first.
7. **Verify locally:** `./scripts/pre-push-changed.sh` for scoped fix; `./scripts/pre-push.sh` before final push when near merge.
8. **Push** scoped fixes and re-watch CI until mergeable + green + comments triaged. After each push that changes the diff, return to step 4 if new automatic reviews are expected.

Escalate to human when: security/crypto changes, breaking API contracts, migration risk, or product/legal decisions.

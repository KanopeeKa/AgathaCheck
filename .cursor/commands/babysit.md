---
name: babysit
description: Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop.
---

# Babysit PR

Your job is to get this PR to a merge-ready state.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. **Sync (proactive):** Keep the PR branch on the latest base **without waiting for CI to fail**:
   ```bash
   ./scripts/babysit_sync_base.sh --pr <url> --push
   ```
   Uses the PR's base branch (`main` or integration parent). Re-run **before every push**, before entering the CI wait loop, and after long polls (automatic reviews). Manual equivalent: `BASE=$(gh pr view <url> --json baseRefName -q .baseRefName) && git fetch origin "$BASE" && git rebase "origin/$BASE"`.
2. **Merge conflicts:** Intelligently resolve, preserving intent of both sides. If intents conflict, stop and ask.
3. **Ready for review:** If the PR is still a draft, mark it ready (`gh pr ready <url>`). Automatic reviewers (e.g. Copilot, Bugbot) only run after the PR is ready — not while draft.
4. **Wait for automatic reviews (mandatory):** After marking ready, poll until bot reviews land or the budget expires. Do **not** triage, merge, or declare done while reviews are still pending.
   - Formal reviews: `gh api repos/{owner}/{repo}/pulls/{n}/reviews`
   - Review comments (inline): `gh api repos/{owner}/{repo}/pulls/{n}/comments`
   - PR conversation comments (bots may post here instead of a formal review): `gh api repos/{owner}/{repo}/issues/{n}/comments`
   - Poll every 30–60s for up to **15 minutes** (reviews often arrive after CI is already green).
   - Treat Copilot / Bugbot / other configured bots as blocking until their review exists or the wait budget expires.
   - On timeout: comment on the PR listing pending reviewers and halt — do not skip review triage.
5. **Comments:** Review active unresolved threads from automatic and human reviews. Filter resolved threads. Validate Bugbot findings — fix only valid issues; explain false positives.
6. **CI:** Fix failures caused by this PR's scope. Never weaken CI gates to pass. If failure seems unrelated, run `./scripts/babysit_sync_base.sh --pr <url> --push` first — do not wait for a red CI run to discover the branch is behind.
7. **Verify locally:** `./scripts/pre-push-changed.sh` for scoped fix; `./scripts/pre-push.sh` before final push when near merge.
8. **Push** scoped fixes and re-watch CI until mergeable + green + comments triaged. Run `./scripts/babysit_sync_base.sh --pr <url>` before each push. After each push that changes the diff, return to step 4 if new automatic reviews are expected.

**Babysit+ only (after merge to `main`):** enqueue UAT via `node scripts/uat_queue_runtime.js enqueue --write` per `.cursor/skills/babysit-plus/SKILL.md` §8 — **do not** spawn Task sub-agents to poll deploy; use `barrier-check` before the next merge.

Escalate to human when: security/crypto changes, breaking API contracts, migration risk, or product/legal decisions.

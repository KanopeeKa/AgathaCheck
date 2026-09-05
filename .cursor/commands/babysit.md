---
name: babysit
description: Keep a PR merge-ready by triaging comments, resolving clear conflicts, and fixing CI in a loop.
---

# Babysit PR

Your job is to get this PR to a merge-ready state.

**Model:** **`composer-2.5` only** — switch before starting if needed. See `docs/agent-efficiency/pr-review-cost-efficiency.md`.

**Pre-PR review:** If the PR is not open yet, complete mandatory pre-PR critical self-review first (`.cursor/rules/pr-hygiene.mdc`). Run the **Engineering Router** (`.cursor/agent-kernel/ROUTER.md`, profile per skill). If the diff touches Flutter presentation UI, apply **`.cursor/agent-kernel/protocols/accessibility.md` §Quick pass** before opening the PR.

Check PR status, comments, and latest CI and resolve any issues until the PR is ready to merge.

1. **Sync (proactive):** Keep the PR branch on the latest base **without waiting for CI to fail**:
   ```bash
   ./scripts/babysit_sync_base.sh --pr <url> --push
   ```
   Uses the PR's base branch (`main` or integration parent). Re-run **before every push**, before entering the CI wait loop, and after long polls (automatic reviews). Manual equivalent: `BASE=$(gh pr view <url> --json baseRefName -q .baseRefName) && git fetch origin "$BASE" && git rebase "origin/$BASE"`.
2. **Merge conflicts:** Intelligently resolve, preserving intent of both sides. If intents conflict, stop and ask.
3. **Ready for review:** If the PR is still a draft, mark it ready (`gh pr ready <url>`).
4. **Collect threads:** `node scripts/babysit_pr_reviews.js collect --pr <url>` — triage **every** unresolved thread in the JSON output (Copilot, humans). Never skip Copilot threads when present.
5. **Comments:** Apply triage buckets to collected threads. Validate findings — fix valid issues; explain false positives. Do not re-run full adversarial review in agent turns (slim babysit).
6. **CI:** Fix failures caused by this PR's scope. Never weaken CI gates to pass. If failure seems unrelated, run `./scripts/babysit_sync_base.sh --pr <url> --push` first — do not wait for a red CI run to discover the branch is behind.
7. **Verify locally:** `./scripts/pre-push-changed.sh` for scoped fix; `./scripts/pre-push.sh` before final push when near merge.
8. **Push** scoped fixes and re-watch CI until mergeable + green + comments triaged. Run `./scripts/babysit_sync_base.sh --pr <url>` before each push.

**After merge to `main`:** CI runs Pre-UAT E2E and promotion automatically — babysit+ does not spawn agents or poll deploy (babysit-plus §8).

Escalate to human when: security/crypto changes, breaking API contracts, migration risk, or product/legal decisions.

Full policy: `docs/agent-efficiency/pr-review-cost-efficiency.md` · `docs/agent-efficiency/autonomous-pr-policy.md`

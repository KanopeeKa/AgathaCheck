---
name: review-bugbot
description: Run a local Bugbot-style critical review on the branch diff before opening a PR to dedupe paid Bugbot billing when the patch is unchanged.
---

# Review Bugbot (pre-push dedupe)

Optional cost saver documented in `docs/agent-efficiency/pr-review-cost-efficiency.md`.

**When:** After implementation is complete, **before** the first push that opens a PR (or before a PR update that changes behavior).

**Goal:** Catch issues locally so the opened PR does not trigger a second paid Bugbot review on the same patch.

## Steps

1. **Critical self-review** — same mandatory checklist as pre-PR hygiene (`.cursor/rules/pr-hygiene.mdc`):
   - Correctness, edge cases, regressions
   - Security, data integrity, API contracts
   - Design quality vs existing patterns
   - Better solution check — adopt now if clearer/safer
2. **Diff review** — read the full branch diff vs `origin/main` (or integration parent):
   ```bash
   git fetch origin main
   git diff origin/main...HEAD
   ```
3. **Fix findings** — apply must-fix items; open debt issues for deferred nits per atomic PR policy.
4. **Verify:**
   ```bash
   ./scripts/pre-push-changed.sh
   ```
5. **UI-touching changes** — if diff includes `flutter_app/lib/**/presentation/**`, run the `/ui-check` checklist (or read `.cursor/skills/ui-check/SKILL.md` §Steps).
6. **Push + open PR** — Bugbot/Copilot runs on the PR; duplicate Bugbot billing is avoided when the patch matches the pre-reviewed diff.

## Notes

- Copilot is the primary automatic reviewer for this repo; Bugbot is disabled in babysit wait loops.
- This command does **not** call the Bugbot API — it is a structured local review workflow.
- Babysit phases: use **`composer-2.5` only** (`docs/agent-efficiency/pr-review-cost-efficiency.md`).

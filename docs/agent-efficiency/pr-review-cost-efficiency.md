# PR review & cost efficiency

Single source of truth for **pre-PR self-review**, **Bugbot configuration**, **Copilot fallback**, and **Cloud Agent model choice** during PR babysitting.

| Topic | Canonical location |
|-------|-------------------|
| Babysit+ workflow | `.cursor/skills/babysit-plus/SKILL.md` |
| Automatic review wait / triage | [autonomous-pr-policy.md](./autonomous-pr-policy.md) |
| Always-on agent rule | `.cursor/rules/pr-hygiene.mdc` |
| Bugbot project rules | `.cursor/BUGBOT.md` |

---

## Goals

1. **Safety** — Catch defects before and after PR open (self-review + Bugbot + CI).
2. **Cost** — Keep review on Bugbot’s billing bucket; reserve Cloud Agent pool for implementation and babysit fixes.
3. **No duplicate work** — Bugbot reviews; babysit+ triages and fixes; Autofix stays off.

---

## Bugbot dashboard settings (confirmed for Agatha Track)

Configure at [cursor.com/dashboard/bugbot](https://cursor.com/dashboard/bugbot) after connecting GitHub.

| Setting | Recommended | Notes |
|---------|-------------|--------|
| **Trigger mode** | **Once per PR** | One review when PR is opened or marked ready; subsequent pushes rely on babysit+ local verification + CI. Cheaper than review-on-every-push. |
| **Effort** | **Default** | Use **High** only for auth, migrations, billing, or breaking API PRs. |
| **Review draft PRs** | **On** (optional) | Early signal is fine; agents still mark PR **ready** before merge gates and babysit wait. |
| **PR summaries** | **Off** | Not needed; agents write PR bodies. |
| **Autofix** | **Off** | Babysit+ owns fixes; Autofix bills the same Cloud Agent pool and duplicates work. |
| **Incremental review** | **Off** while “once per PR” | Turn **On** only if you switch to review-on-every-push. |

Enable Bugbot on **AgathaCheck** in the repository list. Optional: require the **`Cursor Bugbot`** status check in GitHub branch protection.

Manual re-review: comment `cursor review` or `bugbot run` on the PR.

---

## Pre-PR critical self-review (mandatory)

Every agent (and every human using an agent) **must** complete this checklist **before** the first push that opens a PR and **before** any PR update that changes behavior.

1. **Correctness & impact** — Re-read the requirement; trace happy paths, edge cases, error handling, regressions.
2. **Risks** — Security (auth, validation, exposure), data integrity, migrations, API contracts, concurrency.
3. **Design quality** — Smallest change that meets intent; match existing patterns; avoid drive-by refactors.
4. **Better solution** — If a clearer or safer approach fits with equal or less scope, adopt it now.
5. **Verification** — `./scripts/pre-push-changed.sh` after adjustments.

Then: commit → push → create or update the PR.

### Optional: dedupe Bugbot billing

Run `/review-bugbot` (or ask the agent to) on the branch diff **before** push. When the opened PR has the same patch, Bugbot skips a second paid review and notes the prior run.

---

## Review stack (recommended)

```
Implementation (composer-2.5)
  → pre-PR critical self-review (mandatory)
  → open PR / mark ready

Copilot PR review (when enabled)
  → primary automatic reviewer

Babysit+ slim (composer-2.5 only)
  → node scripts/babysit_pr_reviews.js collect --pr <url>  (triage Copilot + human threads)
  → triage must-fix / nit / ignore
  → fix + ./scripts/pre-push-changed.sh
  → CI loop → ./scripts/pre-push.sh before merge
```

**Copilot:** Request when credits are available; **mandatory for triage when threads exist**. When Copilot is unavailable or posts no threads, proceed after pre-PR self-review + CI green.

**Cursor Bugbot:** Disabled for this repo — do not wait on `babysit_pr_reviews.js wait`.

**CI + CodeQL:** Unchanged — still required on merge to `main`.

---

## Cloud Agent model policy

Usage data (Jul 2026) showed **thinking models on babysit-scale work** burn ~18% of tokens in a small fraction of turns. Babysitting should stay on **Composer 2.5**.

| Work | Model |
|------|--------|
| Feature implementation, refactors, execute-plan implementation workers | `composer-2.5` |
| Deep architecture, ambiguous product trade-offs, multi-file design | Thinking models **only when explicitly needed**; switch back after |
| `/babysit`, `/babysit-plus`, PR triage, review fixes, CI loop, merge | **`composer-2.5` only** |

### Forgetting to switch back

Repo rules (`.cursor/rules/pr-hygiene.mdc`) require agents to **verify model before babysit steps**. Humans should set **Default agent model** to `composer-2.5` in [Cursor Settings → Models](https://cursor.com/dashboard/settings). For babysit-only work, start a **new cloud agent** on `composer-2.5` rather than continuing a thinking-model session.

Cursor cannot enforce model choice from the repo alone; rules + dashboard default + separate babysit sessions are the control.

---

## Cost levers (summary)

| Lever | Effect |
|-------|--------|
| Bugbot review (Autofix off) | Review off Cloud Agent pool |
| Once per PR trigger | One Bugbot run per PR |
| Default effort | Lower cost than High |
| `/review-bugbot` pre-push | Avoid duplicate Bugbot run |
| Pre-PR self-review | Fewer fix iterations after open |
| `composer-2.5` for babysit | Avoid thinking-model token burn on triage/CI |
| Slim babysit+ | Triage all collected review threads (Bugbot + Copilot + human); do not re-run adversarial review in agent turns |
| Skip Copilot wait when unavailable | No 15-minute stall |

---

## Copilot unavailable

When GitHub Copilot PR review credits are exhausted or Copilot never posts:

1. Do **not** request `copilot-pull-request-reviewer` unless credits are available.
2. Rely on mandatory **pre-PR self-review** + **CI** + `./scripts/pre-push.sh` before merge.
3. Run `node scripts/babysit_pr_reviews.js collect --pr <url>` — if threads exist, triage all before merge.
4. Comment on the PR if helpful: `Copilot unavailable; babysit+ triage used CI + pre-push only.`

Do **not** wait on Cursor Bugbot — it is disabled for this repo.

---

## Related

- [autonomous-pr-policy.md](./autonomous-pr-policy.md) — triage buckets, debt issues, merge gates
- [atomic-pr-policy.md](./atomic-pr-policy.md) — one outcome per PR
- [e2e-ci-canary-plan.md](../e2e-ci-canary-plan.md) — Copilot/babysit polling cross-ref

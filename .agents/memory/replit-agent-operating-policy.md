---
name: Replit agent operating policy (repo-aligned)
description: Binding rules distilled from AGENTS.md, .cursor/rules/*.mdc, and CI/CD gates that Replit work must follow on every request.
---

Repo docs are the source of truth. `.cursor/rules/*.mdc` + `AGENTS.md` are the authoritative shared engineering policy for ALL agents; `replit.md` is the project overview/preferences layer and must stay consistent with them. If sources conflict, stop and ask the user — never improvise a compromise — **except during active `/execute-plan`** when gate passes: follow `.agents/memory/execute-plan-autonomy.md` and the frozen snapshot; halt only on escalation or unclear goal. Inspect first, change second; smallest safe change.

**Per-request startup:** read the `.cursor/rules/*.mdc` relevant to the touched area (single-backend, security, testing, modularity, atomic-pr), summarize applicable constraints, then implement.

**Binding engineering rules:**
- **Modularity**: CI enforces a 500-line limit on all hand-written `.js`/`.dart` files across `flutter_app/lib`, `server/routes` (`scripts/check_file_size.js`); grandfathered files have an allowlist with a ratchet ceiling. Target new files <300 lines.
- **Calendar dates**: wire dates are `YYYY-MM-DD` (see `docs/calendar-dates.md`).
- **Security**: never return raw `err.message`/`e.toString()`/`$e` in prod 5xx — use `publicError()`; rate-limit DB/filesystem routes; UUID filenames + path containment for uploads.
- **Atomic outcome**: one verifiable outcome per change set; snags >15 lines become separate work items, never silently deferred.

**Sensitive paths — explicit user confirmation required** (source of truth: `.github/scripts/agent-safety-lib.js`; gate enforced by `agent-pr-safety-gate.yml` on **both** `cursor/*` and `replit/*` branches): `db/migrations/`, `server/config/security.js`, `infra/`, and any path matching `/auth/`, `/billing/`, `/secrets?/`. Note: `server/config/` broadly is NOT forbidden — only `security.js` within it. **`.github/workflows/` is allowed** for agent PRs when CI gate docs are updated in the same change.

**Migrations**: use `cd server && node scripts/migrate.js up`. No `gen_random_uuid()` in SQL — generate UUIDs in code.

**Testing commands (current)**: backend `cd server && npx jest --env=node --forceExit`; Flutter `cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration`; analyze with `cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos`; run `dart run build_runner build --delete-conflicting-outputs` when mocks change. BDD coverage gate: ≥105 mapped scenarios (`node e2e/scripts/check_bdd_coverage.js` — denominator is computed dynamically from feature files, not fixed at 165).

**CI/CD (do not break)**: two checks are GitHub-required on PRs: the umbrella `ci-gate / CI passed` aggregator AND CodeQL `Analyze JavaScript` (both must be green). Within ci-gate: any new blocking job must be added to ci-gate `needs` AND `scripts/ci/assert-ci-gate.sh`. Promotion is tag-first and automated: merge to main → `promote-uat` creates `uat-YYMMDD-PR#` tag → `deploy-uat` via workflow_run → `Prod ready` gate → `deploy-prod` (artifact promotion, provenance-checked; `PROD_DEPLOY_ENABLED`, `UAT_SSH_ENABLED`, `UAT_AUTO_MIGRATE` flags). Tags immutable. UAT `node_modules` must stay a symlink.

**PR flow (user decision):** GitHub branch protection enforces PRs to `main`; prefer routing changes through a PR (so ci-gate + CodeQL run) where practical rather than direct-to-main commits.

**PR checklist — follow in this order every time:**
1. **Rebase first**: `git fetch origin && git rebase origin/main` — resolve any conflicts before pushing; never open a PR that is behind main.
2. **Push branch** (avoid embedding token in URL — use credential helper to prevent leaking via shell history/`git remote -v`):
   ```bash
   git -c credential.helper='!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f' \
     push origin HEAD:refs/heads/replit/<topic>
   ```
   If local git commit is blocked by the sandbox, push files directly via `PUT /repos/KanopeeKa/AgathaCheck/contents/<path>` GitHub API (base64-encode content, supply current blob SHA + branch name).
3. **Open PR via GitHub REST API** using the `GITHUB_TOKEN` environment secret. Create as ready (not draft) so automatic reviewers fire immediately.
4. **Request Copilot review immediately** (parallel to CI — do not wait for CI first): `POST /repos/KanopeeKa/AgathaCheck/pulls/{n}/requested_reviewers` with `{"reviewers":["copilot-pull-request-reviewer"]}`. Canonical policy: `.cursor/skills/babysit-plus/SKILL.md` §0b — poll reviews every 30–60 s for up to 15 min alongside CI; triage must-fix / nit / ignore before merging.
5. **Monitor CI** via `GET /repos/KanopeeKa/AgathaCheck/commits/{sha}/check-runs` — poll every 60–90 s; address failures. Flutter test shards take ~3–5 min, full suite ~8–10 min.
6. **After both CI and reviews are green/triaged**: merge is user's click (branch protection). After merge, sync local main: `git fetch origin && git reset --hard origin/main` (or delegate if destructive).

**Single backend:** Node.js (`server/routes/*.js`) is the only backend. Replit preview runs the Node server.

**Why:** The user works across Cursor and Replit and requires zero drift between agents; these gates are CI-enforced, so violating them locally produces work that cannot merge.

**How to apply:** Re-read this file at the start of every task; when a task touches an area listed here, follow the rule or stop and ask — do not improvise a compromise between conflicting sources.

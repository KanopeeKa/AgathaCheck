---
title: Execute-plan v2 — runtime work packages WP1–WP3
owner: Kanopee
audience: agent
status: active
last_updated: 2026-10-15
tags: [agent, execute-plan, autonomy]
---
# Execute-plan v2 — runtime work packages WP1–WP3

Part of [execute-plan-v2.md](../execute-plan-v2.md). Contracts: [contracts.md](./contracts.md).
State machine: [state-machine.md](./state-machine.md). WP4a–WP5: [work-packages-tick.md](./work-packages-tick.md).
Kickoff prompts: [work-split-and-prompts.md](./work-split-and-prompts.md).

**Rules for every runtime WP** (in addition to index §2):
- Node 22 built-ins only (`fetch`, `crypto`, `fs`, `path`, `child_process` for `git`). No npm
  package, no `gh`, no YAML. These modules also run inside GitHub Actions without `npm ci`.
- CommonJS (`'use strict'; module.exports = …`) like the existing `scripts/lib/execute_plan_*.js`.
- Tests: `node:test` + `node:assert/strict`, offline. HTTP is faked with the WP1 fake fetch; pure
  logic is tested with plain objects. A test that reaches the network is a defect.
- Every new test file is added to the governance block of `scripts/pre-push-changed.sh` next to
  line 135 (`node --test scripts/execute_plan_runtime.test.js`). CI wiring is done once in WP7a.
- v1 untouched: a snapshot without `schema_version` or with `1` keeps today's behaviour; the
  existing `node --test scripts/execute_plan_runtime.test.js` stays green unchanged.
- Each module ≤ 400 lines; split before that.

## WP1 — GitHub client and fake fetch

**Depends on:** nothing · **Recommended executor:** Claude Code (or Cursor) · **Size:** ~350 code, ~250 tests

**Files (create)**
- `scripts/lib/execute_plan_github.js`
- `scripts/test/helpers/execute_plan_fake_fetch.js`
- `scripts/test/execute_plan_github.test.js`

**Do not touch:** any other file except the one test line in `scripts/pre-push-changed.sh`;
in particular `scripts/lib/execute_plan_project.js` (keeps its `gh` calls until WP10) and `.github/**`.

**Exports — `execute_plan_github.js`**
```js
/** @param {{ repo: string, token?: string, fetchImpl?: typeof fetch, baseUrl?: string, sleep?: (ms:number)=>Promise<void> }} opts */
function createGitHubClient(opts)          // repo = 'owner/name'; baseUrl default 'https://api.github.com'
class MissingToken extends Error {}  class RateLimited extends Error { /** resetAt: string */ }
class PullFilesOverflow extends Error {}  class GitHubError extends Error { /** status: number */ }
```
Client methods (all `async`; list methods follow `Link: rel="next"` until exhausted unless a
`pages` limit is given):

| Method | REST / GraphQL |
|--------|----------------|
| `getIssue(n)` / `closeIssue(n)` | `GET` / `PATCH /issues/{n}` (`state: closed`) |
| `listIssueComments(n)` / `createComment(n, body)` / `updateComment(id, body)` | `/issues/{n}/comments`, `PATCH /issues/comments/{id}` |
| `addLabels(n, labels)` / `removeLabel(n, label)` | `POST /issues/{n}/labels`, `DELETE /issues/{n}/labels/{label}` (404 ignored) |
| `listIssueTimeline(n)` | `GET /issues/{n}/timeline` |
| `listPulls({ head, base, state })` | `GET /pulls?head={owner}:{head}&base={base}&state={state}` |
| `getPull(n)`, `listPullCommits(n)`, `listPullReviews(n)` | `/pulls/{n}`, `/pulls/{n}/commits`, `/pulls/{n}/reviews` |
| `listPullFiles(n)` | `/pulls/{n}/files`; throws `PullFilesOverflow` when more than 3000 files |
| `createPull({ title, head, base, body, draft })`, `mergePull(n, { method })`, `updateBranch(n)` | `POST /pulls`, `PUT /pulls/{n}/merge`, `PUT /pulls/{n}/update-branch` |
| `listUnresolvedThreads(n)` | GraphQL `repository.pullRequest(number).reviewThreads(first:100){nodes{isResolved path comments(first:1){nodes{url author{login}}}}}` → `[{ url, path, author }]` for unresolved |
| `enableAutoMerge(nodeId, method)` / `disableAutoMerge(nodeId)` | GraphQL `enablePullRequestAutoMerge(input:{pullRequestId, mergeMethod: SQUASH\|MERGE})` / `disablePullRequestAutoMerge` |
| `listCheckRuns(sha)` | `GET /commits/{sha}/check-runs?per_page=100` |
| `createCheckRun({ name, head_sha, conclusion, title, summary })`, `updateCheckRun(id, {…})` | `POST /check-runs` (`status: completed`), `PATCH /check-runs/{id}` |
| `compare(base, head)` | `GET /compare/{base}...{head}` → `{ status, ahead_by, behind_by, files: [{ filename, status }] }` |
| `listWorkflowRuns(file, { branch, event, status, per_page, pages })` | `GET /actions/workflows/{file}/runs` |
| `listRunJobs(runId)` / `getJobLog(jobId)` | `GET /actions/runs/{id}/jobs`; `GET /actions/jobs/{id}/logs` (follows the redirect, returns text) |
| `dispatchWorkflow(file, ref, inputs)` | `POST /actions/workflows/{file}/dispatches` |
| `listTags({ pages })` | `GET /tags` (`[{ name, commit: { sha } }]`) |
| `getBranch(name)` / `createRef(ref, sha)` | `GET /branches/{name}` (404 → `null`), `POST /git/refs` |
| `getFileAtRef(path, ref)` | `GET /contents/{path}?ref={ref}` → `{ content: <utf-8 string>, sha }`; 404 → `null` |

**Rules**
1. Token: `opts.token` ?? `EXECUTE_PLAN_TOKEN` ?? `GH_TOKEN` ?? `GITHUB_TOKEN`. None → throw
   `MissingToken` on the first request (not at construction).
2. Headers: `Authorization: Bearer <token>`, `Accept: application/vnd.github+json`,
   `X-GitHub-Api-Version: 2022-11-28`, `User-Agent: execute-plan/2`. GraphQL: `POST {baseUrl}/graphql`.
3. Retries: status 502/503/504, or 403/429 whose body mentions `secondary rate limit` → up to 3
   retries with `sleep` 2 s, 4 s, 8 s. 403 with header `x-ratelimit-remaining: 0` → throw
   `RateLimited` (resetAt from `x-ratelimit-reset`). Never loop without a limit.
4. Other non-2xx → `GitHubError(status, message)`; 404 → `null` only where the table says so.
5. Never print tokens; errors include method and path only.

**Fake fetch — `scripts/test/helpers/execute_plan_fake_fetch.js`**
`createFakeFetch(routes)` returns a `fetch`-compatible function. `routes` maps keys
`'<METHOD> <path>?<query sorted by key>'` (path without the `https://api.github.com` prefix) or
`'POST /graphql'` to `{ status = 200, headers = {}, body }` or to `(request) => response`. An
unmatched request throws `Error('Unrecorded request: <key>')`. It records every request in
`fake.calls` for assertions. Later WPs reuse it to test `observe()` and workflow scripts.

**Tests** (`scripts/test/execute_plan_github.test.js`): `pagination follows Link`,
`listPullFiles overflow throws PullFilesOverflow`, `retry on 502 then success`,
`secondary rate limit retried then succeeds`, `rate limit remaining 0 throws RateLimited`,
`token resolution order`, `missing token throws on first call`, `getBranch 404 returns null`,
`getFileAtRef decodes base64 content`, `compare maps fields`, `unresolved threads mapping`,
`enableAutoMerge sends the GraphQL mutation`, `getJobLog returns text`,
`fake fetch throws on unrecorded request`.

**Acceptance:** `node --test scripts/test/execute_plan_github.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-runtime.md` — new section "v2 GitHub client" (what it
is, token order, no `gh` in new code, the fake for tests).

## WP2 — Scope matcher (pure)

**Depends on:** nothing (can run in parallel with WP1) · **Recommended executor:** Claude Code · **Size:** ~250 code, ~250 tests

**Files (create)**
- `scripts/lib/execute_plan_scope.js`
- `scripts/test/execute_plan_scope.test.js`

**Do not touch:** `classifyFile` / `classifyWithException` in `scripts/lib/execute_plan_schema.js:84-105`
(v1 keeps them), `.github/scripts/agent-safety-lib.js` (import only). The CLI and the workflow
that call this module are WP7a, not here.

**Exports**
```js
const PROTECTED_PATHS            // array of globs, exactly the list in rule 3
const FIXED_COMPANIONS           // array of globs, rule 7
const EXCEPTION_GLOBS            // { tests: [...], docs: [...] }, rule 6
/** @returns {{ category: 'phase'|'sync'|'sync-resolve'|'release'|'remedial'|null, phaseId: string|null }} */
function categorizePull({ head_ref, base_ref }, snapshot)
/** @returns {{ file, verdict: 'own-plan-file'|'protected'|'forbidden'|'allowed'|'exception:tests'|'exception:docs'|'companion'|'unclassified' }} */
function classifyPath(file, { snapshot, category, phaseId })
/** @param {{ files: string[], snapshot, category, phaseId, ownPlanFilesVerified: boolean, stopped: { stopped: boolean, reason: string|null } }} args
 *  @returns {{ conclusion: 'success'|'failure', title: string, violations: {file:string, reason:string}[], companionsUsed: string[] }} */
function evaluateDiff(args)
```

**`categorizePull`** (`<id>` = `snapshot.plan_id`, `I` = `snapshot.integration_branch`):
`cursor/<id>-p<n>` → `I` ⇒ `phase` (phaseId `n`); `main` → `I` ⇒ `sync`; `cursor/<id>-sync-<n>` → `I` ⇒
`sync-resolve`; `I` → `main` ⇒ `release`; `cursor/<id>-remedial-<n>` → `main` ⇒ `remedial`;
anything else ⇒ `null`.

**`evaluateDiff` rules** (globs via `globToRegExp` from `scripts/lib/execute_plan_schema.js:72`; **no brace expansion** — list every glob separately):
1. `stopped.stopped` → `failure`, title `plan-stopped`, no file evaluation.
2. `category == null` or `'sync'` → `success`, title `ok`, no file evaluation.
3. Per file, first match wins:
   a. `.agents/plans/<id>.md` or `.agents/plans/<id>.snapshot.json` → `own-plan-file`: allowed
      only when `category == 'release'` and `ownPlanFilesVerified`; otherwise violation `drift`.
   b. Protected set → violation `protected`: `scripts/execute_plan_runtime.js`,
      `scripts/execute_plan_runtime.test.js`, `scripts/lib/execute_plan_*`,
      `scripts/validate_execute_plan_snapshot.js`, `scripts/test/execute_plan_*`,
      `scripts/test/helpers/execute_plan_*`, `scripts/test/fixtures/execute-plan-v2/**`,
      `scripts/pre-push.sh`, `scripts/pre-push-changed.sh`, `.github/**`, `.cursor/rules/**`,
      `.cursor/skills/**`, `.cursor/hooks.json`, `.claude/**`, `AGENTS.md`, `CLAUDE.md`,
      `.agents/plans/**`, `docs/agent-efficiency/plans/execute-plan-v2.md`,
      `docs/agent-efficiency/plans/execute-plan-v2/**`.
   c. `isForbiddenPath(file)` from `.github/scripts/agent-safety-lib.js` (migrations, security
      config, infra, `/auth/`, `/billing/`, `/secret(s)/`) → violation `forbidden`.
   d. Any phase's `forbidden_paths` (for `phase`: that phase; otherwise all phases) → `forbidden`.
   e. Scope globs: `phase` → that phase's `allowed_paths`; `release` and `sync-resolve` → union of
      all phases' `allowed_paths`; `remedial` → that union plus `e2e/**` → `allowed`.
   f. Exceptions, only when listed (`phase`: by that phase; otherwise by any phase; `remedial`
      always gets `tests`): `tests` = `**/test/**`, `**/*.test.js`, `**/*.test.mjs`,
      `**/*.test.ts`, `**/*_test.dart`, `e2e/**/*.spec.ts`; `docs` = `docs/**`, `**/*.md` →
      `exception:<name>`.
   g. Companions: the phase's `companions` (all phases' for non-phase categories) plus
      `FIXED_COMPANIONS` = `**/generated/**`, `**/*.g.dart`, `**/*.freezed.dart`,
      `flutter_app/lib/l10n/*.arb`, `docs/architecture/openapi/*.json`,
      `flutter_app/lib/features/*/*.dart` (feature barrel files) → `companion`; the 6th and later
      companion files are violations `companion-cap`.
   h. Otherwise violation `unclassified`.
4. Title = the most serious violation reason present, in this order: `drift`, `protected`,
   `forbidden`, `unclassified`, `companion-cap`; no violation → `ok`. Conclusion `failure` iff
   any violation.

**Tests:** `forbidden beats allowed (server/** allowed, server/routes/auth/x.js)`,
`protected beats allowed (.github/workflows/x.yml in allowed_paths)`, `exception tests matches only test files`,
`exception docs rejects care_item.dart`, `barrel care_item.dart is a companion and reported`,
`openapi json is a companion`, `sixth companion is companion-cap`, `own plan file in phase PR is drift`,
`own plan file in release PR verified is allowed`, `own plan file in release PR unverified is drift`,
`other plan file is protected`, `release uses union`, `remedial allows e2e and tests`,
`sync category green without evaluation`, `stopped plan red plan-stopped`, `unclassified red`,
`categorizePull for each category and null`, `title priority`.

**Acceptance:** `node --test scripts/test/execute_plan_scope.test.js && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/execute-plan-schema.md` — new section "v2 scope check":
categories, evaluation order, protected set, companions, exception globs, and that plans can never
touch paths matched by `agent-safety-lib.js` (auth, billing, secrets, migrations, infra).

## WP3 — Approval, snapshot v2, `init`

**Depends on:** WP1 · **Recommended executor:** Claude Code · **Size:** ~400 code, ~300 tests

**Files**
- Create: `scripts/lib/execute_plan_approval.js`, `scripts/lib/execute_plan_snapshot_v2.js`,
  `scripts/lib/execute_plan_init.js`, `scripts/test/execute_plan_approval.test.js`,
  `scripts/test/execute_plan_snapshot_v2.test.js`, `.agents/plans/_example.v2.md`,
  `.agents/plans/_example.v2.snapshot.json`.
- Modify: `scripts/lib/execute_plan_constants.js` (add a v2 block), `scripts/validate_execute_plan_snapshot.js`
  (route v2), `scripts/execute_plan_runtime.js` (register `init`), `scripts/pre-push.sh` and
  `scripts/pre-push-changed.sh` (validate the v2 example next to `_example.snapshot.json`).

**Do not touch:** v1 functions in `scripts/lib/execute_plan_artifacts.js` and
`scripts/lib/execute_plan_schema.js` (call them only for `globToRegExp`), `.github/**`,
`.agents/plans/_example.snapshot.json`.

**Exports**
```js
// execute_plan_constants.js (append)
const V2_CAPS = { window_days: 14, ci_per_phase: 3, launches_per_phase: 6, remedial_rounds: 3, sync_attempts: 2, daily_launches: 30, phases: 8, companions: 5 };
const V2_DEFAULTS = { window_days: 7, budgets: { ci_per_phase: 3, launches_per_phase: 5, remedial_rounds: 3, sync_attempts: 2, daily_launches: 20 } };

// execute_plan_approval.js
function canonical(value)                         // contracts §3.4
function computeApprovalHash(snapshot)            // 'sha256:<hex>'; ignores snapshot.approval_hash
const APPROVE_RE, RESUME_RE, REVOKE_RE            // contracts §3.3
function parseControlComment(body)                // → { verb: 'approve'|'resume'|'revoke', plan, hash?, until? } | null
/** @param {{ comment: {user:{login}, author_association, created_at, updated_at, body}, snapshot, config: {owners: string[], bot_login: string} }} args
 *  @returns {{ valid: boolean, reason: null|'not-owner'|'bot'|'edited'|'plan'|'hash'|'until'|'window', verb, until }} */
function validateControlComment(args)
/** Latest approve/resume comment (valid or not) and latest valid revoke. */
function findControlComments(comments, snapshot, config) // → { authorizing: <Observations.control.authorizing>|null, revoke_comment_at: string|null }

// execute_plan_snapshot_v2.js
function isV2(snapshot)                           // schema_version === 2
function validateSnapshotV2(snapshot, { planMarkdown })  // throws ExecutePlanError with a precise message
function parsePlanMarkdown(markdown)              // → { title, phases: [{ id, title, scope: {...json block} }] } per contracts §3.2
function buildSnapshotFromPlan({ planId, planMarkdown, controlIssue, now, windowDays, integrationSuffix, settings }) // → snapshot with approval_hash
async function loadSnapshotAtRef(client, planId, ref)     // reads both files at ref; validates; checks hash → { snapshot, planMarkdown }

// execute_plan_init.js
async function runInit({ client, planId, windowDays = 7, dryRun = false, git, now })
```

**Rules**
1. `validateSnapshotV2` enforces every row of contracts §3.1, the caps, `computeApprovalHash(snapshot)
   === snapshot.approval_hash`, and `sha256(planMarkdown) === plan_file_sha256`.
2. `parsePlanMarkdown` follows contracts §3.2 exactly: phases from `### Phase <id> — <title>`
   headings, the first fenced ```` ```json ```` block after each heading is `JSON.parse`d; a
   heading `Contract`, `Rules` or `Process` at any level → error `plan file must not contain
   process rules (heading "<name>")`.
3. `buildSnapshotFromPlan`: `integration_branch = cursor/<planId>-integration-<integrationSuffix>`
   (suffix = the last 4 characters of `planId` when it ends in `-[a-z0-9]{4}`, as in
   `proof-build-label-7f3a` → `7f3a`; otherwise the first 4 hex chars of `sha256(planId)`),
   phase branches `cursor/<planId>-p<id>`,
   `release_branch: "main"`, `approved_until = now + windowDays` (seconds = 0, ISO `Z`),
   `protected_paths_version: 1`, settings default from `V2_DEFAULTS` overlaid by the given values.
4. `validate_execute_plan_snapshot.js`: `schema_version === 2` → v2 validator (reads the plan file
   next to it); `--fix-hash` on a v2 file exits `1` with `--fix-hash is not allowed for v2 snapshots`.
5. `runInit` (CLI `node scripts/execute_plan_runtime.js init <plan_id> [--window-days N] [--dry-run]`):
   a. Current branch must be `cursor/<plan_id>-init`; `git status --porcelain` may list only
      `.agents/plans/<plan_id>.md`; otherwise exit `3` with the reason.
   b. Parse and validate the plan markdown (rule 2).
   c. Create the control issue: title `execute-plan: <title> (<plan_id>)`, label `execute-plan`,
      body = phase table (id, title, branch, allowed paths), window, `Approval hash: pending`.
   d. Build the snapshot with that issue number, write `.agents/plans/<plan_id>.snapshot.json`,
      `git add` both files, commit `execute-plan init <plan_id>`, `git push -u origin HEAD`.
   e. Edit the issue body: replace `Approval hash: pending` with the hash, add
      `Init branch: cursor/<plan_id>-init @ <commit sha>` and the exact line the owner must post:
      `approve-autonomous <plan_id> sha256:<hex> until <approved_until>`.
   f. Print that line and exit `0`. **The session ends here by design** (the one human checkpoint).
   g. `--dry-run`: no issue, no commit, no push; print the snapshot JSON and the approval line
      with `control_issue: 0`.
6. Example files: `_example.v2.md` = the §8 proof plan of the runbooks with `<date>` replaced by
   `2026-10-16`; `_example.v2.snapshot.json` is generated from it by `buildSnapshotFromPlan`
   (`controlIssue: 1900`, `now: 2026-10-16T09:00:00Z`) — never hand-edited. The §3.4 test
   vectors use inline objects, not these files.

**Tests:** `canonical empty`, `canonical sorted`, `approval hash example (contracts §3.4 vector 3)`,
`hash ignores approval_hash field`, `hash changes when plan_file_sha256 changes`,
`approve regex accepts exact line`, `approve regex rejects trailing text`, `resume and revoke parse`,
`validate: not-owner`, `validate: author_association not OWNER`, `validate: bot login`,
`validate: edited`, `validate: wrong hash`, `validate: approve until mismatch`,
`validate: resume until beyond 14 days`, `findControlComments picks latest authorizing`,
`snapshot caps: raising a budget rejected`, `snapshot caps: lowering accepted`,
`integration branch pattern enforced`, `phase branch pattern enforced`, `plan markdown json block parsed`,
`plan markdown with Rules heading rejected`, `v1 file routed unchanged`, `--fix-hash refuses v2`,
`init refuses wrong branch`, `init refuses dirty tree`, `init dry-run output`
(`init` tests inject a fake `git` object and the WP1 fake fetch).

**Acceptance:** `node --test scripts/test/execute_plan_approval.test.js scripts/test/execute_plan_snapshot_v2.test.js && node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.v2.snapshot.json && ./scripts/pre-push-changed.sh`

**Docs:** `docs/agent-efficiency/plan-template.md` — new section "v2 plan file" (contracts §3.2
layout and the error for process-rule headings); `docs/agent-efficiency/autonomous-pr-policy.md:313`
— replace "Plan changes after approval → new snapshot + `approve-autonomous` again" with
"v2: plans are immutable after approval; changing scope means a new plan; time and budgets are
renewed with `resume-autonomous`".

# Handoff — care-next-occurrence-c1a7 (2026-09-30)

Everything a new agent needs to continue the CARE programme from where the
previous session stopped. Read this first, then the plan
([care-next-occurrence-c1a7.md](care-next-occurrence-c1a7.md)) and
[parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md) §5–§7
on `main`.

**Delete this file in the commit that lands the A+B slice** (it is a working
note, not documentation).

## Takeover corrections — 2026-09-30

The owner approved Replit Agent continuing and pushing this plan after a
read-only review and the previous agent's confirmation of these corrections.
This section supersedes conflicting operational instructions below; the quoted
owner messages remain historical context.

- **One writer, preserved history:** continue on `claude/eager-edison-mf34j6`.
  Merge `origin/main` into this shared branch; do not rebase or force-push it.
- **First fix:** migration 083 must leave transaction ownership with the
  migration runner. Remove its internal transaction boundaries and do not
  swallow item synchronization errors. Prove failure rollback, successful retry,
  repeat-run safety, and preservation of the enclosing transaction.
- **B9 is mandatory:** CR-1…7 and migration idempotency are exit criteria.
  Explicitly cover delayed-tick catch-up, pet-timezone day boundaries,
  concurrent completion of different slots, and DST tick deduplication.
- **Verification:** use Flutter 3.44.0 / Dart 3.12, Node 22 and PostgreSQL 16.
  A full nine-shard `e2e.yml` dispatch is an accepted localhost gate if the
  frontend artifact and tests are verified against the same candidate commit.
  This does not replace full pre-push or post-merge pre-UAT checks.
- **Landing:** A+B only after ARCH D is on main, main's pre-UAT is green,
  and no other programme is landing. TEST phase 1 and PEOPLE documentation
  already landed; the audit dependency files already match main.
- **Data safety:** local validation uses an isolated disposable database.
  No production reset or broad repair of older migrations is authorized by
  this takeover.

### Validation follow-up — not ready to land

- Pushed candidate: `df24d31d3c4d09e012c1046a2f01952540123817`.
  [Nine-shard CI](https://github.com/KanopeeKa/AgathaCheck/actions/runs/36772443621)
  finished with **eight passing shards and shard 3 failing**.
- [Regular CI](https://github.com/KanopeeKa/AgathaCheck/actions/runs/36772351948)
  passed PostgreSQL integration, all Flutter shards, analyze/format, coverage,
  integration, web build, governance, audits and the smoke canary. The
  database-free backend Jest job failed: it also selects the new DB-required
  suites. A separate unit-only Jest config and CI command are being verified
  locally; full `npm test` and the PostgreSQL job still require real DB coverage.
  This follow-up still needs a new remote CI run.
- The uploaded CI log identifies the new pre-trip-completion scenario failing
  during Flutter bootstrap, before login; 28 other shard-3 scenarios did not run.
  The page-wide clock header reached external assets. It is now restricted to
  same-origin backend API requests, preserves other handlers/headers, and clears
  safely after a timeout closes the page. No scenario assertion or timeout was
  weakened. The unchanged scenario passed locally after a clean server restart.
- Helper verification: **12/12 unit tests**, E2E TypeScript, and a real Chromium
  two-origin probe passed. The probe proves the old global header reaches the
  external resource server while the scoped clock does not, and still reaches
  the backend API.
- Database-free unit coverage: **141/142 suites, 1,113/1,114 tests** passed;
  the sole failure was a five-second sharing-test timeout. Its complete file
  then passed **9/9** on a focused rerun. Do not describe the initial coverage
  run as wholly green; fresh CI must confirm the result.
- GitHub connector execution recovered, but account-level repository push
  permission did not establish workflow-file write access. Ordinary-file tree
  creation succeeds; creating a tree with the changed Actions workflow returns
  404. Offered OAuth scopes omit `workflow`, so reconnecting the same connector
  is not a supported remedy. Shell Git explicitly rejects its credentials.
  The reconciled commits remain local; no partial change was pushed.
- The owner reconfirmed a sole writer. The remote branch update and latest
  `origin/main` were merged without rewriting history; the local clock/CI fixes
  and the newer TEST/PEOPLE changes are all preserved.
- The old full pre-push was stopped before merging because incoming test changes
  would invalidate its result. Fresh full pre-push and exact-candidate CI are
  required for the combined tree; do not infer signoff from older passing jobs.
- Fresh combined-tree verification passed governance, **153 backend suites /
  1,185 tests**, and **12 E2E helper tests** plus TypeScript. The new full
  pre-push continues through Flutter; its final result is still pending.
- Landing is still blocked independently of publishing: ARCH D PR #1467 remains
  open, main's latest pre-UAT run is pending, and other programme PRs are open.
  Keep this PR draft and preserve the original serialized landing gates.

### Takeover implementation and evidence

- Migration 083 is now transaction-neutral and propagates failures. Its actual
  CLI PostgreSQL tests prove rollback of schema, earlier item writes and ledger,
  followed by successful retry and idempotent CLI/hook reruns.
- B9 now covers all CR-1…7 explicitly, including held advisory-lock overlap,
  two authorized carers racing for one or different slots, delayed catch-up,
  timezone boundaries and both UTC instants of the autumn repeated hour.
  Spring gaps retain the stored time but become due at the first real minute;
  Paris and Lord Howe are covered. Formatter/slot caches are bounded.
- B10 covers real next occurrences on away plans, separate estimated summaries,
  exact today/tomorrow dose counts, and reminder recreation after on-time
  completion. Notification grouping retains its verified existing assertion;
  its SQL backdate helper now rejects a zero-row update.
- Backend verification passed: **153 suites / 1,184 tests**, including real DB
  suites. Focused migration tests: **2/2**; schedule/catch-up tests: **37/37**.
  Full local seeding into a separate disposable database followed by repair
  dry-run checked **18 care items, zero violations**.
- The full pre-push and all nine active localhost shards are still required
  landing evidence; use the exact-candidate workflow results/comments on
  [PR 1448](https://github.com/KanopeeKa/AgathaCheck/pull/1448), not the earlier
  focused counts, to determine whether those gates have finished.
- For browser runs, explicitly supply the same isolated PG settings as the
  backend as well as `E2E_BASE_URL`. Non-care notification helpers still use
  SQL, so changing the HTTP URL alone is insufficient.
- Keep disposable database/workflow settings out of the pushed `.replit`.
  Older migrations with internal transaction boundaries were handed to ARCH E
  on [its control issue](https://github.com/KanopeeKa/AgathaCheck/issues/1446#issuecomment-5918723158);
  they are not part of the CARE fix.

The original checkpoint list and unfinished-work notes below describe the
pre-takeover state; this section supersedes them.

---

## 1. Owner instructions in force

Verbatim, latest first:

1. "Resume. Fix the Backend Jest failure on PR 1448, then finish B9–B10. Apply the
   CARE changes in parallel-programmes.md §6 (on branch claude/exciting-bardeen-hy6yzp):
   land A+B as their own slice, keep migration 083, and fix the provider snapshot at
   providerUsed.js:47. Before opening the A+B PR to main: rebase on main (ARCH D and
   TEST phase 1 will be there), then run the full pre-push and all 9 localhost
   Playwright shards. From then on, new Flutter code must pass
   scripts/check_feature_imports.js, and new test folders must be added to
   flutter_app/test/ci_shards.json. Continue autonomously"
2. Execution model (2026-09-29): execute-plan in essence — integration branch for the
   whole plan, `phase(<n>/<m>): …` commits with **no approval stops**, merge and babysit
   until pre-UAT E2E is green.

Standing rules:

- Push only to **`claude/eager-edison-mf34j6`** (integration line for the whole plan).
- Never `gen_random_uuid()` in SQL — UUIDs in JS. Keep the word "Overdue".
- Pre-launch: care data may be wiped (owner-approved, plan §6.3).
- Commit trailer:
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01Bt4AKWjKRuDofFbYg1cadg`
  (a new session uses its own session link). No model names in commits, PRs or code.
- PR links as full URLs.

## 2. parallel-programmes.md rules that bind CARE

- **§6 CARE deltas:** land per child — **A+B**, then **C+D**, then **E+F** — each its own
  integration → `main` PR with `/babysit-uat`; merge main into the integration branch after every
  landing. Keep migration **083** (renumber only if another programme takes 083 first).
  Completion records the provider snapshot from the item's attached contact, not filtered
  by the completer's directory (PEOPLE invariant I12) — **done in B4b**. E2E infra changes
  (shard manifest, canary swap) wait for TEST slice 1 (issue #1449). Child E owns
  `server/routes/.../plannedAbsencesRouter.js` and `flutter_app/lib/features/pet_care/context/**`
  until it lands. Child C's pet-profile agenda lands before ARCH G / PEOPLE p13.
- **§5:** one landing at a time (check no other programme `main` PR is open/landing);
  after each landing post the §7 landing broadcast on every open programme control
  issue/PR (ARCH #1446/#1447, TEST #1449 / PR #1455, PEOPLE PR #1454); merge main then full
  pre-push + 9 shards; stay in CARE's area (`server/lib/people/**` belongs to PEOPLE);
  shared E2E files append-only outside the owner window; contracts travel with code; no
  cross-branch merges.
- **Landing order:** 0 PEOPLE docs (PR #1454) · 1 ARCH D · 2a TEST slice 1 (PR #1455) /
  **2b CARE A+B** · 3b CARE C+D · 5b CARE E+F.

## 3. Where things stand

### Historical pre-takeover checkpoints on `claude/eager-edison-mf34j6`

| Commit | What |
|---|---|
| `a0ebad9`…`57c27f3` | Plan v1 → v3.1 + owner validation |
| `f045112` | A1 — canonical docs (D-CSM-019…033, D-CIE-024…028, D-ACP-011, terminology, api-reference) |
| `745e424` | B1–B6 — engine: `server/lib/care/schedule/*`, `server/lib/care/occurrence/*`, migration 083 (+down, runner script, canonical.sql, manifest), commands/routes, care tick, write-path guard `scripts/check_occurrence_writes.js` |
| `ed9edef` | B7 — reminders on real dates, list/detail DTOs, OpenAPI, test clock header `X-Care-As-Of` |
| `0ec4638` | B8 — UAT seed built through care commands + `uat-demo-data.md` |
| `f0fff61` | B9 (part) — seed DB test skips without PostgreSQL; I12 provider snapshot fix (`server/lib/care/providerUsed.js` + `server/test/db/careProviderSnapshot.integration.test.js`); undo of one-off completion reactivates; fixed-schedule keeps latest series date ≤ today (still Overdue) |
| `4645c4e` | `npm audit` fix (see §4) |
| (this commit) | B10 work in progress + this handoff |

### PR [KanopeeKa/AgathaCheck#1448](https://github.com/KanopeeKa/AgathaCheck/pull/1448)

Draft, base `main`. On `f0fff61` every check was green **except** `test-suite / Backend
(Node.js Jest)`, which failed at the `npm audit --audit-level=high` step (new advisories
published 2026-09-30, affects every branch including `main`). `4645c4e` fixes it; CI result
for `4645c4e` and later was **not yet checked**. Retitle/mark ready as the **A+B slice**
only when §5 below is done.

### Other open PRs to `main` (2026-09-30 ~09:15 UTC)

- [#1455](https://github.com/KanopeeKa/AgathaCheck/pull/1455) TEST 1a (shard manifest `ci_shards.json` + ownership gate) — branch `claude/relaxed-einstein-jqecfg`. It will hit the same `npm audit` failure unless it carries a fix.
- [#1454](https://github.com/KanopeeKa/AgathaCheck/pull/1454) PEOPLE docs + `parallel-programmes.md` (draft) — branch `claude/exciting-bardeen-hy6yzp`.
- ARCH D was **not yet on `main`** (main head was `f04e19a`).

### Verification done so far

- Server: `cd server && npm test -- --forceExit` → **151 suites / 1173 tests pass**
  (use `npm test`, not bare `npx jest`: bare jest also runs frozen-domain suites that
  need `ENABLE_FROZEN_DOMAINS=true` and fail with 404s).
- DB integration (`server/test/db/**`, PostgreSQL up): all pass — 41+ occurrence cases,
  520-step property test (INV-1…5, OR-4), provider snapshot, seed row assertions; repair
  dry-run 0 violations.
- `npm audit --audit-level=high` clean in `server/` and `e2e/`.
- Local Playwright (after the web rebuild in §6):
  `health.tracking.spec.ts` + `notifications.spec.ts` → **27 passed, 1 skipped, 1 failed**
  (the multi-dose test, §5.1).

## 4. The `npm audit` fix (`4645c4e`)

`server/package.json`: `overrides.brace-expansion` 5.0.9 → **5.0.12**; `nodemailer`
^9.0.6 → **^10.0.13** (v10's only breaking change is Node ≥ 20; CI uses 22; used only in
`server/config/mail.js` via `createTransport`); `npm audit fix` took express 4.22.3,
qs 6.16.0, ip-address 10.7.2. If `main` gets its own fix first, take `main`'s lockfile on
rebase and drop this commit's changes.

## 5. Next steps, in order

### 5.1 Finish B10 (E2E fallout of the server change)

Uncommitted-then-committed WIP (this commit):

- `e2e/playwright/support/care-api.ts` (new): `withCareClock`, `createCareItem`,
  `getCareItem`, `completeOccurrence`, `completeNextOccurrence` (keep/keep),
  `skipOccurrence`, `recordEarlierDoses`, `planAnotherDate`, `changeDate`, `postpone`,
  `resume`, `undoLast`. API only — never SQL on `health_occurrences`.
- `e2e/playwright/support/api.ts`: removed `markHealthEntryTaken`,
  `undoCompleteHealthEntry`, `seedMultiDoseHealthEntry`, `seedPlannerOccurrenceChain`,
  `pinOpenOccurrenceForEntry`, `getHealthEntryHistory`.
- `health.tracking.spec.ts`: uses care-api; snooze test removed; multi-dose test seeds
  via `createCareItem(times ['23:58','23:59'])`.
- `notifications.spec.ts`: `completeNextOccurrence` replaces `markHealthEntryTaken`.
- `flutter_app/test/bdd/features/health_tracking.feature`: "Snoozing a health entry"
  scenario removed (snooze no longer exists).
- Plan file: coordination row, landing-slice table, phase B4b.

**Open failure — `health.tracking.spec.ts` "multi-dose daily medication shows stack sheet
and records one dose":** `OccurrenceStackSheetPage.expectDueTodayDoseCount(2)` finds
**4** "at" rows. Cause: a fixed schedule now stores today's **and tomorrow's** slots
(D-CSM-023), and the current (pre-child-C) Flutter stack sheet lists every open
occurrence; the page-object locator (`flt-semantics` filtered by "Due today", then
`getByText(/\bat\b/)`) also matches tomorrow's rows. Fix in the test/page object
(assert today's two rows by their date/label, or count rows under the "Due today"
header only) — do not change the engine. Child C rewrites this sheet anyway (C4/C6),
so keep the fix minimal. After recording one dose, the API assertions (3 pending, 1
completed) are already correct.

Then run the remaining B10 specs (plan §11.3 "B" rows) and fix fallout:

- `away.care.planning.spec.ts` — a grep of `e2e/playwright` found no remaining use of the
  removed helpers, so run it as is; move any date pinning to `withCareClock`; add AB-1
  (plan §8.9).
- `away.plan.detail.v2.spec.ts`, `away.planning.spec.ts` — seed via API; assertions unchanged.
- `care.item.absence.spec.ts`, `guardian.dashboard.spec.ts` (already asserts there is no
  "snooze" button), `pet.profiles.spec.ts`.
- `weight.tracking.spec.ts` — weigh-in completion and weight-entry deletion (UN-5).
- `sharing.spec.ts` — no change expected; run it. `adoption.spec.ts` and
  `organisation.pet.management.spec.ts` are now in the frozen-domain manifest,
  excluded from the active nine-shard gate; do not reactivate them.
- `@smoke-ci` canary.
- BDD gate: `node e2e/scripts/check_bdd_coverage.js --report-only` (≥ 68 % of active scenarios).

Commit as `phase(B10/33): e2e: care API helpers and test clock replace SQL care seeding`
and push. Required B9 completion includes CR-5 (different stack slots),
migration-083 idempotency and failure rollback, plus explicit CR-2, CR-3 and
CR-6 database coverage (see takeover corrections above).

### 5.2 Land the A+B slice (landing 2b)

1. Wait until **ARCH D** and **TEST slice 1** (PR #1455) are on `main`, and no other
   programme `main` PR is open/landing.
2. `git fetch origin main && git merge origin/main` (shared branch; no rebase or
   force-push). Keep migration **083** unless `main` took that number. Resolve
   `ci_shards.json`: any **new Flutter test folder** from this branch must be listed there.
3. `./scripts/pre-push.sh` (full) green.
4. All **9 localhost Playwright shards** green (see §6 for local setup; shard list in
   `e2e/` config / `.github/workflows` pre-UAT workflow).
5. Retitle PR #1448 as the A+B slice ("Care occurrences A+B: …"), update body (scope =
   children A+B; C–F follow in later PRs), mark ready, CI green, handle review
   (Copilot-first; `.claude/skills/steward|babysit` if present on head).
6. Merge per `merge-policy.mdc`, then babysit `pre-uat-e2e.yml` until green.
7. Post the §7 landing broadcast on every open programme control issue/PR.
8. Delete this handoff file in the landing commit (or right after).

### 5.3 After A+B lands

Merge main into the integration branch, then child **C** (agenda, row, sheets), **D** (form + Care
Item view) → C+D PR (landing 3b), then **E** (absences) + **F** (module consolidation,
compat routes deleted) → E+F PR (5b). New gates from here on: new Flutter code passes
`node scripts/check_feature_imports.js`; new Flutter test folders go in
`flutter_app/test/ci_shards.json`. Phases and exit checklists are in plan §10.

## 6. Local environment recipe (cloud container)

```bash
# PostgreSQL stops on every container restart
sudo pg_ctlcluster 16 main start
cd server && node scripts/migrate.js up

# Flutter web must bundle CanvasKit locally: the egress proxy denies www.gstatic.com
# (403 CONNECT) and fonts.gstatic.com, so the default CDN build never renders
# (every Playwright test times out waiting for flutter-view). Roboto still fails
# to load from fonts.gstatic.com — harmless, tests use semantics.
cd flutter_app && PATH=/opt/flutter/bin:$PATH \
  flutter build web --release --no-tree-shake-icons --no-web-resources-cdn

# Server (single origin, serves flutter_app/build/web, API under /backend)
cd server && E2E=1 APP_ENV=ci PGUSER=user PGPASSWORD=password PGHOST=localhost \
  PGPORT=5432 PGDATABASE=agatha_db nohup node bin/start.js > /tmp/server.log 2>&1 &
```

Playwright 1.63 in `e2e/` expects a newer Chromium than the preinstalled one. Create
`e2e/playwright.sandbox.config.ts` locally — **never commit it**:

```ts
// Local sandbox only (not committed): use the preinstalled Chromium.
import base from './playwright.config';

const executablePath = '/opt/pw-browsers/chromium';
export default {
  ...base,
  use: { ...base.use, launchOptions: { ...(base.use?.launchOptions ?? {}), executablePath } },
  projects: (base.projects ?? []).map((p) => ({
    ...p,
    use: { ...(p.use ?? {}), launchOptions: { ...((p.use as { launchOptions?: object })?.launchOptions ?? {}), executablePath } },
  })),
};
```

Run: `cd e2e && npx playwright test -c playwright.sandbox.config.ts --project=full <specs> --reporter=line`
(~20 s per test, single worker). The test clock header `X-Care-As-Of` works when
`APP_ENV` ∈ {development, test, ci}.

Other checks: `./scripts/pre-push-changed.sh` while iterating; `node scripts/check_file_size.js`
(≤ 500 lines); `node scripts/check_occurrence_writes.js`; Flutter
`flutter analyze --no-fatal-warnings --no-fatal-infos` and
`flutter test --concurrency=1 --exclude-tags=integration`.

## 7. Engine facts worth knowing before touching tests

- Every active planned item has ≥ 1 stored open occurrence, written in the same
  transaction; `next_due_date` = earliest open (read-only cache). No T−1 materialisation.
- Schedule types: **Fixed schedule** (`from_due_date`, medication default) and **After
  it's done** (`from_completion`, other families). Multiple times require Fixed.
- Fixed slots stored: series dates in [today−3, today] + latest series date ≤ today
  (stays Overdue) + next series date after today; nothing before `series_resumed_on`.
  A Not recorded slot closes when its next slot date ≤ today−3; Overdue never auto-closes.
- Occurrence status per row: `coming_up` / `due` / `overdue` / `not_recorded`; server
  sends `as_of`.
- Ask-before-saving 409s (nothing saved): `next_choice_required`,
  `earlier_choice_required`, `occurrence_not_open`. `late_completion_choice` can be remembered.
- Commands run in `withCareItemLock` → `executeCareCommand` (catch-up sync → action →
  sync → one `care_schedule_events` ledger row with payload; undo is whole-command).
- Compat routes (`mark-taken`, `ensure-open`, `pause`, `skip-missed`, `undo-complete`)
  still exist until child F2 deletes them.

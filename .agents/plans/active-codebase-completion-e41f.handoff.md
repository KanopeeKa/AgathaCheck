---
title: Handover — architecture programme active-codebase-completion-e41f (Batches D–K)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-30
---

# Handover: architecture programme `active-codebase-completion-e41f` (ARCH)

**State at 2026-09-30 ~19:45 UTC.**

- Written by Claude Code session `session_01YUBDQf93z9AFgmhDkvGh3g`, which started and has
  driven the programme so far.
- This file is self-contained: you should not need that session's transcript.
- It lives on branch `claude/friendly-davinci-5zcxj2`, next to
  `active-codebase-completion-e41f.gen_snapshots.py` (§6).
- The plan files themselves are on `cursor/active-codebase-d-integration-e41f`.

**How to read this file:**

1. Read §0 and §1, then do §2.
2. §3 tells you what to do on every wake.
3. The rest is reference.

---

## 0. TL;DR

- **Goal:** finish the accepted architecture review
  (`docs/architecture/reviews/active-codebase-review.md`, Packages 1–12).
  - The roadmap `.agents/plans/active-codebase-completion-e41f.md` chains nine execute-plan
    children, D → K.
  - Each child builds on its own integration branch, lands on `main` through one PR, and is done
    only when **pre-UAT E2E is green on the merge SHA**.
- **Where we are:**
  - Batch D phases 1–3 are merged into `cursor/active-codebase-d-integration-e41f` (head
    `c81b09ec`, pushed).
  - Phase 4 (integration → `main` + pre-UAT) is **not opened yet**, by the user's instruction.
- **The one blocker:** PR **#1454** (People docs, landing slot 0b) must merge first.
  - It is a **draft labelled `do-not-merge`**, owned by another session
    (`session_01F26uJYD6S5qBrfK9ibiuNS`).
  - **Do not merge it yourself.** Only the user or its owner lands it.
- **After D:** E–K each wait for work that CARE, TEST or PEOPLE own (§5). ARCH can't speed that
  up; each child starts when its slot opens.
- **Time bomb:** the roadmap and D approval windows end **2026-10-01T22:39:00Z** (§1.3).

## 1. Ground rules

### 1.1 Single driver

Only one agent may drive this programme at a time. The previous session scheduled a one-shot
check-in that wakes *it* (not you):

- trigger `trig_01GH4Y6o9g1E9DrSSm5NKquv`, due 2026-09-30T20:26Z.

When you take over:

1. If the trigger is still pending, delete it with `mcp__Claude_Code_Remote__delete_trigger`.
2. If it has already fired, tell the user that session must stop.
3. Then schedule your own check-ins.

### 1.2 User instructions (verbatim; they bind you)

1. Initial grant (2026-09-29): *"That's fine, go ahead, and let me know exactly what to do if you
   need me."* Recorded as the standing grant on the roadmap control issue #1446.
2. Merge authority (2026-09-30): *"When in a plan under "execute-plan" you always have the full
   confirmation to merge yourself."*
   - This covers the programme's own PRs only: phase PRs into integration branches, and each
     child's integration → `main` PR.
   - It does **not** cover other sessions' PRs (#1454, #1455, #1448 …).
3. Landing gate for D (2026-09-30): *"Don't open the integration → main PR until pre-UAT on main
   is green after PR 1445 and the People docs PR has landed. Then open it and watch its CI and
   pre-UAT through to green. Continue autonomously through the phases."*
4. Latest (2026-09-30): *"Ok, check the current status and finish the full plan."* Continue
   autonomously through every child, respecting the landing slots.

**Asking the user:** use one line per question, and only for:

- approvals;
- #1454;
- anything that hits a hard stop (§8).

### 1.3 Approval windows

| Plan | Control issue | `approved_at` | `approved_until` |
|---|---|---|---|
| Roadmap `active-codebase-completion-e41f` | #1446 | 2026-09-29T22:39:00Z | 2026-10-01T22:39:00Z |
| D `active-codebase-batch-d-guardrails-e41f` | #1447 | 2026-09-29T22:39:00Z | 2026-10-01T22:39:00Z |
| E–K | — (drafts) | `null` | `null` |

- Agents never extend a window themselves.
- If D is not done before its window ends:
  1. run `node scripts/execute_plan_runtime.js halt active-codebase-batch-d-guardrails-e41f --reason session_limit --write`;
  2. record `next_action`;
  3. ask the user for `approve-autonomous active-codebase-batch-d-guardrails-e41f` on #1447;
  4. once approved, re-stamp, run `--fix-hash` and resume.
- **Every child from E on** starts after the roadmap window has ended. Before bootstrapping any
  of them, get a fresh `approve-autonomous active-codebase-completion-e41f` on #1446, then
  re-stamp the roadmap snapshot and run `--fix-hash`.
- Children bootstrapped inside a live roadmap window need no further approval (roadmap "How to
  run" §3).

## 2. First 15 minutes

```bash
cd <repo> && git fetch origin main cursor/active-codebase-d-integration-e41f claude/friendly-davinci-5zcxj2
git checkout cursor/active-codebase-d-integration-e41f && git pull
node scripts/validate_execute_plan_snapshot.js .agents/plans/active-codebase-completion-e41f.snapshot.json
node scripts/validate_execute_plan_snapshot.js .agents/plans/active-codebase-batch-d-guardrails-e41f.snapshot.json
# gate reads labels from the caller (no gh): #1446/#1447 carry execute-plan, autonomous-approved, plan:<id>
node scripts/execute_plan_runtime.js gate active-codebase-batch-d-guardrails-e41f --labels execute-plan,plan:active-codebase-batch-d-guardrails-e41f,autonomous-approved   # {"ok":true} while the window is open
node scripts/execute_plan_runtime.js roadmap-status active-codebase-completion-e41f
node scripts/check_feature_imports.js && node scripts/check_file_size.js
```

Then check on GitHub. There is no `gh` CLI here; use the GitHub MCP tools.

| What | How | Expect (at handover) |
|---|---|---|
| #1454 merged? | `pull_request_read get 1454` → `merged` | `false`, draft, `do-not-merge` |
| Latest pre-UAT on `main` | `actions_list list_workflow_runs pre-uat-e2e.yml` | run 562 on `238ca5f`: success |
| Open PRs into `main` | `list_pull_requests state=open base=main` | #1455 (TEST), #1454 (draft), #1448 (CARE, draft) |
| New comments on the control threads | `issue_read get_comments` on #1446, #1447, #1449, #1454 | nothing addressed to ARCH after 19:15Z |

Then §3.

## 3. Decision tree on every wake (check-in or event)

1. **Has #1454 merged?**
   - No → nothing to land.
     - Optional prep that stays inside ARCH's areas: rerun `pre-push`, and dry-run the merge
       (`git merge-tree --write-tree --name-only HEAD origin/claude/exciting-bardeen-hy6yzp`).
     - Re-arm the check-in (≈60 min, `send_later`). Don't message the user unless something
       changed.
   - Yes → go to 2.
2. **Is pre-UAT green on `main`'s latest merge SHA?**
   - If it's red and not caused by ARCH, don't pile on.
     - Comment once on the owning programme's thread.
     - Wait for the fix.
   - The D gate the user set is "pre-UAT green after #1445", and it is already met (run 562).
     The coordination rule, though, is **one landing at a time, each green before the next**. So
     D opens only after #1454's merge SHA has a green pre-UAT run.
3. **Is another programme's `main` landing in flight?**
   - A PR is in flight when it is merging now, or merged with its pre-UAT still running.
   - If so, wait for it; D goes next.
   - PEOPLE hotfixes (slot 0c) are disjoint from D and may land before or after it, never at the
     same time.
4. Run **§4 (Batch D phase 4)**.
5. After D is green:
   1. check which child's slot is open (§5);
   2. bootstrap it (§6), getting a fresh roadmap approval first (§1.3);
   3. if no slot is open, re-arm the check-in.

## 4. Batch D phase 4: exact procedure

### 4.1 Before opening the PR

```bash
git checkout cursor/active-codebase-d-integration-e41f && git pull
git fetch origin main && git merge origin/main        # our own branch: a merge commit is fine
node scripts/check_feature_imports.js                 # NEW/RESOLVED lines → fix, or --update-baseline (removal only)
node scripts/check_file_size.js
node --test scripts/check_feature_imports.test.js scripts/check_file_size.test.js scripts/check_coverage_threshold_consistency.test.js
./scripts/validate_docs.sh --strict
BOT=true ./scripts/pre-push.sh                        # env: §9
git push origin cursor/active-codebase-d-integration-e41f
```

**Known local failures on `main` that are not Batch D's:**

- frozen `flutter_app/test/features/organization/**` load errors;
- 8 `flutter_app/test/core/router/*` failures (tracked in #1453, fixed by TEST #1455).

Batch D changes no Dart code. CI is authoritative.

### 4.2 Open the PR

**Title:** `Batch D (ARCH): programme status, cross-feature import gate, D7 size report, coverage consistency`

**Body:** use this, following `.github/pull_request_template.md`. Update the SHAs.

```markdown
## Outcome

Architecture regressions are blocked before new feature code lands: the programme's real status is visible, new cross-feature imports fail CI, `server/lib` and `server/services` size is reported, and the documented Flutter coverage threshold matches the enforced 70%.

## Scope

Batch D of `active-codebase-completion-e41f` (control issues #1446, #1447), landing slot 1 in `docs/agent-efficiency/parallel-programmes.md`. Phase PRs merged into `cursor/active-codebase-d-integration-e41f`:

- #1450 D.1: Implementation status table in `docs/architecture/reviews/active-codebase-review.md`; baseline README and metrics refreshed.
- #1452 D.2: `scripts/check_feature_imports.js` (R1 domain→experience, R2 cross-feature data, R3 cross-feature presentation, R4 new feature edge; identity baseline that only shrinks; SCC report) with fixtures; wired into `pre-push.sh`, `pre-push-changed.sh` and the CI governance job. `pre-push-changed.sh` now uses the active Jest config.
- #1451 D.3: D7 report-only roots in `check_file_size.js`; coverage threshold consistency test (5 locations = 70%); `CONTRIBUTING.md` and `docs/quality/scorecard.md` say 70%.
- Plan files for the roadmap and children D–K; E–K aligned with the landing slots; `docs/architecture/modularity.md` §Cross-feature imports and §Feature ports and transport.

CI changes are additive steps in the governance job of `_reusable-test.yml` only (named on #1449 for TEST). No product code, no migrations, no wire change.

## Snags

- #1453 (Flutter test dirs no CI shard runs) → TEST #1455.
- People detail refetch loop (root cause of the shard 9 hang) → handed to PEOPLE on #1454 (fix on `cursor/preuat-fix-f04e19aa-e41f` @ `58ce7417`).

## Checklist
(copy the template checklist; tick One outcome, Snags, Synced; mark server/Flutter/codegen/routes/widgets/API/5xx/a11y/BDD rows N/A — no product code)

## Test plan

- `node scripts/check_feature_imports.js`: OK (R1=56 R2=6 R3=201, 59 edges); fixtures 11/11.
- `node --test scripts/check_file_size.test.js scripts/check_coverage_threshold_consistency.test.js`: pass.
- `./scripts/validate_docs.sh --strict`: 0 errors. All execute-plan snapshots validate.
- `./scripts/pre-push.sh`: passed on `c81b09ec` (rerun after the final `main` merge and update this line).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

Then:

1. `subscribe_pr_activity` on the new PR.
2. Wait for `ci.yml` to go green. The governance job now runs the four new D steps.
3. Fix red CI per the repo's babysit rules:
   - root-cause every failure;
   - never skip or quarantine a test;
   - never push an empty commit.

### 4.3 Merge and watch

1. **Squash-merge** with `merge_pull_request`, `merge_method: squash`, and `expectedHeadSha`
   set to the PR head.
2. Watch pre-UAT on the merge SHA: `actions_list list_workflow_runs pre-uat-e2e.yml`, filtered
   on `head_sha`. A run takes about 12 min and has 9 shards.
   - `scripts/babysit_uat_watch_preuat.sh` needs the `gh` CLI, which this environment lacks. Poll
     with the MCP tools instead (a `send_later` of about 15 min, not `sleep`).
3. If pre-UAT is red:
   1. diagnose from the job logs (`get_job_logs`);
   2. reproduce locally (§9.2);
   3. open a remedial PR into `main`, merge it and watch again.
   D is done **only** when pre-UAT is green.

### 4.4 Close D

```bash
# on a small branch off main (plan-files only), or as the first commit of E's integration branch
node scripts/execute_plan_runtime.js set-phase active-codebase-batch-d-guardrails-e41f --phase 4 --status merged --pr-url <PR url> --pr-head <head sha> --write
# set merge_commit for phase 4 in the snapshot, then:
node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/active-codebase-batch-d-guardrails-e41f.snapshot.json
node scripts/execute_plan_runtime.js complete-plan active-codebase-batch-d-guardrails-e41f --write --skip-close
node scripts/execute_plan_runtime.js roadmap-set-child active-codebase-completion-e41f --child active-codebase-batch-d-guardrails-e41f --status merged --pr-url <PR url> --merge-commit <merge sha> --write
```

1. Close #1447 with `issue_write` (`state: closed`, `state_reason: completed`) and a summary
   comment.
2. **Landing broadcast** (coordination doc §5.2). Post one short comment on each of #1448
   (CARE), #1449 (TEST), #1455 (TEST 1a), and #1454 or PEOPLE's control issue once it exists:

   ```
   Landed: ARCH D @ <merge sha> (PR #<n>) · Areas: CI governance (additive steps in _reusable-test.yml), scripts/check_feature_imports*, docs, plan files · Migrations: none · Next ARCH landing: E (slot 3a, after CARE A+B)
   ```

   End every GitHub comment with the attribution footer:

   ```

   ---
   _Generated by [Claude Code](https://claude.ai/code)_
   ```
3. Update the review doc's Implementation status rows for Package 1, Package 9 (gate) and
   Package 11 (D7/D23) in `docs/architecture/reviews/active-codebase-review.md`. It can go in
   the same plan-bookkeeping PR.

## 5. Children E–K: when each opens

The landing order belongs to `docs/agent-efficiency/parallel-programmes.md` §4 (it arrives with
#1454; until then it is on branch `claude/exciting-bardeen-hy6yzp`). The roadmap's "Cross-programme
landing slots" table and each child's **Entry gate** section restate it. Rules:

- one landing on `main` at a time;
- pre-UAT green after each landing;
- a broadcast after each landing;
- migrations are named in plans and numbered when the landing PR opens (CARE keeps `083`);
- don't edit another in-flight programme's area.

| Child | Slot | Opens after (merged on `main`, pre-UAT green) | Things to redo at bootstrap |
|---|---|---|---|
| E `…batch-e-backend-integrity-e41f` | 3a | CARE A+B (`care-next-occurrence-c1a7`, #1448) | Re-read `server/lib/care/**` and `server/routes/healthEntries/**` (D12 targets CARE's new engine). `peopleRelationshipsRouter.js` is PEOPLE's, not E's. |
| F `…batch-f-account-erasure-e41f` | 5a | ARCH E and PEOPLE server (`people-server-7f3b`) | F.1 inventory must include the People tables listed in the plan. |
| G `…batch-g-client-authority-e41f` | 7 | CARE E+F | Re-baseline Package 8 (health store, `CareScheduleController`) against CARE F; G.2 and G.3 may shrink. |
| H `…batch-h-ports-transport-e41f` | 9 | PEOPLE client integration (`people-client-integration-7f3b`) | Re-list `auth/data` importers and the health presentation → data files (H.1-2, H.2-3), and update `allowed_paths` before stamping. |
| I1 `…batch-i1-public-apis-e41f` | 10 | ARCH H | — |
| I2 `…batch-i2-acyclic-graph-e41f` | 10, after I1 | ARCH I1 | — |
| J `…batch-j-standards-e41f` | 11 | TEST slice 2 (`test-health-ci-5f3a` phases 4, 6, 7) | Reuse TEST's KPI generator and shard manifest (#1455); drop whatever TEST already enforces. |
| K `…batch-k-final-acceptance-e41f` | 12 | everything else | — |

Development may start before a slot opens, on the child's own branches. Only the
integration → `main` PR waits for the slot. In practice, bootstrap a child when the landing
before it is close.

## 6. Bootstrapping a child (E onwards)

The roadmap's "How to run" §3 has the canonical steps. In this environment:

1. **Approval:** fresh `approve-autonomous active-codebase-completion-e41f` on #1446 if the
   roadmap window has passed (§1.3). Stamp the roadmap snapshot and run `--fix-hash`.
2. **Integration branch:**
   ```bash
   CHILD=$(node scripts/execute_plan_runtime.js roadmap-next-child active-codebase-completion-e41f)
   git fetch origin main && git push origin origin/main:refs/heads/cursor/active-codebase-<x>-integration-e41f
   ```
3. **Control issue:** run `node scripts/execute_plan_runtime.js init-control-issue "$CHILD"`. It
   renders a `gh issue create` command; create the issue with `issue_write` instead, using the
   same title and body. Give it the labels `execute-plan`, `autonomous-approved` and
   `plan:$CHILD`, as on #1447; `gate` checks them.
4. **Stamp the child snapshot:**
   - `control_issue` = the new issue;
   - `approved_at` = now (UTC);
   - `approved_until` = now + 48h;
   - `approved_by` = `standing grant — roadmap active-codebase-completion-e41f (#1446)`.

   Then run:
   ```bash
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/$CHILD.snapshot.json
   node scripts/execute_plan_runtime.js gate "$CHILD" --labels execute-plan,plan:$CHILD,autonomous-approved
   node scripts/execute_plan_runtime.js roadmap-set-child active-codebase-completion-e41f --child "$CHILD" --status in_progress --write
   ```
5. **Phases:**
   - each phase gets its own branch (the snapshot's `branch`) and one PR into the integration
     branch;
   - squash merge;
   - commit messages follow `phase(<id>/<total>): <type>: <description>`;
   - stay inside `allowed_paths` plus the allowed exceptions, or halt on drift;
   - update the runtime with `set-phase … --status merged --pr-url … --pr-head … --write`, set
     `merge_commit`, then run `--fix-hash` and `sync-runtime --write`.
6. **Last phase:** follow §4 with the child's names.

**If you edit a draft child `.md`'s phase blocks, regenerate its draft snapshot.** The script
resolves the repo from its own location, and the current child `.md` files live on the
integration branch (the copies on `claude/friendly-davinci-5zcxj2` are the older drafts). So run
it from an untracked copy inside the integration checkout:

```bash
git show origin/claude/friendly-davinci-5zcxj2:.agents/plans/active-codebase-completion-e41f.gen_snapshots.py > .agents/plans/gen.py
python3 .agents/plans/gen.py /tmp/snapout && rm .agents/plans/gen.py
cp /tmp/snapout/<changed draft child>.snapshot.json .agents/plans/
```

The script resets approval fields to `null`. **Never** copy its roadmap, D or any other stamped
child's output over the files in `.agents/plans/`. It was verified to reproduce the committed E–K
drafts byte for byte at `c81b09ec`.

## 7. Open side items (not ARCH's to land; keep an eye on them)

| Item | State | Owner / action |
|---|---|---|
| People detail refetch loop (B1): the People edit screen hangs forever | Fix plus regression test on `cursor/preuat-fix-f04e19aa-e41f` @ `58ce7417`; commit `5c2a1e1d` there is obsolete (conflicts with #1458) | PEOPLE hotfixes (slot 0c). Handed over on #1454 (comment 5917987327). Don't open a PR for it: `features/people/**` is PEOPLE-owned. |
| #1458's test-side workaround (persists the vet edit via API) | On `main` | PEOPLE should revert it with the fix, so E2E exercises the real form. |
| Contact coordinates rendered as `SelectableText` never reach the DOM or accessibility tree | Reported on #1454 | PEOPLE client (`Semantics` on `_CoordinateRow`). |
| #1453 unscheduled Flutter test dirs | Covered by TEST #1455 | TEST. J builds on it. |
| `pre-push*.sh` Flutter version check breaks as root | Workaround `BOT=true` | TEST follow-up on #1449. |

## 8. Hard stops (halt even with the grant)

From the roadmap:

- A migration beyond the three tables in D9(a), or any change to an existing table.
- A response change for installed clients that is not additive or compatible. D13, D14, D16 and
  D22 are the only exceptions.
- Deleting, skipping or quarantining a test, or lowering a threshold, to get green.
- F.1 finds personal data that would survive erasure with no lawful-retention reason, and the fix
  lies outside F's paths. Halt with `halt --reason governance_approval_required`.
- Frozen internals changed beyond what a phase lists.

Also:

- Never merge another programme's PR.
- Never extend an approval window.
- Never force-push someone else's branch.
- Never put a model identifier in commits or PRs.

Commit trailers used so far (replace with your own session's):

```
Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01YUBDQf93z9AFgmhDkvGh3g
```

## 9. Environment

### 9.1 Toolchain (cloud container)

```bash
source scripts/flutter-sdk.sh && agatha_flutter_use        # Flutter 3.44.0 → ~/.cache/agatha-track
chown -R root:root ~/.cache/agatha-track/flutter-3.44.0-linux   # "dubious ownership" fix
export BOT=true PATH=$HOME/.cache/agatha-track/flutter-3.44.0-linux/bin:$PATH   # root banner breaks the version check otherwise
apt-get install -y shellcheck
(cd server && npm ci)                                      # docs validation needs js-yaml
(cd flutter_app && flutter pub get && dart run build_runner build --delete-conflicting-outputs)   # mocks are not committed
pg_ctlcluster 16 main start
su postgres -c "psql -c \"CREATE ROLE \\\"user\\\" LOGIN SUPERUSER PASSWORD 'password'\""   # if missing
su postgres -c "createdb -O user agatha_db"                                                   # if missing
PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db ./e2e/scripts/bootstrap-db.sh
```

### 9.2 Local E2E

```bash
(cd flutter_app && flutter build web --release --no-tree-shake-icons --no-web-resources-cdn)   # no CDN: the test browser can't reach it
(cd server && PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db E2E=1 nohup node bin/start.js > /tmp/server.log 2>&1 &)
(cd e2e && npm ci)
cd e2e && E2E_BASE_URL=http://localhost:3000 npx playwright test -c playwright.local-chromium.config.ts --project=full playwright/tests/<spec> --reporter=line
```

- Don't run `playwright install`: `e2e/` pins a Chromium the container doesn't have.
- Instead, create an untracked `e2e/playwright.local-chromium.config.ts` and add it to
  `.git/info/exclude`:

```ts
import base from './playwright.config';
const executablePath = '/opt/pw-browsers/chromium-1194/chrome-linux/chrome';
const withChrome = (use: Record<string, unknown> = {}) => ({
  ...use,
  launchOptions: { ...((use.launchOptions as object) ?? {}), executablePath },
});
export default {
  ...base,
  use: withChrome(base.use as Record<string, unknown>),
  projects: (base.projects ?? []).map((p) => ({ ...p, use: withChrome(p.use as Record<string, unknown>) })),
};
```

- The container can restart when a session reconnects. If requests fail with `fetch failed`,
  restart Postgres and the server.
- Don't `pkill node` broadly: it kills your own shell.

### 9.3 Facts worth knowing

- **CI coverage by branch:**
  - `ci.yml` runs only on PRs into `main`.
  - PRs into integration branches get only docs validation, workflow lint and governance hints,
    until TEST slice 1 adds a CI tier for them.
  - Pre-UAT (`pre-uat-e2e.yml`, 9 shards) runs only on push to `main`.
- **No `gh` CLI:**
  - `execute_plan_runtime.js` and `babysit_*.sh` print or run `gh` commands; do the same through
    the GitHub MCP tools.
  - `complete-plan --skip-close` avoids its `gh issue close`.
- **Reviews:** Copilot review is unavailable (quota exhausted). Do a careful self-review of the
  diff before each merge.
- **Riverpod:** a `FutureProvider` that watches a derived provider and mutates its source loops
  forever unless the entities have value equality (see B1). The convention in
  `docs/architecture/modularity.md` §Feature ports and transport now forbids it.
- **Snapshot generator:** `.agents/plans/active-codebase-completion-e41f.gen_snapshots.py` on
  `claude/friendly-davinci-5zcxj2`. It parses the child `.md` files and outputs drafts with null
  approval fields. See §6 for how to run it.

## 10. Reference: what exists

### Branches

| Branch | Head | Purpose |
|---|---|---|
| `cursor/active-codebase-d-integration-e41f` | `c81b09ec` | Batch D integration (all plan files live here until D lands) |
| `claude/friendly-davinci-5zcxj2` | this commit | Original plan drafts (`bea86c96`), this handover, and the generator |
| `cursor/preuat-fix-f04e19aa-e41f` | `5c2a1e1d` | People detail loop fix `58ce7417` for PEOPLE (don't PR it) |
| `claude/exciting-bardeen-hy6yzp` | `4b03093a` | #1454 (PEOPLE docs + coordination doc), another session's |

### Integration-branch commits since `main` (`238ca5f`)

| Commit | What |
|---|---|
| `6f7a59b6` | phase 1 (#1450; PR head `20330e6b`) |
| `0232029e` | phase 2 (#1452; PR head `04b6fc0d`) |
| `d7a77fde` | phase 3 (#1451; PR head `87309202`) |
| `3be676ee` | merge of `main` @ `238ca5f` |
| `1d5c3de1` | D runtime bookkeeping (phases 1–3 `merged`, phase 4 `in_progress`) |
| `c81b09ec` | E–K entry gates, roadmap slot table, H convention in `modularity.md`, H.1-2/H.2-3 fixed, E/H draft snapshots regenerated |

### Issues and PRs

| Number | What |
|---|---|
| #1446 | Roadmap control issue |
| #1447 | Batch D control issue |
| #1448 | CARE programme (draft PR, `care-next-occurrence-c1a7`) |
| #1449 | TEST control issue. ARCH D's added CI steps are named there (comment 5917988876). |
| #1453 | Debt: unscheduled Flutter test dirs → #1455 |
| #1454 | PEOPLE docs + coordination doc (draft, `do-not-merge`; slot 0b) |
| #1455 | TEST 1a (slot 2a, lands after D) |
| #1458 | Test-side workaround that made pre-UAT green (run 562) |

## 11. Verification log

- **People vet specs** on `cursor/preuat-fix-f04e19aa-e41f`, locally: 22 passed, 1 skipped
  (shard 9 plus the People hub specs). Before the provider fix the edit form hung.
- **Integration branch @ `c81b09ec`:**
  - `validate_docs.sh --strict`: 0 errors;
  - import gate OK (R1=56 R2=6 R3=201, 59 edges);
  - size gate OK;
  - roadmap and D snapshots valid;
  - E–K drafts valid with placeholder approvals;
  - dry-run merge with #1454's head: clean.
- **Full `BOT=true ./scripts/pre-push.sh` on `c81b09ec`:** passed (exit 0, "✓ Full pre-push
  passed"). This covers the governance, Jest, analyze, Flutter shard tests and format checks.
  The #1453 directories (`test/core/**` …) are not in any shard yet, so the known router
  failures don't show up here. Rerun it after merging `main` again (§4.1).

---
title: Handoff — active-codebase-completion-e41f (architecture programme, Batches D–K)
owner: Agent
audience: agent
status: active
last_updated: 2026-09-30
---

# Handoff: architecture programme `active-codebase-completion-e41f`

Written 2026-09-30 by the Claude Code session that started the programme
(session `session_01YUBDQf93z9AFgmhDkvGh3g`). Everything below is what a new agent needs
to continue without re-deriving context. Read it top to bottom once; §4 and §5 are the
next actions.

## 1. What the programme is

- **Charter:** `docs/architecture/reviews/active-codebase-review.md` (accepted review; Packages
  1–12; decisions D1–D7). Batches A–C shipped earlier (PRs #1282–#1319).
- **Roadmap parent plan:** `.agents/plans/active-codebase-completion-e41f.md` + `.snapshot.json`.
  It adds decisions **D8–D23** (accepted by the user with the grant) and chains nine child
  execute-plans:

  | Order | Child plan (`.agents/plans/<id>.md`) | Packages |
  |---|---|---|
  | 1 | `active-codebase-batch-d-guardrails-e41f` | 1, 9 (D6 gate), 11 (D7, D23) |
  | 2 | `active-codebase-batch-e-backend-integrity-e41f` | 3, 4, 6 |
  | 3 | `active-codebase-batch-f-account-erasure-e41f` | 5 |
  | 4 | `active-codebase-batch-g-client-authority-e41f` | 7, 8 |
  | 5 | `active-codebase-batch-h-ports-transport-e41f` | 10 |
  | 6 | `active-codebase-batch-i1-public-apis-e41f` | 9 (entrypoints) |
  | 7 | `active-codebase-batch-i2-acyclic-graph-e41f` | 9 (acyclic graph) |
  | 8 | `active-codebase-batch-j-standards-e41f` | 11 |
  | 9 | `active-codebase-batch-k-final-acceptance-e41f` | 12 |

- **Where the plan files live:** on `cursor/active-codebase-d-integration-e41f` (they land on
  `main` with Batch D). A copy of the original drafts is on `claude/friendly-davinci-5zcxj2`
  (commit `bea86c96`). Child snapshots other than D are **drafts**: `control_issue`,
  `approved_at`, `approved_until`, `content_hash` are `null` until each child is bootstrapped
  (see the roadmap's "How to run").
- **Snapshot generator:** the drafts were generated from the child `.md` files. If you edit a
  child `.md` phase block (allowed_paths etc.), regenerate that snapshot consistently and run
  `node scripts/validate_execute_plan_snapshot.js --fix-hash <file>` after stamping.

## 2. User instructions and authority (verbatim where it matters)

1. Initial grant (2026-09-29): *"That's fine, go ahead, and let me know exactly what to do if
   you need me."* Recorded as the standing grant on roadmap #1446.
2. Merge authority (2026-09-30): *"When in a plan under "execute-plan" you always have the full
   confirmation to merge yourself."* Before this, the Claude Code auto-mode safety check blocked
   merging without review ("Merge Without Review"). Copilot review is unavailable (account
   quota exhausted), so there is no automated reviewer.
3. Landing gate for Batch D (2026-09-30): *"Finish phase 4/4. Don't open the integration → main
   PR until pre-UAT on main is green after PR 1445 and the People docs PR has landed. Then open
   it and watch its CI and pre-UAT through to green. Continue autonomously through the phases."*
4. The user then asked for this handoff and to **stop** once it was written.
5. Then (2026-09-30): *"Ok, check the current status and finish the full plan"*: resume
   autonomously through every child, respecting the gates above.

## 3. State (updated 2026-09-30, after the user's "check the current status and finish the full plan")

### Batch D (`active-codebase-batch-d-guardrails-e41f`, control issue #1447)

| Phase | PR | State |
|---|---|---|
| 1 Programme status + baseline refresh | #1450 | merged into integration (`6f7a59b`) |
| 2 Cross-feature import gate (D6) | #1452 | merged into integration (`0232029`) |
| 3 D7 size report + D23 coverage consistency | #1451 | merged into integration (`d7a77fd`) |
| 4 Integration → `main` + pre-UAT | — | **not opened**: waits for #1454 (slot 0b), see §4 |

- Integration branch `cursor/active-codebase-d-integration-e41f` @ `c81b09ec` (pushed):
  - `3be676ee` merges `main` @ `238ca5f` (clean);
  - `1d5c3de1` records runtime bookkeeping (phases 1–3 `merged` with merge commits, phase 4
    `in_progress`, hash refreshed, `gate` OK);
  - `c81b09ec` aligns children E–K with the coordination doc (§6 below) and publishes the H
    convention in `docs/architecture/modularity.md` §Feature ports and transport.
- A dry-run merge of #1454's head (`4b03093a`) into the integration branch is clean.
- Approval windows: roadmap and D stamped `2026-09-29T22:39:00Z` → `approved_until`
  `2026-10-01T22:39:00Z`. If D is not done by then, halt with `session_limit` and ask the user
  to re-approve (`approve-autonomous <plan_id>`); agents never extend a window themselves.
  Every later child (E–K) needs a fresh approval at its bootstrap, since its slot opens after
  this window.

### `main` and the other programmes

- Pre-UAT is **green on `main` @ `238ca5f`** (run 562, after #1458), so slot 0a is closed.
- #1458 (another agent) made shard 9 green with a **test-side** workaround: it persists the vet
  phone edit via the API when the People edit form hangs.
- The **app bug** behind the hang is the `peopleContactDetailProvider` refetch loop (B1 in the
  People refactor plan). Its fix is on branch `cursor/preuat-fix-f04e19aa-e41f` @ `58ce7417`,
  with a regression test. It was handed to PEOPLE on #1454 (comment 5917987327) to take into
  `people-hotfixes-7f3b` (slot 0c). No PR was opened: `features/people/**` is PEOPLE-owned. The
  branch's page-object commit `5c2a1e1d` conflicts with #1458 and is obsolete.
- Open programme PRs:
  - #1454 PEOPLE docs (slot 0b): **draft + `do-not-merge`**, another session's PR;
  - #1455 TEST 1a (slot 2a, lands after D);
  - #1448 CARE (draft; A+B is slot 2b, after D).
- D's added CI steps were named on TEST's #1449 (comment 5917988876), so §6 item 1 of the
  coordination doc is done.

### Other artifacts created

- Roadmap control issue **#1446**; Batch D control issue **#1447**.
- Debt issue **#1453** (unscheduled Flutter test dirs) is covered by TEST **#1455**; Batch J's
  entry gate says to build on it.

## 4. Blocker: #1454 has to land first

The user's gate for opening the D → `main` PR: *pre-UAT green on `main` after #1445* (done) **and**
*the People docs PR has landed* (#1454, not yet). It is a draft labelled `do-not-merge`, owned by
another session. Do not merge it yourself; the user or its owning session lands it. Check with
`mcp__github__pull_request_read get 1454` (look for `merged: true`).

## 5. Batch D phase 4: exact procedure once #1454 has merged

1. `git fetch origin main`; merge `main` into `cursor/active-codebase-d-integration-e41f` (our
   own branch, so a merge commit is fine). Re-run `node scripts/check_feature_imports.js`. If
   the new landings changed Dart imports, the check fails with `NEW`/`RESOLVED` lines: fix them,
   or run `--update-baseline` (it only removes).
2. Coordination rule §5.1: check that no other programme's `main` PR is ahead of ARCH D. 0c
   (PEOPLE hotfixes) is disjoint from D and may land in either order, but only one landing at a
   time, each followed by pre-UAT green.
3. Run `./scripts/pre-push.sh` (with `BOT=true`; §7). Known local failures that are not Batch
   D's (D changes no Dart code): frozen `test/features/organization/**` load errors and the 8
   `test/core/router/*` failures (#1453). CI is authoritative.
4. Open the PR `cursor/active-codebase-d-integration-e41f` → `main` using
   `.github/pull_request_template.md`. List the D.1–D.3 outcomes, #1450/#1452/#1451, and the
   plan edits from `c81b09ec`. Subscribe to it and wait for `ci.yml` to go green.
5. Squash-merge (the user granted merge authority inside execute-plan). Watch `pre-uat-e2e.yml`
   on the merge SHA (it runs on push to `main`, about 12 min). If it fails, diagnose, open a
   remedial PR and watch again. D is done only when pre-UAT is green.
6. On a small follow-up branch into `main`, or folded into E's first phase, run:
   - `node scripts/execute_plan_runtime.js complete-plan active-codebase-batch-d-guardrails-e41f --write`,
     then close #1447 with the MCP tools (no `gh`);
   - `roadmap-set-child active-codebase-completion-e41f --child active-codebase-batch-d-guardrails-e41f --status merged --pr-url <url> --merge-commit <sha> --write`.
7. Post the landing broadcast (§5.2) on #1448, #1449, #1454 (or PEOPLE's control issue once it
   exists) and #1455:
   `Landed: ARCH D @ <sha> (PR #n) · Areas: CI governance (additive steps in _reusable-test.yml), docs, plan files · Migrations: none`.
8. Update the review doc's Implementation status rows (Packages 1, 9 gate, 11 D7/D23).

## 6. Children E–K: plan changes applied, and when each opens

Applied in `c81b09ec`. Each child `.md` has an **Entry gate** section; the roadmap maps the slots.

| Child | Slot | Bootstrap / land after | Notes |
|---|---|---|---|
| E | 3a | CARE A+B (2b) | `peopleRelationshipsRouter.js` removed from E paths (PEOPLE s3 owns it). Re-read care engine before D12. Migrations numbered at landing. |
| F | 5a | ARCH E (3a) and PEOPLE server (4) | F.1 inventory includes the People tables. |
| G | 7 | CARE E+F (5b) | Re-baseline Package 8 against CARE F first. |
| H | 9 | PEOPLE client integration (8) | Convention published early in modularity.md. H.1-2/H.2-3 now match their `allowed_paths`; wiring lives in `application/`. |
| I1 | 10 | H | |
| I2 | 10, after I1 | I1 | |
| J | 11 | TEST slice 2 (6) | Reuse TEST's KPI generator and #1455 shard manifest. |
| K | 12 | everything else | |

Bootstrapping a child means:

1. create its integration branch from `main`;
2. create its control issue (`init-control-issue`; perform the rendered `gh` calls with the MCP tools);
3. stamp `approved_at`/`approved_until` (+48h) and `control_issue` in its snapshot, after a fresh
   user approval;
4. run `validate_execute_plan_snapshot.js --fix-hash`, `gate`, and `roadmap-set-child … --status in_progress`.

The draft snapshots for E–K validate with placeholder approval values. The scratchpad generator
overwrites approval fields: use it only on unstamped drafts.

## 7. Cloud container setup (what worked in this session)

```bash
# Flutter 3.44.0 (sourced by pre-push scripts); fix ownership once, and set BOT=true so the
# "running as root" banner does not break the version check.
source scripts/flutter-sdk.sh && agatha_flutter_use     # downloads to ~/.cache/agatha-track
chown -R root:root ~/.cache/agatha-track/flutter-3.44.0-linux
export BOT=true PATH=$HOME/.cache/agatha-track/flutter-3.44.0-linux/bin:$PATH
apt-get install -y shellcheck                           # needed by pre-push scripts
(cd server && npm ci)                                   # also needed by docs validation (js-yaml)
(cd flutter_app && flutter pub get && dart run build_runner build --delete-conflicting-outputs)

# Postgres (dev defaults from AGENTS.md)
pg_ctlcluster 16 main start
su postgres -c "psql -c \"CREATE ROLE \\\"user\\\" LOGIN SUPERUSER PASSWORD 'password'\""
su postgres -c "createdb -O user agatha_db"
PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db ./e2e/scripts/bootstrap-db.sh

# Local E2E (Flutter web must not use the CanvasKit CDN: the test browser has no route to it)
(cd flutter_app && flutter build web --release --no-tree-shake-icons --no-web-resources-cdn)
(cd server && PGUSER=user PGPASSWORD=password PGHOST=localhost PGPORT=5432 PGDATABASE=agatha_db E2E=1 nohup node bin/start.js > /tmp/server.log 2>&1 &)
(cd e2e && npm ci)
```

Playwright in `e2e/` pins a newer Chromium than the preinstalled one; do **not** run
`playwright install`. Use an untracked local config (keep it out of git, e.g. via
`.git/info/exclude`):

```ts
// e2e/playwright.local-chromium.config.ts (local only)
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

Run a spec: `cd e2e && E2E_BASE_URL=http://localhost:3000 npx playwright test -c playwright.local-chromium.config.ts --project=full playwright/tests/veterinarian.spec.ts --reporter=line`.
The container can restart when the session reconnects; if requests fail with `fetch failed`,
restart Postgres and the server.

Other facts worth knowing:

- `ci.yml` runs only for PRs into `main`; phase PRs into integration branches get only docs
  validation, workflow lint and governance hints. Pre-UAT (9 Playwright shards) runs only on
  push to `main`.
- `scripts/pre-push-changed.sh` now uses `server/jest.config.active.cjs` (fixed in D.2).
- GitHub access is via the GitHub MCP tools (no `gh` CLI). `execute_plan_runtime.js` renders
  `gh` commands; perform them with the MCP tools instead.

## 8. Local verification (2026-09-30)

- People vet specs on `cursor/preuat-fix-f04e19aa-e41f`: 22 passed, 1 skipped (shard 9 + People hub).
- Integration branch @ `c81b09ec`: `validate_docs.sh --strict` 0 errors; import gate OK;
  size gate OK; all snapshots valid. The full `./scripts/pre-push.sh` result is appended below
  once it finishes.

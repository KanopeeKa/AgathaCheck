---
title: Active codebase completion roadmap (Batches D–K)
owner: Agent
audience: both
status: proposed
last_updated: 2026-09-29
tags: [architecture, execute-plan, roadmap, pet-care]
---

# active-codebase-completion-e41f

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `active-codebase-completion-e41f` |
| **title** | Finish the accepted active-codebase architecture programme (Packages 1–12) |
| **plan_kind** | `roadmap` (parent orchestrator; one standing grant chains the child plans below) |
| **programme_ref** | [`docs/architecture/reviews/active-codebase-review.md`](../../docs/architecture/reviews/active-codebase-review.md) |
| **created** | 2026-09-29 |
| **status baseline** | `main` @ `0cc739e` (2026-09-29) |
| **base_branch** | `main` (each child plan owns its own integration branch) |
| **default_merge_mode** | `auto` |
| **artifact_branch_policy** | `phase-branch` |

## Goal

Batches A, B and C of the accepted architecture review shipped (PRs #1282–#1319). Their plans were marked complete, but each one covered only the core step of its package. The review's exit gates for Packages 3, 4, 7 and 8 are still open, and Packages 5 and 9–12 have not started. The coupling Package 9 targets has also **regressed**: cross-feature edges went from 50 to 59, import directives from 466 to 536, and the import cycle from 12 to 13 features. This roadmap closes every remaining gap through **nine child execute-plans** (Batches D–K). Each child is small enough for one 48-hour approval window. Each child runs on its own **integration branch**: phase PRs merge into it through `/babysit-plus`, then one integration → `main` PR merges through `/babysit-uat` and must end with **pre-UAT E2E green** on the merge SHA.

The architecture decisions D1–D7 recorded in the review remain binding. This roadmap adds decisions **D8–D23** (below), which the approval grant accepts.

## How to run

1. **Create the roadmap control issue:** `node scripts/execute_plan_runtime.js init-control-issue active-codebase-completion-e41f`, then run the rendered `gh issue create` command and put the issue number in the snapshot's `control_issue`.
2. **Approve (human):** comment `approve-autonomous active-codebase-completion-e41f` on that issue, after editing the D8–D23 table if needed. That comment is the standing grant for every child plan below and for decisions D8–D23.
   ```bash
   # orchestrator: stamp the grant, freeze and gate
   # set approved_at (now, UTC), approved_until (+48h), approved_by ("approve-autonomous on #<issue>")
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/active-codebase-completion-e41f.snapshot.json
   node scripts/execute_plan_runtime.js gate active-codebase-completion-e41f --labels execute-plan,plan:active-codebase-completion-e41f,autonomous-approved
   ```
3. **Bootstrap each child when it starts** (roadmap chaining; no new human approval needed). The child snapshots are pre-authored but **draft**: `control_issue`, `approved_at`, `approved_until` and `content_hash` stay `null` until the child starts.
   ```bash
   CHILD=$(node scripts/execute_plan_runtime.js roadmap-next-child active-codebase-completion-e41f)
   git fetch origin main && git push origin origin/main:refs/heads/<child integration branch>   # create integration branch from main
   node scripts/execute_plan_runtime.js init-control-issue "$CHILD"                              # run the rendered gh command
   # fill control_issue / approved_at / approved_until (+48h) / approved_by ("standing grant — roadmap active-codebase-completion-e41f")
   node scripts/validate_execute_plan_snapshot.js --fix-hash .agents/plans/$CHILD.snapshot.json
   node scripts/execute_plan_runtime.js roadmap-set-child active-codebase-completion-e41f --child "$CHILD" --status in_progress --write
   ```
   Then run `/execute-plan $CHILD`.
4. **Close each child:** after pre-UAT is green, run `complete-plan <child> --write`, then `roadmap-set-child active-codebase-completion-e41f --child <child> --status merged --pr-url <integration→main PR> --merge-commit <sha> --write`, and loop to the next child in the same session.
5. **Close the roadmap:** when `roadmap-status` reports `complete: true`, run `complete-plan active-codebase-completion-e41f --write`.

If a child cannot finish inside its 48h window, halt with `session_limit` before `approved_until` passes and record `next_action`. The human re-approves on the child control issue (`approve-autonomous <child>`); the orchestrator then re-stamps `approved_at`/`approved_until`, re-runs `--fix-hash`, and resumes with `/execute-plan <child> resume`. Agents never extend an expired window themselves. The same applies to the roadmap: the whole programme will take longer than one 48h window, so when the roadmap's `approved_until` passes, the next child bootstrap waits for a fresh `approve-autonomous active-codebase-completion-e41f` on the roadmap issue. Do not widen the child's scope to catch up. The roadmap CLI commands (`roadmap-status`, `roadmap-next-child`) only work after step 2, because they validate the stamped snapshot.

## Starting point (status at `0cc739e`, 2026-09-29)

| Pkg | Status | Landed | Open (owning child → phase) |
|---|---|---|---|
| 1 Baseline | Done | #1282 | Baseline README rows are stale → **D.1** |
| 2 Frozen boundary | Done | #1283, #1284 | None. Org-transfer and family-event writes return a JSON 404 when frozen mode is off, which is equivalent to not being mounted. Recorded in **D.1**. |
| 3 Transactions + pet delete | Partial | #1295, #1296 | No `cleanup_jobs` → **E.1**. `files_removed` counts scheduled files, not deleted ones; the audit write is not awaited on the transaction client (an aborted transaction can turn COMMIT into a silent ROLLBACK); `DELETE /pets/:id` deletes the pet row outside the data transaction → **E.2**. About 20 hand-written `BEGIN` blocks and 3 copies of `withOptionalTransaction` with a pool fallback → **E.3**, **E.4** |
| 4 Stable command results | Partial | #1297 | Invite code retry runs inside an aborted transaction; no invite replay or concurrency control; notifications are written after commit; weight establishment and cache refresh fail silently after commit → **E.4** |
| 5 Account erasure | Not started | — | Everything → **F.1–F.4** |
| 6 Passed-away DTO | Done (core) | #1299 | A repeat POST notifies everyone again; `api-reference.md` still lists the endpoint as a "lifecycle stub" → **E.2** |
| 7 Pet cache (D2) | Mostly | #1309, #1319 | No freshness limit; `fetchedAt` on cached results is set to `now()`; pet detail screen not migrated → **G.1**, **G.4** |
| 8 Canonical health store | Partial | #1315 | No `CareScheduleController` (15 direct repository calls in 10 widget files); `refresh()` wipes the store on failure; no guard against out-of-order responses → **G.2**, **G.3** |
| 9 Public APIs / cycles | Not started, **regressed** | — | D6 block-new gate → **D.2**. Public entrypoints and edge removal → **I1**. Acyclic graph → **I2** |
| 10 Ports / transport | Not started | — | **H.1–H.4** |
| 11 Measurable standards | Not started | — | D7 report plus coverage threshold consistency → **D.3**. Remainder → **J** |
| 12 Extractions / final | Not started | — | **K** |

## Decisions accepted with the grant (D8–D23)

Approving this roadmap accepts every **recommended** option below. To change one, edit this table **before** approval. After approval, a change means a new snapshot and a new approval.

| # | Decision | Accepted option | Used by |
|---|---|---|---|
| D8 | Programme shape | Roadmap parent plus 9 child plans (D, E, F, G, H, I1, I2, J, K). Each has its own integration branch and its own pre-UAT gate. One standing grant covers all of them. | all |
| D9 | Pre-approved escalations (otherwise "always halt") | **(a) Migrations:** only three new additive tables: `cleanup_jobs`, `pet_lifecycle_notifications`, `account_erasure_operations`. No changes to existing tables, columns or data. **(b) CI:** only add or modify named steps in `.github/workflows/_reusable-test.yml` and `.github/workflows/_reusable-flutter-coverage.yml`; no removed or weakened gates. **(c) Wire changes:** only the additive or compatible ones in D13, D14, D16, D17 and D22. **(d) Security-sensitive work** (F, H.4) is pre-approved as designed here, but each PR must apply `.cursor/agent-kernel/protocols/security.md` and `authorization.md` and get an integration review (R3). Anything outside (a)–(d) → `halt` with `escalation`. | E, F, D, J, H |
| D10 | Cleanup-job runner | An **in-process**, lease-based runner in the Node server (claims via `FOR UPDATE SKIP LOCKED`), kicked after each commit and polled while the process is alive, plus a one-shot CLI for cron. No separate worker process and no queue library. Cron installation belongs to the ops plan (`docs/ops/prod-backup-restore-plan.md` Step 3); the runner must work correctly without it. | E.1, F.2 |
| D11 | Effect classification (review table, finalized) | Job types are limited to `file_delete` and `posthog_person_delete`. In-app invite notifications and passed-away notifications are written **in the command's transaction**. Invitation email to new users stays **best-effort** delivery metadata. Optional audit and activity records stay best-effort but **logged**. Required audit rows (pet deletion, account erasure) are written in the transaction and awaited. | E.2, E.4, F.2 |
| D12 | Weight side effects | Weight-establishment persistence and the pet weight-cache refresh move **inside** the completion transaction. Both are local and idempotent. | E.4 |
| D13 | Pet-data deletion DTO | Add `files_scheduled` (int) and `file_cleanup` (`scheduled` \| `none`). Keep `files_removed` as a documented, **deprecated alias** of `files_scheduled` for installed clients. | E.2 |
| D14 | Passed-away repeat policy | At most one notification per (pet, event, recipient), tracked in `pet_lifecycle_notifications`. A repeat POST returns 200 with `notified_count` = newly notified, `already_notified_count`, and `delivery_status` ∈ `delivered` \| `already_notified` \| `no_recipients`. | E.2 |
| D15 | Erasure scope | Database erasure is **synchronous** inside the acceptance transaction (user row plus existing cascades). Files and PostHog deletion are **asynchronous** cleanup jobs. Shared/household behaviour is unchanged: the existing 409 `household_pets_require_confirmation` stays. | F.2 |
| D16 | Erasure wire contract | `202 { message, erasure: { operation_id, status: "accepted", status_token } }`. Status is read with `GET /api/auth/erasure/:operationId` plus header `X-Erasure-Status-Token`. Installed clients only read `message` and treat any status below 400 as success, so they stay compatible. The UI does **not** poll; it says the account is deleted and that remaining files and analytics data are being removed. | F.2, F.4 |
| D17 | Rejecting existing access tokens | A global middleware does one primary-key lookup on `users` for every request that carries a verified bearer access token, with **no cache**. A missing user returns 401 `{ code: "account_unavailable" }`. It applies on both `/api` and `/backend/api`. | F.3 |
| D18 | Pet cache freshness | `lastSyncedAt` is persisted per user. Up to 7 days old = `stale` (info banner showing the sync time). Older than 7 days, or unknown = `expired`/`unknown` (warning banner plus Retry). Cached data stays visible. | G.1 |
| D19 | Health store semantics | No optimistic updates. Commands return `CommandOutcome { committed, refreshFailed }`. A failed refresh keeps the last good data and exposes a refresh error. | G.2, G.3 |
| D20 | Flutter public API convention | One entrypoint per feature, `lib/features/<feature>/<feature>.dart`. Data implementations are never exported. UI entrypoints are exported explicitly and listed in the feature README. Cross-feature imports must use the entrypoint. | I1 |
| D21 | Cycle-cut strategy | Multi-feature pet-profile surfaces (profile or detail sections that aggregate health, weight, sharing, vet or pet-care widgets) move into `experience`, the composition layer. `pet_profile` keeps the Pet domain, data, list and form. The final target is **zero** multi-feature strongly connected components. | I2 |
| D22 | Invite replay and concurrency | An identical replay (same inviter, email, role and pet set) while a pending invite covers every requested pet returns 200 with the existing invite and `replayed: true`. It is never disclosed to another inviter. Creation is serialized with `pg_advisory_xact_lock` per (inviter, lower(email)). Other cases keep today's semantics (201 plus `excluded[]`, or 400). | E.4 |
| D23 | Coverage thresholds | The Flutter domain threshold is the implemented **70%**, and the docs are aligned now (D.3). After J.1 counts files missing from coverage as uncovered, the threshold is re-set from the measured result, never below 70% without a recorded exception. Backend coverage gets per-area ratchet floors at the measured values. | D.3, J.1 |

## Hard stops (halt even with the grant)

- Any migration beyond the three tables in D9(a), or any change to an existing table.
- Any response change for installed clients that is not additive or compatible (D13, D14, D16, D22 are the only exceptions).
- Deleting, skipping or quarantining a test, or lowering a threshold, to get green.
- F.1 finds personal data that would survive account erasure with no lawful-retention reason, and fixing it lies outside F's allowed paths → `halt --reason governance_approval_required`.
- Changes to frozen internals (manifest `sourceRoots` / `serverRoots` / frozen `server/lib` files) beyond what a phase explicitly lists.

## Child plans and sequence

| Order | Child `plan_id` | Packages | Depends on | Parallel-eligible | Integration branch |
|---|---|---|---|---|---|
| 1 | `active-codebase-batch-d-guardrails-e41f` | 1, 9 (D6 gate), 11 (D7 report, D23) | — | — | `cursor/active-codebase-d-integration-e41f` |
| 2 | `active-codebase-batch-e-backend-integrity-e41f` | 3, 4, 6 | D | G | `cursor/active-codebase-e-integration-e41f` |
| 3 | `active-codebase-batch-f-account-erasure-e41f` | 5 | E (cleanup jobs) | G | `cursor/active-codebase-f-integration-e41f` |
| 4 | `active-codebase-batch-g-client-authority-e41f` | 7, 8 | D | E, F (Flutter-only; disjoint paths) | `cursor/active-codebase-g-integration-e41f` |
| 5 | `active-codebase-batch-h-ports-transport-e41f` | 10 | F, G | — | `cursor/active-codebase-h-integration-e41f` |
| 6 | `active-codebase-batch-i1-public-apis-e41f` | 9 (entrypoints, forbidden edges) | D, G, H | J | `cursor/active-codebase-i1-integration-e41f` |
| 7 | `active-codebase-batch-i2-acyclic-graph-e41f` | 9 (acyclic graph, server direction) | I1 | J | `cursor/active-codebase-i2-integration-e41f` |
| 8 | `active-codebase-batch-j-standards-e41f` | 11 | D | I1, I2 (scripts/CI only) | `cursor/active-codebase-j-integration-e41f` |
| 9 | `active-codebase-batch-k-final-acceptance-e41f` | 12 + programme acceptance | all | — | `cursor/active-codebase-k-integration-e41f` |

**Default is sequential.** The orchestrator may run a parallel-eligible child with `/spawn-sprint-agents` only when its `allowed_paths` stay disjoint from the running child's. Integration → `main` merges are always serialized: babysit merge preflight, then pre-UAT on each merge SHA.

### Cross-programme landing slots (supersedes the parallel-eligible column)

Since 2026-09-30 this roadmap (ARCH) shares `main` with CARE, TEST and PEOPLE. `docs/agent-efficiency/parallel-programmes.md` (§4) owns the landing order, and it wins over the table above. Each child's **Entry gate** section restates its slot.

| Child | Slot | Bootstrap / land after (each with pre-UAT green on its merge SHA) |
|---|---|---|
| D | 1 | 0a (#1445) and 0b (#1454, the People docs PR that adds the coordination doc) |
| E | 3a | CARE A+B (2b) |
| F | 5a | ARCH E (3a) and PEOPLE server (4) |
| G | 7 | CARE E+F (5b); re-baseline Package 8 first |
| H | 9 | PEOPLE client integration (8) |
| I1 | 10 | ARCH H (9) |
| I2 | 10, after I1 | I1 |
| J | 11 | TEST slice 2 (6) |
| K | 12 | everything else |

The rules in that doc apply to every child: one landing on `main` at a time; a landing broadcast on each programme's control thread after each merge; migrations are named, not numbered, until landing; each programme stays inside the areas it owns. A later child may start development early on its own branches (the doc's "Develops in parallel with" column), but it opens its integration → `main` PR only in its slot.

## Delivery mechanics (every child)

1. Create the child integration branch from current `main`. The snapshot `base_branch` is that integration branch.
2. Each numbered phase goes on its own branch, as one PR into the integration branch, driven through **/babysit-plus** (squash merge). The phase gate is merge-done.
3. The last phase (**Integration → main + pre-UAT**) opens one PR from the integration branch into `main`. The coordinator runs `./scripts/pre-push.sh`, then **/babysit-uat**, then `./scripts/babysit_uat_watch_preuat.sh <merge_sha> --timeout-min 90`. On failure: **/e2e-debug**, then **/babysit-uat** on the remedial PR in the same session. The child is done only when pre-UAT is green.
4. Commits use `phase(<id>/<total>): <type>: <description>`. Drift, meaning files outside `allowed_paths` and not covered by an allowed exception, triggers a halt.
5. Each phase updates `docs/engineering/active-codebase-baseline/README.md` rows it changes (via the `docs` exception) and the review doc's Implementation status table (from D.1 onward).

## Cross-cutting acceptance gates (apply to every phase)

| ID | Gate |
|---|---|
| CG1 | `./scripts/pre-push-changed.sh` green during iteration; `./scripts/pre-push.sh` green before each merge; `node scripts/check_file_size.js` green (no file above 500 lines, no allowlist growth). |
| CG2 | Server changes: `cd server && npx jest --env=node --forceExit` green. Every transaction or concurrency claim is proven by a **real-PostgreSQL** integration test, not only mocks. These tests live under `server/test/db/**` (the only directory the CI `backend-integration` job runs) and use the shared helper from E.1, which **fails** rather than silently returning when `CI=true` and the database is unreachable. |
| CG3 | Flutter changes: `flutter analyze --no-fatal-warnings --no-fatal-infos` and `flutter test --concurrency=1 --exclude-tags=integration` green; `dart run build_runner build --delete-conflicting-outputs` when mocks change. |
| CG4 | Any response change: contract tests on **both** `/api` and `/backend/api`; `docs/architecture/api-reference.md` and `docs/architecture/openapi/pet-care-critical.json` updated; `node scripts/validate_openapi.js` green; an installed-client note in the PR body (which field the shipped Flutter client reads, and why it still works). |
| CG5 | Calendar dates stay `YYYY-MM-DD` on the wire; no `gen_random_uuid()` in SQL (UUIDs are generated in code). |
| CG6 | No test skipped, deleted or weakened to pass. Characterization tests that the phase intentionally changes are replaced by regression tests, and the change is noted in the baseline README. |
| CG7 | From D.2 onward: `node scripts/check_feature_imports.js` green, and the baseline may only shrink. |
| CG8 | BDD/E2E changes: `node e2e/scripts/check_bdd_coverage.js`, `node e2e/scripts/validate-shard-manifest.mjs` and `node scripts/check_bdd_priority_tags.js` green; the Playwright `@bdd` title exactly matches the Gherkin `Scenario:`. |
| CG9 | 5xx responses never contain raw error text (existing security tests plus `publicError`). Logs contain no tokens, passwords or email addresses in new code paths. |
| CG10 | Pre-UAT E2E green on the integration → `main` merge SHA of every child. |

## Traceability matrix (review exit gates → acceptance criteria)

| Review requirement (package / gate) | Acceptance criteria |
|---|---|
| P1 A01: one client per transaction; injected failure rolls back everything | E.2 AC 1–3, E.3 AC 1–3, E.4 AC 10 |
| P3: cleanup is retryable, counts are truthful, a rotating pool catches pool queries | E.1 AC 1–11, E.2 AC 2–5 |
| P3: duplicate transaction helpers migrated | E.3 AC 1–2, E.4 AC 10 |
| P1 A02 / P4: committed results stay stable; replay and concurrency are safe | E.4 AC 1–9 |
| P4: jobs have retry, backoff, dedupe and a failed-job inspection path | E.1 AC 3–10 |
| P5: 202 plus durable job, access rejection, resumable cleanup, runbook | F.1 AC 1–5, F.2 AC 1–12, F.3 AC 1–5, F.4 AC 1–4 |
| P6: docs, DTO and read-after-write agree; no duplicate notifications | E.2 AC 5, E.2 AC 7–9 |
| P7: freshness metadata; all consumers migrated; user switch is safe | G.1 AC 1–7, G.4 AC 1–3 |
| P8: one owner; commands in a controller; refresh failure is separate from command failure | G.2 AC 1–6, G.3 AC 1–6 |
| P9: block-new gate (D6) | D.2 AC 1–6 |
| P9: public surfaces, no private/data cross-imports, domain features don't import Experience | I1.1 AC 1–4, I1.2 AC 1–3, I1.3 AC 1–3, I1.4 AC 1–3 |
| P9: acyclic target graph; server ownership rule | I2.1–I2.4 |
| P10: auth and document ports; central principal and error boundary | H.1 AC 1–4, H.2 AC 1–4, H.3 AC 1–4, H.4 AC 1–4 |
| P11: D7 report-only then ratchet; coverage denominators; lint; BDD; checker fixtures | D.3 AC 1–4, J.1–J.4 |
| P12: cohesive extractions, ADRs, READMEs, before/after metrics, final review | K.1–K.4 |

## Programme exit criteria

The roadmap is complete only when **all** of the following hold on `main`:

1. Every P1 finding (A01–A06) has a passing failure-path test, listed in the baseline README.
2. The transaction-ownership architecture test (E.3) has **zero** exceptions in active server code.
3. Pet deletion, weight completion, invite creation and acceptance, passed-away notification and account erasure each have a stable committed response, plus real-PG tests for fault injection and concurrency.
4. Account erasure returns 202 only after durable acceptance, rejects old access tokens, and its cleanup jobs reach `completed` or a visible `failed` state (F.2, F.3).
5. The health-presentation boundary test (G.3) passes, and every health mutation goes through the controller or store.
6. `python3 scripts/architecture/architecture-metrics.py` reports **0** multi-feature strongly connected components, and `check_feature_imports.js` has an **empty** baseline for rules R1–R3, R5 and R6.
7. The size, lint, coverage, BDD, boundary, import and transaction checkers each have a fixture proving they fail on a deliberate violation, and all run in blocking CI (J.4).
8. The review doc is marked implemented; its Implementation status table has no Partial or Not-started rows; any remaining P2/P3 exceptions have an owner, reason and review date (K.4).
9. Pre-UAT E2E green on the final `main` merge SHA.

## Runtime state (agent-updated)

**Agent handover (gates D–G delta):** [`.agents/plans/active-codebase-completion-e41f.handoff-d-g.md`](./active-codebase-completion-e41f.handoff-d-g.md) on `main` (full playbook remains on branch `claude/friendly-davinci-5zcxj2` until copied).

```yaml
autonomy: active
current_phase: orchestrate
last_completed_phase: null
halt_reason: null
next_action: "bootstrap and gate child plan active-codebase-batch-e-backend-integrity-e41f"
artifact_ref:
  branch: cursor/arch-d-g-handover-26ff
  plan_path: .agents/plans/active-codebase-completion-e41f.md
  plan_commit: 8fa1b1f5154164d8a2322aa6d8d50567ed795590
  snapshot_path: .agents/plans/active-codebase-completion-e41f.snapshot.json
  snapshot_commit: 8fa1b1f5154164d8a2322aa6d8d50567ed795590
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Sanity check (pre-approval)

- **Result:** `proceed-high-risk`. The programme is large and includes a privacy-critical erasure flow, but it is split into nine children that each fit the 48h window.
- Every child phase declares `allowed_paths`, `forbidden_paths`, `allowed_exceptions` and `exit_checklist`.
- Phases inside one child overlap on `allowed_paths` only in I1 (phases 2–4), I2 (phases 2–3), J (the CI workflow file in phases 1, 2 and 4) and D (the CI workflow file in phases 2–3). Each child states the overlap, and those phases run strictly in sequence, never with `/spawn-sprint-agents`.
- Children run in parallel only where the sequence table allows it, and only with disjoint paths. The one shared file set is the l10n ARB files between F.4 and G.1; the G plan documents how to resolve that.
- Migrations, auth changes, CI edits and wire changes are enumerated and pre-approved in D9; anything else halts.

## Revoke and resume

| Action | How |
|---|---|
| Revoke | Add `autonomous-revoked` on the roadmap or child control issue; optionally `do-not-merge` on open PRs. Halt only: do not close PRs or revert merges. |
| Resume | Remove the revoke label; comment `resume-plan <plan_id>`; run `/execute-plan <plan_id> resume`. |

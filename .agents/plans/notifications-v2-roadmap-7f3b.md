---
title: Notifications v2 roadmap orchestrator
owner: Agent
audience: agent
status: active
---

# notifications-v2-roadmap-7f3b

## Before you run

1. Create control issue (replace `control_issue: 1` in all snapshots with real `#`):
   ```bash
   node scripts/execute_plan_runtime.js init-control-issue notifications-v2-roadmap-7f3b
   # run rendered gh issue create; paste issue number into snapshots + foundation if shared
   ```
2. Comment on control issue: **`approve-autonomous notifications-v2-roadmap-7f3b`**
3. Set snapshot `autonomy: active`, `approved_by` to grant comment, re-run `--fix-hash` on roadmap snapshot
4. `/execute-plan notifications-v2-roadmap-7f3b` → gate exit 0 → **`/execute-plan notifications-v2-foundation-7f3b`**

**Sanity check:** `proceed-high-risk` (migrations PR1, auth PR7, multi-week programme — re-grant before each `approved_until` expiry or bootstrap child with fresh 48h window).

## Goal

Orchestrate Notifications v2 from **spec rev 2.3.1 on `main`** through **PR7** (account security), then **integration → `main`**. PR8 (subscription) is **skipped** until billing provider + server entitlement source. Programme index: [notifications-v2-programme.md](../../docs/domains/notifications/changes/notifications-v2-programme.md).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | *(set at grant)* |
| **approved_until** | `approved_at + 48h` per child bootstrap; re-grant parent if programme spans longer |
| **control_issue** | *(from `init-control-issue`)* |
| **Grant keyword** | `approve-autonomous notifications-v2-roadmap-7f3b` |

**Standing grant (user chat 2026-10-04):** full delegated authority for foundation → PR7 + integration; billing PR8 **not now**; sign-in location **not now** (N13).

## Sanity check

**Output:** `proceed-high-risk` — migrations (PR1), auth/security (PR7), large Flutter inbox (PR2–PR4). Router **full** at each child bootstrap.

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: orchestrate
halt_reason: null
next_action: "roadmap complete"
artifact_ref:
  branch: cursor/notifications-v2-integration-7f3b
  plan_path: .agents/plans/notifications-v2-roadmap-7f3b.md
  plan_commit: 61a39527011c99297174f7f64fd09f93c493eb11
  snapshot_path: .agents/plans/notifications-v2-roadmap-7f3b.snapshot.json
  snapshot_commit: 61a39527011c99297174f7f64fd09f93c493eb11
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

## Orchestration loop

1. `roadmap-next-child notifications-v2-roadmap-7f3b`
2. Bootstrap child snapshot if missing; child `approved_by` = same standing grant
3. `/execute-plan <child_plan_id>` until child `complete-plan`
4. `roadmap-set-child --status merged --write`
5. Repeat until all children merged or PR8 skipped
6. Run `notifications-v2-integration-7f3b` → `/babysit-uat` on integration → `main`

## Child plans

See snapshot `child_plans[]`. CLI: `node scripts/execute_plan_runtime.js roadmap-status notifications-v2-roadmap-7f3b`

| plan_id | When |
|---------|------|
| `notifications-v2-foundation-7f3b` | **First** — 2.3.1 + merge docs/spec to `main` |
| `notifications-v2-pr1-7f3b` … `pr7-7f3b` | After foundation; base = integration branch |
| `notifications-v2-pr8-7f3b` | **skipped** |
| `notifications-v2-integration-7f3b` | After PR7 merged to integration |

## Phase — orchestrate (roadmap parent)

Single governance phase: update programme index, snapshot child status, commit on active child artifact branch.

**Exit:** All children `merged` or `skipped`; integration PR merged to `main`.

---

## Child plan summaries (bootstrap reference)

Detailed phases live in each `.agents/plans/<child>.md`. Spec AC tags in [notifications-v2-spec.md](../../docs/domains/notifications/features/notifications-v2-spec.md).

### notifications-v2-foundation-7f3b

| Phase | Branch | Deliverable |
|-------|--------|-------------|
| 1 | `cursor/notifications-v2-spec-231-7f3b` | Rev **2.3.1** (six nits, FR-IA A1/A9, `shareLinkFollowed`, Secure-my-account session rule, FR-MG-5 N1–N13, badge prose) |
| 2 | same | PR **`main`** — merge lineage from `origin/claude/jolly-allen-cxrzgc` + foundation commits; docs checks green |

### notifications-v2-pr1-7f3b

Create `cursor/notifications-v2-integration-7f3b` from `main` if missing. **PR1 spec §12.**

- Server: no inbox rows for `overdue`/`due_soon`; migration archives due rows only; SQL backfill reclassify §3.4; extend `kind` enum
- Flutter: parse `relationship`, `suggestion`, `account`; safe default (no crash)
- BDD: `notifications_v2.feature`; tag legacy care-in-inbox `@legacy`; compensate coverage gate
- Jest: migration + reclassify fixtures per emitter title

### notifications-v2-pr2-7f3b

- Split `notification_panel` → shared tab shell; Activity / For you; calm badge §5.4.1; Appendix A → ARB (EN/FR)
- Remove kind chips; session tab memory; server explainer pref

### notifications-v2-pr3-7f3b

- Emit R1–R12, R14–R17; `shareLinkFollowed`; ban `general`; `notificationKind.js` map; AC-AC-16 guard test
- Privacy FR-PR-* ; snapshot fields on rows

### notifications-v2-pr4-7f3b

- **Core:** Needs your response, inline accept/decline (relationship + admin pending), FR-AR-5/6
- **Enhancement (cut if slip):** read-model grouping API, R4/R18 jobs

### notifications-v2-pr5-7f3b

- Server suggestion job, S1–S7, rate limits, For you cards; FR-SG-6 deferred until this PR (profile API consumer)

### notifications-v2-pr6-7f3b

- **Core:** settings matrix, mandatory locks, FR-SE-5 mute rules
- **Enhancement:** digest FR-DG-* , N8 email default

### notifications-v2-pr7-7f3b

| Phase | Deliverable |
|-------|-------------|
| 1 | **Security architecture note** `docs/domains/notifications/changes/notifications-v2-security-architecture.md` — device_label storage/retention/erasure, A1 push routing, Secure my account session order (keep current refresh), DPIA pointer |
| 2 | A1–A3, A6 implementation; device label on login; emails; inline A1 actions (FR-IA) |

Protocols: `security`, `authorization`, `data-lifecycle`, `private-files` (if new tables).

### notifications-v2-integration-7f3b

- `./scripts/pre-push.sh`; PR integration → `main`; `/babysit-uat`; delete `@legacy` BDD in same or follow-up PR per spec §12 (PR6 says delete legacy — verify at integration)

## Revoke / resume

Standard execute-plan. On `session_limit`, halt with `next_action: resume-plan notifications-v2-roadmap-7f3b`.

# Agent plans

Multi-phase autonomous work artifacts for `/execute-plan`.

| File | Purpose |
|------|---------|
| `<plan_id>.md` | Human-readable plan + runtime state (updated during run) |
| `<plan_id>.snapshot.json` | Frozen contract at upfront approval |

**Convention:** `artifact_branch_policy: phase-branch` — commit plan files on the active phase branch. Control issue is the index (see [github-labels.md](../../docs/agent-efficiency/github-labels.md)).

**Example:** `_example.md` + `_example.snapshot.json` (validated in CI via `scripts/validate_execute_plan_snapshot.js`).

**Docs:**

- [execute-plan skill](../../.cursor/skills/execute-plan/SKILL.md)
- [execute-plan-schema.md](../../docs/agent-efficiency/execute-plan-schema.md)
- [execute-plan-runtime.md](../../docs/agent-efficiency/execute-plan-runtime.md)
- [plan-template.md](../../docs/agent-efficiency/plan-template.md)
- [autonomous-pr-policy.md](../../docs/agent-efficiency/autonomous-pr-policy.md)

**Approval expiry:** 48 hours from `approved_at` (autonomy window). **Session limit:** ~24h continuous work → `halt --reason session_limit`; resume via `resume-plan` on control issue.

**Autonomy contract:** `.agents/memory/execute-plan-autonomy.md`

## Closed stale plans (2026-09-29)

These snapshots still said `autonomy: active` on `main` although their work had landed or their 48h approval window had long expired. They were closed in one bookkeeping pass (People domain refactor session, `people-domain-refactor-7f3b` prep). `completed` = every phase merged. `revoked` = approval window expired (schema meaning); the listed phases were **not** done and are not carried forward — re-plan them if still wanted. Open control issues among them (#1427, #1373, #1094, #1093, #671, #652, #500) were closed on GitHub the same day with a comment. Coordination of the programmes still running: [parallel-programmes.md](../../docs/agent-efficiency/parallel-programmes.md).

| Plan | Control issue | Closed as | Note |
|------|---------------|-----------|------|
| `away-care-planning-debt` | #1323 | `revoked` | Window expired 2026-09-26; unfinished `debt-1` not carried forward. Check against `care-next-occurrence-c1a7` before re-planning. |
| `away-care-planning` | #1304 | `revoked` | Window expired 2026-09-25; unfinished `acp-8` not carried forward. Check against `care-next-occurrence-c1a7` before re-planning. |
| `care-schedule-management-v1` | #1173 | `revoked` | Window expired 2026-09-17; unfinished `csm-8, csm-12, csm-13` not carried forward. Check against `care-next-occurrence-c1a7` before re-planning. |
| `care-through-change-v1` | #1110 | `revoked` | Window expired 2026-09-11; unfinished `cc3, cc4` not carried forward. Check against `care-next-occurrence-c1a7` before re-planning. |
| `ci-speedup` | #285 | `revoked` | Window expired 2026-07-25; unfinished `4` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `ci-test-depth-abc9` | #558 | `revoked` | Window expired 2026-08-05; unfinished `F6` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `collection-filter-canonical-f8a2` | #884 | `completed` | All phases merged. |
| `contacts-detail-parity-fcd9` | #1440 | `completed` | All phases merged via #1440 (no control issue existed; `control_issue` set to the delivering PR; missing phase fields reconstructed). |
| `db-schema-bootstrap-345` | #251 | `revoked` | Window expired 2026-07-23; unfinished `3, 4, 5` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `e2e-debug-skill-6bba` | #1 (placeholder) | `revoked` | Window expired 2026-08-25; unfinished `1` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `e2e-flutter344-uat-unblock-5641` | #500 | `revoked` | Window expired 2026-07-30; unfinished `1, 2` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `experience-program-36bd` | #379 | `revoked` | Window expired 2026-07-27; unfinished `2, 3, 5` not carried forward. |
| `fostering-platform-j1-phase4-e877` | #352 | `completed` | All phases merged. |
| `fostering-platform-wave-c-e877` | #369 | `revoked` | Window expired 2026-07-27; unfinished `2, 3, 4, 5, 6` not carried forward. Frozen domain. |
| `guardian-care-block-surface-5d6a` | #940 | `revoked` | Window expired 2026-09-05; unfinished `1` not carried forward. |
| `guardian-desk-framing-6e46` | #928 | `completed` | All phases merged. |
| `guardian-ops-desk-754-b9bd` | #755 | `completed` | All phases merged. |
| `guardian-org-profile-link-3e55` | — | `revoked` | Window expired 2026-09-03; unfinished `1` not carried forward. Frozen domain. Never had a control issue (snapshot left with `control_issue: 0`). |
| `guardian-semantics-preuat-2600` | #688 | `revoked` | Window expired 2026-08-23; unfinished `1` not carried forward. |
| `organisation-ux-v3-badd` | #567 | `revoked` | Window expired 2026-08-06; unfinished `12` not carried forward. Frozen domain. |
| `organisation-v2-abc9` | #537 | `revoked` | Window expired 2026-08-04; unfinished `1a, 1b, 2a, 2b, 3, 4a, 4b, 5, 6, 7a, 7b, 8a, 8b, 9, INT` not carried forward. Frozen domain. |
| `organisation-v4-people-perms` | #621 | `completed` | All phases merged. |
| `people-vet-unify-a58d` | #1427 | `completed` | All phases merged; p5 landed via #1433 → #1434 (`945f2a3`), runtime sync had been skipped. |
| `personal-pet-list-role-split-6d00` | #1233 | `revoked` | Window expired 2026-09-19; unfinished `1` not carried forward. |
| `pet-care-weight-validation` | #1028 | `revoked` | Window expired 2026-09-08; unfinished `1` not carried forward. |
| `pet-detail-ux-c2ce` | #823 | `completed` | All phases merged. |
| `pet-form-redesign-f4a2` | #976 | `revoked` | Window expired 2026-09-07; unfinished `4, 5` not carried forward. |
| `pet-share-invite-v2-13cc` | #1226 | `revoked` | Window expired 2026-09-19; unfinished `1` not carried forward. Check against `people-domain-refactor-7f3b` (p5) and `active-codebase-batch-e` (E.4) before re-planning. |
| `pet-sharing-consolidation-8cf0` | #1218 | `revoked` | Window expired 2026-09-18; unfinished `1, 3` not carried forward. Check against `people-domain-refactor-7f3b` (p5) and `active-codebase-batch-e` (E.4) before re-planning. |
| `pet-timeline-segments-a03d` | #532 | `revoked` | Window expired 2026-08-04; unfinished `1` not carried forward. |
| `pet-timeline-view-a03d` | #530 | `revoked` | Window expired 2026-08-04; unfinished `1` not carried forward. |
| `public-access-gate-a35f` | #611 | `completed` | All phases merged. |
| `session-detail-view-eec3` | #804 | `completed` | All phases merged. |
| `shelter-dashboard-v2-c4e8` | #952 | `completed` | All phases merged. |
| `shelter-desk-parity-dd8e` | #942 | `revoked` | Window expired 2026-09-05; unfinished `0` not carried forward. Frozen domain. |
| `uat-agent-babysit-5641` | #481 | `revoked` | Window expired 2026-07-29; unfinished `1, 2, 3, 4` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `uat-coordinator-launch-fix-7808` | #345 | `revoked` | Window expired 2026-07-27; unfinished `1` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `uat-pre-e2e-pipeline-5641` | — | `revoked` | Window expired 2026-07-28; unfinished `1, 2, 3` not carried forward. Check against `test-health-ci-5f3a` before re-planning. Never had a control issue (snapshot left with `control_issue: 0`). |
| `uat-queue-pr-fallback-2936` | #363 | `revoked` | Window expired 2026-07-27; unfinished `1` not carried forward. Check against `test-health-ci-5f3a` before re-planning. |
| `ui-navigation-v2-14ee` | #299 | `revoked` | Window expired 2026-07-25; unfinished `10` not carried forward. |
| `unified-pet-tile-c4e8` | #950 | `revoked` | Window expired 2026-09-05; unfinished `2` not carried forward. |
| `workspace-nav-simplify-8c14` | #897 | `completed` | All phases merged. |

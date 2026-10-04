---
title: Notifications v2 PR1 — migration + stop care inbox rows
owner: Agent
audience: agent
status: active
---

# notifications-v2-pr1-7f3b

## Goal

Deliver spec **PR1**: stop creating inbox rows for due/overdue care; migrate archive + reclassify legacy rows; client parses new kinds safely; BDD v2 bootstrap.

**Prerequisite:** `notifications-v2-foundation-7f3b` merged to `main`.

## Autonomy

| Field | Value |
|-------|-------|
| **Grant keyword** | `approve-autonomous notifications-v2-pr1-7f3b` |
| **base_branch** | `cursor/notifications-v2-integration-7f3b` |

**Bootstrap:** At phase start, create integration branch from `origin/main` if absent; push empty branch or first commit.

## Phase 1 — PR1 implementation

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/notifications-v2-pr1-7f3b` |
| **exit_checklist** | `single-backend-route`, `bdd-journey`, `flutter-screen-split` (parser only) |

**allowed_paths:**

```
server/lib/checkDueNotifications.js
server/lib/notificationKind.js
server/lib/notificationHelper.js
server/routes/**/notification*
server/test/notifications/**
server/test/**/notification*
db/migrations/**
flutter_app/lib/features/notifications/domain/**
flutter_app/lib/features/notifications/data/**
flutter_app/test/features/notifications/**
flutter_app/test/bdd/features/notifications.feature
flutter_app/test/bdd/features/notifications_v2.feature
docs/domains/notifications/features/notifications-v2-spec.md
.agents/plans/notifications-v2-pr1-7f3b.*
```

**forbidden_paths:**

```
.github/workflows/**
server/config/security.js
infra/**
**/billing/**
```

**allowed_exceptions:** `docs`, `tests`, `migrations`

**Scope:**

- Migration: archive `overdue`/`due_soon`; reclassify per §3.4 (title fixtures for `general` rows); add kinds on wire
- `checkDueNotifications`: push/local only — no INSERT inbox for due/overdue (FR-CR-1)
- Flutter `NotificationKind`: `relationship`, `suggestion`, `account`; unknown → safe parse (FR-MG-4)
- BDD: create `notifications_v2.feature` (AC-CR-*, AC-MG-*); `@legacy` on old care-inbox scenarios; maintain `check_bdd_coverage.js` gate
- Jest: AC-CR-6, AC-MG-6 migration assertions; pre-migration backup note in `docs/ops/` if not present

**Exit criteria:**

- [ ] AC-CR-1, AC-CR-4, AC-CR-6, AC-MG-1, AC-MG-2, AC-MG-3, AC-MG-6 covered by tests
- [ ] `./scripts/pre-push.sh` green
- [ ] PR merged to integration branch

**Router:** R2 — protocols: api-contract, authorization, security, testing, migrations.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr1-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr1-7f3b
  plan_path: .agents/plans/notifications-v2-pr1-7f3b.md
  plan_commit: 7cfba3b505dfaf413556fa6330802401d179a83a
  snapshot_path: .agents/plans/notifications-v2-pr1-7f3b.snapshot.json
  snapshot_commit: 7cfba3b505dfaf413556fa6330802401d179a83a
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1574"]
merge_commits: {}
debt_issue_refs: []
```

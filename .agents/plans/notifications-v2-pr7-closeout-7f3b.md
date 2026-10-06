# notifications-v2-pr7-closeout-7f3b

**Goal:** Close PR7 follow-ups after roadmap merge: A2 inline **Secure my account**, AC-ACS test coverage, document A1 cross-device push until token registry exists.

**base_branch:** `main`

**Read first:** `docs/domains/notifications/changes/notifications-v2-security-architecture.md`, spec §13.15a AC-ACS-*.

## Phase 1 — PR7 closeout

| Field | Value |
|-------|-------|
| **id** | `1` |
| **branch** | `cursor/notifications-v2-pr7-closeout-7f3b` |
| **exit_checklist** | `single-backend-route`, `bdd-journey` |

**allowed_paths:**

```
server/lib/account/**
server/routes/notifications/**
server/test/account/**
flutter_app/lib/features/notifications/**
flutter_app/lib/features/experience/presentation/services/notification_inline_action_runner.dart
flutter_app/test/features/notifications/**
flutter_app/test/bdd/features/notifications_v2.feature
docs/domains/notifications/changes/deferred.md
.agents/plans/notifications-v2-pr7-closeout-7f3b.*
```

**forbidden_paths:** `.github/workflows/**`, `db/migrations/**`

**Scope:**

- A2 `accountPasswordChanged`: inline **Secure my account** for 7 days (Flutter + server feedback rules); resolve A2 on secure-account completion.
- Server Jest mapping AC-ACS-2, 5, 6, 7, 10 (push AC-ACS-1 deferred).
- BDD `@P1` scenarios in `notifications_v2.feature` for A1/A2 inline parity where steps exist.
- Record A1 push-to-other-devices in `deferred.md` (no server push token store).

**Exit criteria:**

- [ ] A2 row shows Secure my account within 7-day window; A1 unchanged.
- [ ] `accountSecurityNotifications` tests green; `./scripts/pre-push-changed.sh` on touched paths.
- [ ] PR merged to `main` with pre-UAT green.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-10-05T18:20:00Z |
| **approved_until** | 2026-10-07T18:20:00Z |
| **control_issue** | #1664 |
| **autonomy** | `active` |

**Grant:** User chat 2026-10-05 — wrap up PR7 follow-ups in a small plan then `/execute-plan`.

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: main
  plan_path: .agents/plans/notifications-v2-pr7-closeout-7f3b.md
  plan_commit: 3c1f8b72187969a0e8d93e6f6b7505d0d2309fc3
  snapshot_path: .agents/plans/notifications-v2-pr7-closeout-7f3b.snapshot.json
  snapshot_commit: 3c1f8b72187969a0e8d93e6f6b7505d0d2309fc3
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

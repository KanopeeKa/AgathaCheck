# notifications-v2-pr7-7f3b

**Goal:** Spec PR7 — account security A1–A3, A6; device label; Secure my account flow.

**base_branch:** `cursor/notifications-v2-integration-7f3b`

**Read first:** `.cursor/agent-kernel/protocols/security.md`, `data-lifecycle.md`, spec §3.5, FR-ACC-*.

## Phase 1 — Security architecture note

| | |
|--|--|
| **id** | `1` |
| **branch** | `cursor/notifications-v2-pr7-arch-7f3b` |
| **exit_checklist** | `governance` |

**allowed_paths:**

```
docs/domains/notifications/changes/notifications-v2-security-architecture.md
docs/engineering/privacy/**
docs/domains/notifications/features/notifications-v2-spec.md
.agents/plans/notifications-v2-pr7-7f3b.*
```

**Scope:** Document device_label table/fields, retention, account erasure deletion, A1 push to other devices rules, Secure my account step order (preserve current session through password change), DPIA cross-ref N13.

**Exit:** Doc reviewed; merged to integration before phase 2 code.

## Phase 2 — PR7 implementation

| | |
|--|--|
| **id** | `2` |
| **branch** | `cursor/notifications-v2-pr7-7f3b` |
| **exit_checklist** | `single-backend-route`, `bdd-journey`, `flutter-screen-split` |

**allowed_paths:** `server/routes/auth/**`, `server/lib/refreshSessions.js`, `server/lib/account/**`, `server/routes/**/notification*`, `db/migrations/**`, `flutter_app/lib/features/notifications/**`, `flutter_app/lib/features/auth/**`, `server/test/**`, `flutter_app/test/**`

**forbidden_paths:** `.github/workflows/**`, `server/config/security.js` (unless security review + no Fixes #N pattern)

**Scope:** A1–A3, A6; FR-IA inline for A1; badge matrix A1; emails N11; no A4/A5 until email-change feature.

**Exit:** AC-ACS-* (excluding A4/A5); PR merged to integration.

## Runtime

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/notifications-v2-pr7-arch-7f3b"
artifact_ref:
  branch: cursor/notifications-v2-pr7-arch-7f3b
  plan_path: .agents/plans/notifications-v2-pr7-7f3b.md
  plan_commit: 4eca46303fd05abee1898e9622d3ff53fd75fd1f
  snapshot_path: .agents/plans/notifications-v2-pr7-7f3b.snapshot.json
  snapshot_commit: 4eca46303fd05abee1898e9622d3ff53fd75fd1f
open_prs: []
merge_commits: {}
debt_issue_refs: []
```

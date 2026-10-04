# notifications-v2-pr4-7f3b

**Goal:** Spec PR4 — inline actions (core); grouping + invite expiry (enhancement tier).

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr4-7f3b` |
| **exit_checklist** | `single-backend-route`, `flutter-screen-split`, `bdd-journey` |

**allowed_paths:** `server/routes/**/notification*`, `server/lib/**notification*`, `flutter_app/lib/features/notifications/**`, `flutter_app/test/**`, `e2e/playwright/tests/*notification*`, `flutter_app/test/bdd/features/notifications_v2.feature`

**Scope:**

- **Core:** Needs your response; FR-IA-1 invites + admin pending; FR-AR-5/6; stale handling FR-IA-5
- **Enhancement (defer if slip):** §6.4.1 grouping read API; R4/R18 scheduled jobs

**Exit:** AC-IA-*, core AC-GR; PR merged to integration.

# notifications-v2-pr6-7f3b

**Goal:** Spec PR6 — settings matrix (core); digest/email (enhancement).

**base_branch:** `cursor/notifications-v2-integration-7f3b`

## Phase 1

| | |
|--|--|
| **branch** | `cursor/notifications-v2-pr6-7f3b` |
| **exit_checklist** | `single-backend-route`, `flutter-screen-split`, `bdd-journey` |

**allowed_paths:** `flutter_app/lib/features/notifications/presentation/screens/notification_settings*`, `server/routes/**/notification*`, `server/lib/**notification*`, `server/test/**`, `flutter_app/test/**`, `flutter_app/test/bdd/features/notifications_v2.feature`

**Scope:** FR-SE-*, FR-MD-*, FR-DG-* (enhancement cut if slip); delete `@legacy` BDD scenarios per spec §12.

**Exit:** AC-SE-*, AC-DG-* (subset if enhancements cut); PR merged to integration.

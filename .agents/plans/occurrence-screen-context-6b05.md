---
title: Care date screen (occurrence leaf) v1
---

# occurrence-screen-context-6b05

## Goal

Implement the agreed Care date screen layout: context tile, title + Reschedule, status, away block, unified actions; spec `occurrence-screen-context-spec.md`; widget tests and E2E locator updates.

## Metadata

| Field | Value |
|-------|-------|
| **plan_id** | `occurrence-screen-context-6b05` |
| **base_branch** | `cursor/occurrence-screen-context-6b05-integration-6b05` |
| **default_merge_mode** | `auto` |

## Phases

### Phase 1 — Spec and core Care date layout

**branch:** `cursor/occurrence-screen-context-core-6b05`  
**allowed_paths:** `docs/domains/pet_care/changes/occurrence-screen-context-spec.md`, `flutter_app/lib/features/experience/presentation/care_item/occurrence/**`, `flutter_app/lib/l10n/**`, `.agents/plans/occurrence-screen-context-6b05.*`

### Phase 2 — Away block, tests, E2E

**branch:** `cursor/occurrence-screen-context-tests-6b05`  
**allowed_paths:** same occurrence paths, `flutter_app/test/features/care_item/**`, `e2e/playwright/pages/occurrence.page.ts`, `e2e/playwright/pages/care-item.page.ts`

## Autonomy

Granted in user chat 2026-10-06 — full integration branch, single PR to `main`, no pause.

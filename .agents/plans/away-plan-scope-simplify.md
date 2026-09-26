# Away plan scope simplify

| Field | Value |
|-------|-------|
| **plan_id** | `away-plan-scope-simplify` |
| **base_branch** | `main` |

## Goal

Narrow away-plan `planned_care_items[]` to in-window care (plus stale open work after absence start), per-pet pre-departure overdue attention link, See options on flexible in-window rows, PDF parity, D-ACP-011.

## Phases

### Phase aps-1 — Server + docs

**branch:** `cursor/away-plan-scope-simplify-71a1`

**allowed_paths:** `server/lib/care/awayPlan/**`, `server/lib/care/schedule/projectSchedule.js`, `server/test/careSchedule/**`, `docs/domains/pet_care/changes/away-plan-scope-simplify-decisions.md`, `docs/architecture/api-reference.md`

### Phase aps-2 — Flutter

**branch:** `cursor/away-plan-scope-simplify-71a1`

**allowed_paths:** `flutter_app/lib/features/pet_care/context/**`, `flutter_app/lib/l10n/**`, `flutter_app/test/features/pet_care/context/**`, `e2e/playwright/pages/away-planning.page.ts`, `e2e/playwright/tests/away.care.planning*.spec.ts`

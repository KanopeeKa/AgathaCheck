# Tech debt — care reliability and hygiene (Tier 1–2)

## Goal

Close the highest-impact open `tech-debt` items for care correctness, Flutter web reliability, transaction safety, UI deduplication, and doc/execute-plan hygiene. Work lands in six atomic phase PRs on one integration branch, then one release PR to `main` and UAT. Tier 4 owner decisions, Tier 5 feature relabeling, and R11 prod cron sign-off stay outside this plan (tracked on the control issue).

## Phases

### Phase 1 — Occurrence detail schedule for decideDone (#1476)
```json
{
  "allowed_paths": [
    "server/lib/care/occurrence/**",
    "server/routes/healthEntries/**",
    "server/test/careSchedule/**",
    "server/test/db/**",
    "flutter_app/lib/features/care_item/domain/occurrence_detail.dart",
    "flutter_app/lib/features/care_item/domain/done_decision.dart",
    "flutter_app/lib/features/care_item/domain/care_item_schedule.dart",
    "flutter_app/lib/features/care_item/presentation/care_completion_flow.dart",
    "flutter_app/lib/features/experience/presentation/care_item/occurrence/**",
    "flutter_app/test/features/care_item/domain/done_decision_test.dart",
    "flutter_app/test/features/care_item/**/occurrence/**",
    "docs/domains/pet_care/features/care-item-evolution.md"
  ],
  "forbidden_paths": [
    "server/lib/care/occurrence/careItemLock.js",
    "server/lib/care/occurrence/careTick.js"
  ],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["e2e/playwright/pages/occurrence.page.ts"],
  "exit_checklist": [
    "Occurrence GET includes full schedule context used by decideDone on direct deep link",
    "Jest + Flutter tests for DN-1c/DN-4 paths green",
    "pre-push-changed green"
  ]
}
```
Scope: API and client wire `schedule` (open occurrences, interval) on occurrence detail when opened without prior item context; `decideDone` uses the same inputs as from the item hub. Update canonical spec decision log if behaviour is clarified.
Out of scope: History rich rows (#2056), notification deep links (#1540).

### Phase 2 — Care locking via withTransaction (#1735)
```json
{
  "allowed_paths": [
    "server/lib/care/occurrence/careItemLock.js",
    "server/lib/care/occurrence/careTick.js",
    "server/test/architecture/transactionOwnership.test.js",
    "server/test/**/careItemLock*.js",
    "server/test/**/careTick*.js",
    "docs/architecture/decisions/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": [],
  "exit_checklist": [
    "careItemLock.js and careTick.js removed from transaction allowlist",
    "Architecture + care lock tests green",
    "pre-push-changed green"
  ]
}
```
Scope: Migrate occurrence locking in `careItemLock.js` and tick paths in `careTick.js` to `withTransaction` per ADR 0003; keep behaviour equivalent under concurrency tests.
Out of scope: Unrelated care refactors, import-cycle split (#1545 implementation).

### Phase 3 — People hub vet phone Save on Flutter web (#1457)
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/**/people/**",
    "flutter_app/lib/features/experience/presentation/people/**",
    "flutter_app/test/features/**/people/**",
    "e2e/playwright/pages/people.page.ts",
    "e2e/playwright/tests/**/people*.spec.ts"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests"],
  "companions": [],
  "exit_checklist": [
    "E2E saves vet phone through UI without API workaround",
    "Widget or integration test covers save persistence",
    "pre-push-changed green"
  ]
}
```
Scope: Fix flaky Save on People hub vet phone edit (web focus/dispose or form state); remove API bypass in Playwright helper at `people.page.ts` ~771.
Out of scope: Other People hub features.

### Phase 4 — Dedupe Care date actions (#1823)
```json
{
  "allowed_paths": [
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_dates_section.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/care_item_needs_attention_section.dart",
    "flutter_app/lib/features/experience/presentation/care_item/detail/**",
    "flutter_app/test/features/care_item/presentation/detail/**",
    "docs/design/care-item-view-ui.md"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["tests", "docs"],
  "companions": ["e2e/playwright/pages/care-item.page.ts"],
  "exit_checklist": [
    "Single shared control for Change date / Skip / Mark done (D-CIE-037)",
    "care_item_dates_section and Needs attention tests green",
    "pre-push-changed green"
  ]
}
```
Scope: Extract shared actions widget; leaf occurrence screen remains canonical for occurrence-level actions.
Out of scope: Bulk selection mode (#1673), count-based bulk labels (#1672) — follow-up plan after this phase.

### Phase 5 — Stale compat-route docs and cycle decision (#1547, #1545)
```json
{
  "allowed_paths": [
    "docs/architecture/api-reference.md",
    "docs/architecture/care-item-cross-feature-imports.md",
    "docs/domains/pet_care/features/care-schedule-management.md",
    "docs/domains/pet_care/features/care-context.md",
    "docs/domains/pet_care/changes/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs"],
  "companions": [],
  "exit_checklist": [
    "No mark-taken or ensure-open compat routes in indexed docs",
    "care-item import cycle documents deferred sprint decision (no code split)",
    "Comment on GitHub #1545 and #1547 with doc links",
    "validate_docs.sh green"
  ]
}
```
Scope: Remove or correct stale compat-route references in the five known docs; append decision log deferring B1/B2 split per `care-item-cross-feature-imports.md`.
Out of scope: Implementing the import-cycle split.

### Phase 6 — Batch execute-plan blob SHA checks (#2064)
```json
{
  "allowed_paths": [
    "scripts/lib/execute_plan_github.js",
    "scripts/lib/execute_plan_release.js",
    "scripts/test/execute_plan/**"
  ],
  "forbidden_paths": [".github/workflows/**"],
  "allowed_exceptions": ["tests"],
  "companions": [],
  "exit_checklist": [
    "filesUnchangedOnMain uses batched blob SHAs",
    "execute_plan unit tests green",
    "pre-push-changed green"
  ]
}
```
Scope: Batch GitHub blob SHA lookups in release unchanged-on-main check; no workflow contract change.
Out of scope: Support-PR category enforcement (#2019).

## Proof on UAT

1. Open a care occurrence via direct URL (no prior item visit); Mark as done applies the same next-dose rules as from the item hub (#1476).
2. People hub: edit vet phone, Save, reload — value persists (#1457).
3. Care item view: Needs attention and dates section show consistent Skip / Change date behaviour (#1823).
4. Owner manual (not worker): #1546 R11 checklist — care tick cron, UAT live smoke, reset repair dry-run — post results on control issue.

## Out of programme (separate tracks)

| Item | Track |
|------|--------|
| #2056, #1672, #1540 | Second plan after Phase 4 (`tech-debt-care-ux-*`) |
| #2019, #1542 | Owner decision before any autonomous CI or migration work |
| #1539, #568, #569, #1541, #1673, #570 | Relabel `tech-debt` → `feature-backlog`; not debt burn-down |
| #1546 | Ops verification on control issue; close when checklist signed |

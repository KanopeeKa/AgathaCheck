# Copy-paste prompt templates for cloud agents

Use with `/spawn-sprint-agents`. Replace placeholders in `ALL_CAPS`.

---

## Single-domain agent (direct to main)

```
Task: SPRINT_ITEM_ID — SHORT_DESCRIPTION

Branch: cursor/BRANCH_NAME-feec (from main)

Owns:
- EXACT/PATH/GLOB/**

Do not touch:
- OTHER/PATHS/**

Exit criteria:
- TEST_COMMAND passes
- node scripts/check_file_size.js
- ./scripts/pre-push-changed.sh green

Before push: git fetch origin main && git rebase origin/main
Before merge PR: ./scripts/pre-push.sh
Use skill: /SKILL_NAME if applicable
```

---

## Parallel E2E agent (integration branch)

```
Sprint: SPRINT_N — FEATURE_NAME
Integration branch: cursor/sprint-N-TOPIC-integration-13e3
Your branch: cursor/bdd-FEATURE-13e3 (from integration)

Owns:
- e2e/playwright/tests/FEATURE.spec.ts
- e2e/playwright/pages/FEATURE*.page.ts

Do not touch:
- e2e/playwright/support/api.ts (foundation already merged)

Scenarios to implement (exact titles from Gherkin):
1. Scenario: EXACT_TITLE_ONE
2. Scenario: EXACT_TITLE_TWO

Skill: /add-bdd-playwright-scenario
Verify: node e2e/scripts/check_bdd_coverage.js
During iteration: ./scripts/pre-push-changed.sh
```

---

## Foundation agent (merge first)

```
Sprint: SPRINT_N foundation
Integration branch: cursor/sprint-N-TOPIC-integration-13e3
Branch: cursor/sprint-N-foundation-13e3

Owns ONLY:
- e2e/playwright/support/api.ts
- e2e/playwright/fixtures/** (if needed)

Deliver: API helpers for FEATURE used by parallel E2E agents.
Merge to integration before other agents start.
Exit: ./scripts/pre-push-changed.sh; no spec files in this PR.
```

---

## Flutter screen split

```
Split: SCREEN_FILE.dart (CURRENT_LINES lines → <500)

Skill: /split-flutter-screen
Feature: FEATURE_NAME
Mirror tests: flutter_app/test/features/FEATURE_NAME/

Exit:
- node scripts/check_file_size.js
- flutter test test/features/FEATURE_NAME/ --concurrency=1
- Log in docs/refactoring-log.md
```

---

## Dual-backend route change

```
Endpoint: METHOD /api/PATH
Domain: DOMAIN

Skill: /dual-backend-route-change
Node: server/routes/DOMAIN/
Dart: server/lib/ matching routes
Jest: server/test/DOMAIN/

Also run: /security-error-audit before push
```

---

## Coordinator (integration → main)

```
Merge integration cursor/sprint-N-TOPIC-integration-13e3 → main

Checklist:
- [ ] All sprint items in docs/refactoring-log.md marked Done
- [ ] ./scripts/pre-push.sh green on integration tip
- [ ] BDD gate still passes
- [ ] No merge conflicts with origin/main
- [ ] /babysit until CI green and comments resolved
```

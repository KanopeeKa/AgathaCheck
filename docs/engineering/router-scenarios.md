---
title: Router scenario fixtures
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-05
tags: [agent, engineering, cursor]
---
# Router scenario fixtures

Acceptance tests for the Engineering Router. Use during framework changes and Pet Care plan authoring to verify proportional routing.

**Router:** `.cursor/agent-kernel/ROUTER.md`  
**Framework guide:** [cursor-agent-framework.md](./cursor-agent-framework.md)

---

## A — copy rename

**Input:** `/babysit-plus` Change "Health records" → "Medical history" on one screen

| Field | Expected |
|-------|----------|
| Profile | full → R0 fast path |
| Risk | R0 |
| Protocols | accessibility (quick pass), flutter-mobile (minimal) |
| Verification | flutter analyze, pre-push-changed |
| Must NOT load | database-and-migrations, security architecture, private-files |

---

## B — negative weight API

**Input:** `/babysit-plus` Weight endpoint accepts negative weights

| Field | Expected |
|-------|----------|
| Risk | R2 |
| Protocols | validation, api-contract, testing, authorization (sanity) |
| Verification | Jest domain tests, pre-push-changed |
| Notes | DB constraint if persisted; OpenAPI if maintained |

---

## C — private health documents

**Input:** `/execute-plan` Make health documents private

| Field | Expected |
|-------|----------|
| Risk | R3 |
| Protocols | security, authorization, private-files, data-lifecycle, api-contract, database-and-migrations, testing, documentation, flutter-mobile |
| Strengthen | Split phases: storage/AuthZ → API → client → integration |
| phase_fit | split-required if single phase too narrow |

---

## D — health timeline redesign

**Input:** `/ui-design-deep` Redesign health timeline

| Field | Expected |
|-------|----------|
| Profile | design-scoped |
| Risk | R1 (R2 if API contract changes) |
| Protocols | accessibility, flutter-mobile, testing; api-contract only if API changes |
| Must NOT | private-files, migrations for visual-only |

---

## E — E2E upload timeout

**Input:** `/e2e-debug` Health attachment test times out after upload

| Field | Expected |
|-------|----------|
| Profile | classify-first |
| Step 1 | Classify before test edit |
| If 403 early | authorization, api-contract — not selector timeout |
| Anti-pattern | No automatic timeout increase |

---

## F — refresh token rotation

**Input:** `/execute-plan` Add refresh token rotation

| Field | Expected |
|-------|----------|
| Risk | R3 |
| Protocols | security, database-and-migrations, flutter-mobile, testing, documentation, observability |
| Escalation | halt if crypto/session architecture unclear |

---

## G — share link expiry

**Input:** `/execute-plan` Add expiry to share links

| Field | Expected |
|-------|----------|
| Risk | R2–R3 |
| Protocols | database-and-migrations, authorization, data-lifecycle, api-contract, testing, documentation |
| Strengthen | Migration + backfill phase separate from API phase if needed |

---

## H — usability fast paths

| ID | Input | Profile | Must stay light |
|----|-------|---------|-----------------|
| H1 | babysit-plus triage-only on open PR | diff-scoped | No full domain inspect |
| H2 | babysit-plus copy change | R0 fast path | No migration/security arch |
| H3 | execute-plan resume mid-babysit | skip strengthen | Continue next_action |
| H4 | babysit-uat docs-only PR | diff-scoped | No release-verification |
| H5 | e2e-debug ENVIRONMENT class | classify-first | No product protocols |
| H6 | ui-design-deep button padding | design-scoped R0 | No private-files |

---

## Repo-specific examples

| Input | Risk | Key protocols |
|-------|------|---------------|
| Pet Care route rename `/g/*` → `/pc/*` (wire only) | R1–R2 | flutter-mobile, testing, e2e |
| Shelter org permissions endpoint | R2 | authorization, api-contract, testing |
| Health entry 5xx leak fix | R2 | security §5xx, testing regression |
| Dependabot minor bump server | R1 | dependency-review |
| New Playwright @bdd scenario | R1–R2 | testing, e2e, bdd-journey exit profile |

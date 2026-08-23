---
title: Refactoring debt tracker
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [debt, refactoring]
---
# Refactoring debt & deferred decisions

Living tracker for modularization work, items parked for human review, and architectural decisions deferred during the domain-by-domain refactor.

**Related:** [/docs/debt/deferred.md](/docs/debt/deferred.md) (cross-cutting) · [/docs/debt/technical-debt.md](/docs/debt/technical-debt.md) (legacy pointer) · `docs/architecture/modularity.md` (rules)

Domain-scoped deferrals: `docs/domains/<domain>/changes/deferred.md`

**Last updated:** 2026-08-22

---

## How to use

| Put it here | Open a GitHub Issue when |
|---|---|
| Cross-cutting refactor uncertainty | Scope is clear and someone will implement |
| Domain-scoped deferral | Use domain `changes/deferred.md` instead |

**Priority:** P1 critical · P2 high · P3 recommended · P4 for later

---

## Parked for human review (cross-cutting)

| Item | Priority | Notes |
|---|---|---|
| Root `lib/` legacy Flutter tree | P1 | **Removed** — root `pubspec.yaml` deleted Sprint 2 |
| `attached_assets/` | P1 | **Removed** — was already absent from git |
| `npm run test:mocha` | P4 | Legacy runner; remove when team confirms no local scripts use it. |
| Executable Cucumber BDD | P4 | Medium | Gherkin exists; Playwright is executor today |
| Navigation v2 shell migration backlog | P3 | Execute-plan `ui-navigation-v2-14ee` — see table below |

---

## Navigation v2 — shell migration backlog (P3)

Tracked by execute-plan `ui-navigation-v2-14ee`. Spec: `docs/archived/navigation-v2.md` (superseded).

| Tier | Scope | Status |
|------|--------|--------|
| 1 | Hub routes (`/g/home`, `/o/*` hubs, `/organizations`) | In progress (phases 2–5) |
| 2 | Deep routes (pet detail, forms, vet edit) | Pending |
| 3 | Long tail (help, paywall, transfer, archived) | Deferred |
| 4 | Out of shell (landing, anonymous shared) | N/A |

**Help copy debt:** tracked in [/docs/domains/help_about/changes/deferred.md](/docs/domains/help_about/changes/deferred.md).

---

## Node route change checklist

When changing org (or any) routes, add Jest coverage in the same PR (`single-backend.mdc`).

- [ ] Route path + HTTP method
- [ ] Auth / role guards
- [ ] Request body validation
- [ ] Response JSON shape
- [ ] Status codes (incl. 501 stubs)
- [ ] Calendar date fields (`YYYY-MM-DD`)

---

## Completed domains (modularization programme)

See [/docs/debt/refactoring-log.md](/docs/debt/refactoring-log.md) for sprint-level history. Domain deferred tables hold open items per area.

---

## Changelog

| Date | Change |
|---|---|
| 2026-08-22 | Wave 3 — domain rows moved to `docs/domains/*/changes/deferred.md`; trimmed duplicate completed tables |
| 2026-07-22 | Removed Dart backend audit doc; Node-only route checklist; stale dual-backend debt rows closed (#240). |

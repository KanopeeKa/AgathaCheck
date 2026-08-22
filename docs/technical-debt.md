# Technical debt & deferred work

> **Docs reorg (2026-08):** Cross-cutting rows live in [/docs/deferred.md](/docs/deferred.md). Domain-scoped items live in `docs/domains/<domain>/changes/deferred.md`. This file is a **legacy index pointer** — add new deferrals to the appropriate domain or cross-cutting file, not here.

Living index for historical context. Use [GitHub Issues](https://github.com/KanopeeKa/AgathaCheck/issues) when something is ready to schedule.

**Last reviewed:** 2026-08-22 (wave 3 audit)

---

## Where to file new deferrals

| Scope | File |
|-------|------|
| Platform-wide (observability, GDPR, CI) | [/docs/deferred.md](/docs/deferred.md) |
| Product domain | `docs/domains/<domain>/changes/deferred.md` |
| Refactoring / modularization uncertainty | [/docs/refactoring-debt.md](/docs/refactoring-debt.md) |

---

## Domain deferred indexes

| Domain | Deferred table |
|--------|----------------|
| Auth | [/docs/domains/auth/changes/deferred.md](/docs/domains/auth/changes/deferred.md) |
| Pet profile | [/docs/domains/pet_profile/changes/deferred.md](/docs/domains/pet_profile/changes/deferred.md) |
| Health tracking | [/docs/domains/health_tracking/changes/deferred.md](/docs/domains/health_tracking/changes/deferred.md) |
| Weight tracking | [/docs/domains/weight_tracking/changes/deferred.md](/docs/domains/weight_tracking/changes/deferred.md) |
| Vet | [/docs/domains/vet/changes/deferred.md](/docs/domains/vet/changes/deferred.md) |
| Sharing | [/docs/domains/sharing/changes/deferred.md](/docs/domains/sharing/changes/deferred.md) |
| Notifications | [/docs/domains/notifications/changes/deferred.md](/docs/domains/notifications/changes/deferred.md) |
| Organization | [/docs/domains/organization/changes/deferred.md](/docs/domains/organization/changes/deferred.md) |
| Fostering | [/docs/domains/fostering/changes/deferred.md](/docs/domains/fostering/changes/deferred.md) |
| Subscription | [/docs/domains/subscription/changes/deferred.md](/docs/domains/subscription/changes/deferred.md) |
| Help & about | [/docs/domains/help_about/changes/deferred.md](/docs/domains/help_about/changes/deferred.md) |

---

## Completed (for reference)

| Item | Done in |
|---|---|
| PostgreSQL `audit_events` + retention job | PR #48 |
| Pino structured logging + request IDs | PR #48 |
| PostHog Flutter SDK + consent gating | PR #48 |
| PostHog web snippet inject + CI/deploy secret wiring | PR #51 |
| Observability architecture doc | `docs/observability.md` |

---

## Changelog

| Date | Change |
|---|---|
| 2026-08-22 | Wave 3 audit — duplicate tables removed; domain rows migrated to `docs/domains/*/changes/deferred.md` |
| 2026-07-05 | Initial doc: observability, PostHog health-console deferrals, audit/GDPR follow-ups from PR #48/#51 work. |

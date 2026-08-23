---
title: Open debt register
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-23
tags: [debt, deferred, tech-debt]
---

# Open debt register

**OPEN items only.** When work ships, remove the row — decisions belong in domain `features/` or architecture docs; history lives in PRs and [/docs/debt/refactoring-log.md](./refactoring-log.md).

**How to file:** add a row here (or open a GitHub issue for schedulable work). Domain agents may reference this table from `changes/deferred.md` pointers.

| Domain | PR | Type | Priority | Description |
|--------|-----|------|----------|-------------|
| platform | — | tech debt | P1 | PostHog authorized URLs for prod (`https://prod.agathatrack.com`) |
| platform | — | tech debt | P2 | PostHog authorized URLs for UAT — confirm `https://uat.agathatrack.com` listed |
| platform | — | tech debt | P2 | Server PostHog person deletion on account erase (needs cPanel env vars) |
| platform | — | tech debt | P2 | Extend `audit_events` to org/sharing/foster routes (auth, pets, health partial) |
| platform | — | tech debt | P2 | Cron: `audit-retention.js` on prod/UAT — schedule daily |
| platform | — | tech debt | P2 | Uptime monitoring on `/health` (e.g. Uptime Kuma) |
| platform | #48 | tech debt | P2 | Mirror PostHog / audit retention in FR privacy notice (EN done) |
| platform | — | tech debt | P2 | Automated retention jobs (notifications, tokens) — documented, not coded |
| platform | — | tech debt | P2 | Complete `INTERNAL_GDPR.md` placeholders (DPO, DPAs, incident response) |
| platform | — | tech debt | P2 | Document PostHog env vars in deploy runbook (`docs/ops/observability.md`) |
| platform | — | tech debt | P3 | `$pageleave` events in web PostHog snippet (optional) |
| platform | — | tech debt | P3 | PostHog reverse proxy `/ingest` — defer on cPanel until infra allows |
| platform | — | tech debt | P3 | Session replay opt-in sub-toggle with strong masking |
| platform | — | tech debt | P3 | PostHog group analytics for organizations |
| platform | — | tech debt | P3 | Support query UI for audit lookup (internal admin route) |
| platform | — | tech debt | P3 | Consent preferences server-side record (client-only banner today) |
| platform | — | tech debt | P3 | Playwright E2E — consent + PostHog smoke |
| platform | — | tech debt | P4 | BDD scenarios for observability (optional Gherkin) |
| platform | — | refactor | P3 | Navigation v2 shell migration backlog (execute-plan `ui-navigation-v2-14ee`) |
| platform | — | tech debt | P4 | Remove legacy `npm run test:mocha` when no local scripts depend on it |
| platform | — | tech debt | P4 | Executable Cucumber BDD runner (Gherkin exists; Playwright is executor) |
| shelter | — | tech debt | P2 | Extend `audit_events` to org admin routes and file uploads |
| shelter | — | deferred decision | P3 | Org pet timeline — remove-event + ending notifications (Sprint 6.3 defer) |
| shelter | — | tech debt | P3 | Help FAQ copy still references legacy nav chrome — update after shell migration |
| fostering | — | tech debt | P2 | Extend `audit_events` to foster placement routes |
| sharing | — | tech debt | P2 | Extend `audit_events` to share-link routes |
| notifications | — | tech debt | P2 | Automated notification row retention (90-day policy documented, not coded) |
| subscription | — | deferred decision | P2 | `subscriptions.feature` Playwright E2E — billing provider TBD (not RevenueCat) |
| subscription | — | tech debt | P3 | RevenueCat UAT sandbox wiring — blocked on billing provider decision |
| pet_profile | — | tech debt | P4 | Rename `pet_profile_app` package (large cosmetic rename) |
| pet_profile | — | tech debt | P4 | `family_events_controller.dart` stub not wired — use foster placements |
| health_tracking | — | refactor | P4 | Optional frequency/recurrence widget extract from health entry form |
| vet | — | tech debt | P3 | Dedicated Playwright `vet.*.spec.ts` if CI scope needs explicit journey |
| help_about | — | tech debt | P3 | FAQ navigation copy update when shell migration completes |
| weight_tracking | — | tech debt | P3 | Playwright weight form stability (Flutter web fill timing) |

## Type legend

| Type | Meaning |
|------|---------|
| **tech debt** | Known gap; fix when scheduled |
| **deferred decision** | Product choice parked — implement when decision locks |
| **refactor** | Modularization or cleanup without user-visible feature |
| **other** | Ops, docs, or tooling (use sparingly) |

## Changelog

| Date | Change |
|------|--------|
| 2026-08-23 | Wave 5 phase 4 — consolidated open rows from `deferred.md`, `refactoring-debt.md`, and domain `changes/deferred.md` |

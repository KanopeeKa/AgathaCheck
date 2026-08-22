---
title: Cross-cutting deferred work
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [deferred,technical-debt,infra]
---

# Cross-cutting deferred work

Platform-wide deferrals that do not belong to a single product domain. Domain-scoped items live under `docs/domains/<domain>/changes/deferred.md`.

**Legacy index:** [/docs/technical-debt.md](/docs/technical-debt.md) (being split) · [/docs/refactoring-debt.md](/docs/refactoring-debt.md)

---

## Observability & PostHog

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| PostHog authorized URLs for prod | P1 | Trivial | Add `https://prod.agathatrack.com` in PostHog project settings |
| PostHog authorized URLs for UAT | P2 | Trivial | Confirm `https://uat.agathatrack.com` listed |
| `$pageleave` events (web snippet) | P3 | Small | Optional `capture_pageleave: true` in inject script |
| PostHog reverse proxy (`/ingest`) | P3 | Medium–high | Defer on cPanel until infra allows |
| Session replay opt-in sub-toggle | P3 | Medium | Strong masking if enabled |
| PostHog group analytics (organizations) | P3 | Small | `Posthog().group(groupType: 'organization', …)` |
| Server PostHog person deletion on account erase | P2 | Small | Needs cPanel env vars |

---

## Audit logging & retention

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| Extend `audit_events` to org/sharing/foster routes | P2 | Medium | Auth, pets, health partially covered |
| Support query UI (audit lookup) | P3 | Medium | Internal admin route |
| Cron: `audit-retention.js` on prod/UAT | P2 | Small | Schedule daily |
| Uptime monitoring | P2 | Small | e.g. Uptime Kuma on `/health` |
| Log aggregation (Loki/Grafana) | P4 | Medium | Defer until volume justifies |

---

## GDPR & compliance

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| Mirror PostHog / audit retention in FR privacy notice | P2 | Small | EN updated in #48 |
| Consent preferences server-side record | P3 | Medium | Client-only banner today |
| Automated retention jobs (notifications, tokens) | P2 | Medium | Documented, not coded |
| Complete `INTERNAL_GDPR.md` placeholders | P2 | Ongoing | DPO, DPAs, incident response |

---

## Testing & tooling

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| Playwright E2E — consent + PostHog smoke | P3 | Small | Verify analytics network call |
| BDD scenarios for observability | P4 | Small | Optional Gherkin |

---

## Infrastructure & deploy

| Item | Priority | Effort | Notes |
|------|----------|--------|-------|
| Document PostHog env vars in deploy runbook | P2 | Trivial | See `docs/observability.md` |

# Technical debt & deferred work

Living index of intentional deferrals, low-priority improvements, and follow-ups.
Use this for **context and prioritisation**; create [GitHub Issues](https://github.com/KanopeeKa/AgathaCheck/issues) when something is ready to schedule.

**Last reviewed:** 2026-07-05

---

## How to use this doc

| Put it here | Open a GitHub Issue when |
|---|---|
| Rationale, “why we deferred”, architecture notes | The item has a clear scope and might be picked up in a sprint |
| Cross-cutting themes spanning several areas | You want assignee, milestone, or PR linking (`Fixes #123`) |

**Priority key:** P1 = do soon · P2 = valuable, not urgent · P3 = nice-to-have · P4 = revisit when context changes

---

## Observability & PostHog

| Item | Priority | Effort | Notes |
|---|---|---|---|
| PostHog **authorized URLs** for prod | P1 | Trivial | PostHog project settings → add `https://prod.agathatrack.com` (and keep UAT/localhost). Clears health-console warning; improves domain filters. UI only, no code. |
| PostHog **authorized URLs** for UAT | P2 | Trivial | Confirm `https://uat.agathatrack.com` is listed if not already done during UAT setup. |
| **`$pageleave` events** (web snippet) | P3 | Small | PostHog health console warns bounce rate / session duration may be inaccurate. Flutter SPA — limited benefit vs screen events. Add `capture_pageleave: true` to `inject_posthog_web.sh` if those metrics matter. |
| PostHog **reverse proxy** (first-party `/ingest`) | P3 | Medium–high | Routes events through own domain; reduces ad-blocker loss. Defer on cPanel until infra allows reliable Apache/nginx proxy to `eu.i.posthog.com`. Revisit if consented-user vs received-event gap is large. |
| **Session replay** opt-in sub-toggle | P3 | Medium | Replay off by default (`POSTHOG_SESSION_REPLAY=false`). If enabled later, add separate consent or strong masking on health/foster/org screens. |
| PostHog **group analytics** (organizations) | P3 | Small | Call `Posthog().group(groupType: 'organization', …)` on org context for charity/rescue adoption metrics. |
| Server **PostHog person deletion** on account erase | P2 | Small | `posthogServer.js` exists but needs **cPanel Node env vars** (not GitHub secrets): `POSTHOG_PROJECT_ID`, `POSTHOG_PERSONAL_API_KEY` (personal key, not `phc_`). Wire when GDPR delete flow should purge analytics too. |

---

## Audit logging & retention

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Extend **`audit_events`** to org/sharing/foster routes | P2 | Medium | Auth, pets, and health entry flows covered. Still missing: org admin, share links, foster placements, file uploads, vet/weight CRUD. |
| **Support query UI** (audit lookup by user/pet) | P3 | Medium | Today: SQL on `audit_events` + domain tables (`health_history`, etc.). Internal admin route or gated dashboard beats raw DB access for support staff. |
| **Cron: `audit-retention.js`** on prod/UAT | P2 | Small | Job exists (`npm run audit-retention`); schedule daily on server (cron or cPanel). Hot→warm→cold tiers otherwise never run. |
| **Uptime monitoring** | P2 | Small | e.g. Uptime Kuma pinging `/health` and `/backend/health`. Not implemented; PostHog does not replace this. |
| **Log aggregation** (Loki/Grafana) | P4 | Medium | Pino JSON logs to stdout/files suffice for now. Revisit when log volume or incident frequency justifies it. |

---

## GDPR & compliance

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Mirror **PostHog / audit retention** in **FR privacy notice** | P2 | Small | EN privacy notice updated in #48; FR `politique-de-confidentialite.md` not yet aligned. |
| **GDPR export** completeness | — | Done (5.5) | `/me/export` includes health, weight, org, sharing, notifications |
| **Consent preferences** server-side record | P3 | Medium | Consent banner is client-only (`SharedPreferences`). Consider persisting consent timestamp + choices for auditability. |
| Automated **retention jobs** (notifications, tokens) | P2 | Medium | Documented in `INTERNAL_GDPR.md` (90-day notifications, token purge) but not coded. |
| Complete **`INTERNAL_GDPR.md`** placeholders | P2 | Ongoing | DPO, hosting provider DPAs, incident response plan, supervisory authority — marked TO BE COMPLETED. |

---

## Subscriptions & billing (deferred — product review)

| Item | Priority | Effort | Notes |
|---|---|---|---|
| **`subscriptions.feature` Playwright E2E** | P2 | Medium | **Deferred Sprint 7.2.** Requires functional review: operator is likely moving away from RevenueCat toward an **EU-based billing solution**. Do not invest in RevenueCat sandbox E2E until billing architecture is decided. Gherkin spec (`subscriptions.feature`, 11 scenarios) remains for future implementation. |
| RevenueCat UAT sandbox wiring | P3 | Medium | Blocked on billing provider decision above. |

---

## Testing & tooling

| Item | Priority | Effort | Notes |
|---|---|---|---|
| **Playwright E2E** — consent + PostHog smoke | P3 | Small | E2E foundation merged (#47). Add: accept analytics → verify network call to `eu.i.posthog.com` (or mock). |
| **BDD** scenarios for observability | P4 | Small | Optional Gherkin for consent-gated analytics if product wants regression coverage. |

---

## Infrastructure & deploy

| Item | Priority | Effort | Notes |
|---|---|---|---|
| Document **PostHog env vars** in deploy runbook | P2 | Trivial | `POSTHOG_API_KEY` GitHub secret + inject script documented in `docs/observability.md`. Add one-liner to `replit.md` or deployment doc if team uses cPanel checklist. |
| **Dart server parity** for audit/PostHog | P4 | Medium | Node backend is canonical; Shelf Dart routes not wired to audit helper or PostHog delete. Only matters if Dart server used in prod. |

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
| 2026-07-05 | Initial doc: observability, PostHog health-console deferrals, audit/GDPR follow-ups from PR #48/#51 work. |

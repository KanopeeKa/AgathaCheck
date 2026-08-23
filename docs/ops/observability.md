---
title: Observability and audit logging
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-21
tags: [documentation]
---
# Observability and audit logging

Agatha Track uses a layered observability model:

| Layer | Purpose | Implementation |
| --- | --- | --- |
| **Audit trail** | Who changed what (support + compliance) | PostgreSQL `audit_events` |
| **Security logs** | Auth and account actions | Same `audit_events` table |
| **Application logs** | Request timing, errors (engineering) | [Pino](https://getpino.io/) JSON logs |
| **Product analytics** | Feature usage (consent-gated) | [PostHog Cloud EU](https://eu.posthog.com/) |

## Audit events (`audit_events`)

Schema: `db/migrations/019_audit_events.sql`

Each row captures:

- **Actor** — `actor_user_id` (hot tier only), later `actor_pseudonym`
- **Action** — e.g. `auth.login`, `pet.created`, `health_entry.marked_complete`
- **Resource** — `resource_type`, `resource_id`, optional `pet_id` / `org_id`
- **Context** — `request_id`, IP, user agent (hot tier only)
- **Metadata** — JSON field names and counts only; never health/foster payloads

### Retention tiers

Enforced by `server/scripts/audit-retention.js` (run daily via cron):

| Tier | Duration | Contents |
| --- | --- | --- |
| **hot** | 14 days (default) | Full actor + IP + user agent |
| **warm** | 90 days total | Pseudonymized actor (`md5(user_id + salt)`), no IP/UA |
| **cold** | 730 days total | Action + resource IDs only; metadata cleared |
| **purge** | After cold window | Row deleted |

Configure via environment:

```bash
AUDIT_HOT_DAYS=14
AUDIT_WARM_DAYS=90
AUDIT_COLD_DAYS=730
AUDIT_PSEUDONYM_SALT=<random-secret>
```

Run retention manually:

```bash
cd server
PGUSER=user PGPASSWORD=password PGHOST=localhost PGDATABASE=agatha_db \
  node scripts/audit-retention.js
```

### Writing audit events (server)

```javascript
import { logAuditEventSafe } from '../lib/audit.js';

logAuditEventSafe(pool, {
  actorUserId: userId,
  action: 'pet.updated',
  resourceType: 'pet',
  resourceId: petId,
  petId,
  metadata: { fields: ['name', 'species'] },
  req,
});
```

Failures are logged but never block the API response.

## Product activity (`pet_activity_events`)

Organisation v2 introduces a **product** activity layer for last-activity sorting — separate from audit and timeline:

| Concern | Table / column | Writer |
| --- | --- | --- |
| Product activity | `pet_activity_events`, `pets.last_activity_at` | `recordPetActivity()` in `server/lib/petActivity.js` |
| Compliance audit | `audit_events` | `logAuditEventSafe()` |
| Guardian timeline | `pet_timeline_entries` | Timeline routes |

- Activity events store **event type + safe metadata only** (no health/foster payloads).
- `last_activity_at` is updated in the **same transaction** as the event insert.
- No backfill — see `docs/architecture/pet-activity-model.md`.

## Structured application logs

- **Library:** `pino` (`server/lib/logger.js`)
- **Request IDs:** `X-Request-Id` header (`server/middleware/requestContext.js`)
- **Scope:** API routes under `/api/`, `/backend/api/`, `/server/api/`
- **Level:** `LOG_LEVEL` env (default `info` in production, `debug` otherwise)

## PostHog (product analytics)

- **Region:** EU (`https://eu.i.posthog.com`) by default
- **Legal basis:** Consent (Art. 6(1)(a) GDPR) via the in-app consent banner
- **SDK:** `posthog_flutter` **plus** PostHog JS in `web/index.html` (required for Flutter web)

Flutter web assumes `posthog-js` is loaded in HTML before the app starts. CI/deploy runs
`flutter_app/scripts/inject_posthog_web.sh` using the `POSTHOG_API_KEY` GitHub secret.

**Local build:**
```bash
cd flutter_app
export POSTHOG_API_KEY=phc_xxx
bash scripts/inject_posthog_web.sh
flutter build web --release --no-tree-shake-icons \
  --dart-define=POSTHOG_API_KEY=$POSTHOG_API_KEY \
  --dart-define=POSTHOG_HOST=https://eu.i.posthog.com
```

The HTML snippet uses `opt_out_capturing_by_default: true`; Dart calls `Posthog().enable()`
only after analytics consent.

- **Session replay:** Off by default. Enable with `--dart-define=POSTHOG_SESSION_REPLAY=true` (masks all text/images).
- **Sensitive screens** excluded from screen tracking: health dashboards/forms, org person detail, account details.

**`posthogServer.js` (optional — account deletion only, not event capture):** needs server env vars on cPanel/Node, not the project API key:
```bash
POSTHOG_HOST=https://eu.posthog.com
POSTHOG_PROJECT_ID=<numeric id from PostHog project settings/URL>
POSTHOG_PERSONAL_API_KEY=<personal API key with person delete scope>
```
GitHub secrets used for Flutter builds do not configure the Node server automatically.

## Support investigation workflow

1. **Last 14 days:** Query `audit_events` by `actor_user_id` or `resource_id` (hot tier).
2. **Domain tables:** Join `health_history`, `family_event_history` for business context.
3. **Request correlation:** Match `request_id` in Pino logs.
4. **UX issues (consented users):** PostHog person timeline + session replay.
5. **After 14 days:** Search warm tier by `actor_pseudonym` + resource ID.

Example SQL:

```sql
SELECT occurred_at, action, resource_type, resource_id, outcome, metadata
FROM audit_events
WHERE actor_user_id = '<user-uuid>'
  AND occurred_at > NOW() - INTERVAL '14 days'
ORDER BY occurred_at DESC;
```

## What we deliberately do not log

- Passwords, tokens, reset codes
- Health record contents (medication names, notes, vet details)
- Foster contact PII
- Full request/response bodies

## Related documents

- `regulatory/INTERNAL_GDPR.md` — processing register and retention
- `regulatory/DATA_MAP.md` — field inventory including audit/analytics
- `flutter_app/assets/legal/en/privacy-notice.md` — user-facing disclosure

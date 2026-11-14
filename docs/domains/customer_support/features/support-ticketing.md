---
title: Support ticketing and contact hub
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-14
tags: [domain, customer_support, support-ticketing]
domain: customer_support
feature_id: support-ticketing
---

# Support ticketing and contact hub

## Summary / scope

- **Owns:** EN/FR contact hub, private support intake, Postgres tickets, one receipt email, private GitHub issues on @ATSupport, read-only staff queue, retention and erasure hooks.
- **Does not own:** In-app ticket history or replies, customer-visible statuses, status-change emails, notification-bell events, diagnostic sessions, AI triage, automatic engineering handover, live chat, public AgathaTrack engineering support issues.
- **Depends on:** Auth (optional submit), Nodemailer SMTP, private screenshot storage outside `uploads/`, Postgres migrations, AgathaTrackPrivate + built-in board auto-add.

Anyone signed in or not can send a categorised request from the hub. It is stored privately with an `AT-` reference, acknowledged by email, and appears as an issue in **AgathaTrackPrivate** on the **@ATSupport** board. Conversation after the receipt continues by email from `support@`. Engineering work is handed to AgathaTrack by a human with personal content stripped first.

Roadmap: [support-roadmap.md §4](../changes/support-roadmap.md#4-phase-1--contact-foundation-and-ticketing). Product spec source: [issue #2271](https://github.com/AgathaTrack/AgathaTrack/issues/2271). Ops: [support-intake-runbook.md](/docs/ops/support-intake-runbook.md).

## Vocabulary

[terminology.md](/docs/design/terminology.md) §Customer support vs directory contacts.

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-TICKETING-R-001 | Contact hub reachable from Account **and** the sign-in (landing) footer; route on the public allowlist; cards: Help & Support (form), Partnerships, Legal & Privacy; general line for `contact@agathatrack.com`. | In delivery |
| SUPPORT-TICKETING-R-002 | Help & Support opens the form; Partnerships and Legal & Privacy use `launchExternalLink` with copy fallback; Account mailto replaced; dead `drawer_contact` case deleted. | In delivery |
| SUPPORT-TICKETING-R-003 | One-column hub layout (stacked cards on all widths), consistent with Help and About. | In delivery |
| SUPPORT-TICKETING-R-004 | Show `contact@`, `support@`, `legal@`, `partnerships@` (mailboxes are an ops prerequisite). | In delivery |
| SUPPORT-TICKETING-R-005 | `POST /api/support/tickets` (+ `/backend`); handler decides sign-in (no bearer = signed out; invalid bearer = 401); signed-in receipt uses `users.email`; signed-out requires email; reference `AT-` + 8 Crockford base32; UUIDs in app code; multipart for screenshots, JSON for text-only; coming-soon 403 before handler. | In delivery |
| SUPPORT-TICKETING-R-006 | Categories `bug`, `suggestion`, `account`, `billing`; title + description always; bug fields (expected, actual, steps, frequency always/sometimes/once) without focus jump. | In delivery |
| SUPPORT-TICKETING-R-007 | Context allowlist only: version/build from site-root `GET /version.json` (cache-bust; empty if missing); platform (`web` on web); coarse browser family; locale; route name; client time; server timestamp authoritative; CI asserts `version.json` beside `index.html`. | In delivery |
| SUPPORT-TICKETING-R-008 | Screenshots: signed-in only; max 3 files, 2 MB each, 6 MB total; PNG/JPEG/WebP via `safeUpload`; storage outside `uploads/`, not static; `fileDelete.js` key `support_screenshots`; staff-only `GET /api/support/attachments/:id` (403 before lookup for non-staff); PII notice before upload; re-encoding is debt (`sharp`). | In delivery |
| SUPPORT-TICKETING-R-009 | Ticket row: reporter (user or normalised email), category, title, description, bug fields, context, locale, `created_at`, `github_issue_number`; no priority; users cannot read tickets via API. | In delivery |
| SUPPORT-TICKETING-R-010 | Tables `support_tickets`, `support_attachments`, `support_outbox` (message/status history and links deferred). | In delivery |
| SUPPORT-TICKETING-R-011 | Design note: diagnostic metadata not in the ticket blob; Phase 3 adds `support_diagnostic_sessions`. | Planned |
| SUPPORT-TICKETING-R-012 | Customer-visible lifecycle states (deferred beyond Phase 1; @ATSupport columns are internal only). | Planned |
| SUPPORT-TICKETING-R-013 | DB category is sender choice; `category:*` label in GitHub is staff classification; priority is a GitHub label only. | Planned |
| SUPPORT-TICKETING-R-014 | Read-only staff at `/staff/support` (list, detail, screenshots, blocked/failed outbox); no reply/assign/close; no menu entry; server enforces `is_support_staff`. | In delivery |
| SUPPORT-TICKETING-R-015 | Emails on status changes (deferred beyond Phase 1). | Planned |
| SUPPORT-TICKETING-R-016 | One receipt EN/FR via outbox; subjects `[AT-XXXXXXXX] We received your request` / `[AT-XXXXXXXX] Nous avons reçu votre demande`; Reply-To `support@`; body never repeats user text; `resolveEmailLocale`. | In delivery |
| SUPPORT-TICKETING-R-017 | Outbox: `receipt`, `github_issue`, `github_issue_delete`; Node `fetch`; create-issue title `[AT-XXXXXXXX] <category>: <title>`; fenced untrusted body + allowlisted context; labels `category:*`, `env:*`, `source:form`; statuses pending/sent/failed/blocked/disabled; skip receipt/create if ticket gone; redact from stored issue number; startup privacy check for repo; 422 label = config failure. | In delivery |
| SUPPORT-TICKETING-R-018 | SQL rate limits: signed-in 3/h and 10/24h per account; signed-out 3/h per IP and 5/24h per normalised email; 429 + `Retry-After`; field max lengths; express-rate-limit backstop only with default key. | In delivery |
| SUPPORT-TICKETING-R-019 | Daily `support_retention` on `scheduler_daily_runs`; erasure in `acceptAccountErasure` before user delete (tickets, paths, issue numbers, outbox, redact rows); export matches normalised email; hand `source:email` issues per runbook. | In delivery |
| SUPPORT-TICKETING-R-020 | EN/FR UI (`app_*.arb`) and email copy (`server/lib/email/i18n.js`); no machine translation of free text. | In delivery |
| SUPPORT-TICKETING-R-021 | WCAG 2.2 AA across hub, form, screenshots (labels, error summary, keyboard controls, both languages). | In delivery |
| SUPPORT-TICKETING-R-022 | Support data is private customer data; GitHub only in AgathaTrackPrivate; engineering AgathaCheck issues carry no user text; privacy notice names GitHub and 7-day redacted-issue deletion. | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given a signed-out visitor on the landing page, when they open Contact and submit a valid bug report, then they see an `AT-` reference, a receipt is queued, and an issue is queued for AgathaTrackPrivate. | SUPPORT-TICKETING-R-001, SUPPORT-TICKETING-R-005, SUPPORT-TICKETING-R-016, SUPPORT-TICKETING-R-017 | none — #2271 |
| Given a signed-in user, when they submit with a different email in the body, then the receipt goes to their account email. | SUPPORT-TICKETING-R-005 | test: server/test/support/ticketsSubmit.test.js |
| Given a request with an invalid token, when submitted, then the API returns 401 and no ticket is created. | SUPPORT-TICKETING-R-005 | test: server/test/support/ticketsSubmit.test.js |
| Given the Partnerships card, when the email link cannot open, then a copy dialog shows `partnerships@`. | SUPPORT-TICKETING-R-002, SUPPORT-TICKETING-R-004 | none — #2271 |
| Given a signed-out sender, when the request includes a screenshot, then the API rejects it. | SUPPORT-TICKETING-R-008 | test: server/test/support/supportScreenshots.test.js |
| Given a stored screenshot, when requested via `/uploads/…`, or by a signed-in non-staff user, or with a guessed id, then responses are 404, 403, and 403 respectively. | SUPPORT-TICKETING-R-008 | test: server/test/support/supportScreenshots.test.js |
| Given 3 tickets in the past hour from one account, when a 4th is submitted, then the API returns 429 with `Retry-After`. | SUPPORT-TICKETING-R-018 | test: server/test/db/support/ticketsRateLimit.integration.test.js |
| Given SMTP and GitHub are down, when a ticket is submitted, then the ticket is saved and outbox rows retry later. | SUPPORT-TICKETING-R-016, SUPPORT-TICKETING-R-017 | none — #2271 |
| Given `SUPPORT_GITHUB_REPO` points at a public repo, when the worker starts, then create-issue rows are `blocked`; when a later check sees a private repo, those rows return to `pending`. | SUPPORT-TICKETING-R-017 | none — #2271 |
| Given a user with signed-in and signed-out tickets, when their account is erased, then tickets, screenshots, and pending outbox rows are gone, redact rows are queued, and erasure still commits. | SUPPORT-TICKETING-R-019 | test: server/test/support/retentionErasure.test.js |
| Given a create-issue call that finishes after erasure deleted the ticket, when the worker writes the issue number back, then it queues a redact row for that number. | SUPPORT-TICKETING-R-017, SUPPORT-TICKETING-R-019 | none — #2271 |
| Given a user exports their data, when they have tickets, then the export includes signed-out tickets with the same normalised email. | SUPPORT-TICKETING-R-019 | test: server/test/gdprUserExport.test.js |
| Given a user who is not staff, when they call the staff API, then the response is 403; `/staff/support` has no menu entry. | SUPPORT-TICKETING-R-014 | test: server/test/support/staffTickets.test.js |
| Given French locale, when a ticket is submitted, then form, errors, confirmation, and receipt (including subject) are in French. | SUPPORT-TICKETING-R-016, SUPPORT-TICKETING-R-020 | none — #2271 |

## States & data

**`support_tickets`:** `id`, `reference`, `user_id`, `reporter_email`, `reporter_email_normalised`, `signed_in`, `submit_ip` (signed-out rate limits only), `category`, `title`, `description`, `expected`, `actual`, `steps`, `frequency`, `context` (allowlisted JSON), `locale`, `created_at`, `github_issue_number`.

**`support_attachments`:** `id`, `ticket_id`, `storage_key`, `mime`, `bytes`, `created_at`.

**`support_outbox`:** `id`, `ticket_id`, `kind` (`receipt`, `github_issue`, `github_issue_delete`), `github_issue_number`, `status`, `attempts`, `next_attempt_at`, `last_error` (never user text). Constraints: `ticket_id` required for receipt/create; empty for redact; `github_issue_number` required for redact; uniqueness per plan phase 3.

**Endpoints** (each also under `/backend`): `POST /api/support/tickets`; `GET /api/support/staff/tickets` (+ `/:id`); `GET /api/support/attachments/:id`. OpenAPI: `docs/architecture/openapi/support-tickets.json` (companion, not folded into `pet-care-critical.json`).

**Settings:** `SUPPORT_GITHUB_REPO`, `SUPPORT_GITHUB_TOKEN`, `SUPPORT_REPLY_TO`, `APP_ENV` (not `NODE_ENV`) for `env:*` labels.

Worker: outbox drain and `support_retention` run from the existing cleanup poll; `file_delete` gains the private screenshot storage key.

## UX surfaces

- Contact hub `/contact` — **in delivery** (`flutter_app/lib/features/support/hub/`): Account row + landing footer (`LegalFooterLinks`); `/contact/support` registers the intake form route (UI in phase 4).
- Support form `/contact/support` — **in delivery** (`flutter_app/lib/features/support/form/`): categorised intake, error summary, optional signed-in screenshots (`flutter_app/lib/features/support/screenshots/`), `POST /api/support/tickets`, context from `version.json` + browser UA.
- Staff read-only queue `/staff/support` — **in delivery** (`flutter_app/lib/features/support/staff/`): no drawer entry; deep URL only; staff API at `GET /api/support/staff/tickets` (+ `/:id`).

## Out of scope (Phase 1)

In-app replies or ticket history, customer-visible statuses, status-change emails, notification-bell events, diagnostic sessions, AI triage, automatic engineering handover, live chat, `support` GitHub label, board token / Actions add-to-project workflow, issues in public AgathaTrack.

## Still open

- Mailboxes `support@`, `legal@`, `partnerships@` (ops); `contact@` exists.
- UAT: set `SUPPORT_REPLY_TO=support@agathatrack.com` before receipt smoke tests.
- @ATSupport smoke test: manual issue lands in New, close moves to Done, pawpet board unchanged.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-TICKETING-D-001 | Native AgathaTrack ticketing in Postgres | Avoid helpdesk SaaS; own records for automation later | Live | 2026-11-11 | TBD |
| SUPPORT-TICKETING-D-002 | `customer_support` domain slug; code under `support/` not `contact/` | Disambiguate from People directory Contacts | Live | 2026-11-11 | TBD |
| SUPPORT-TICKETING-D-003 | Phase 1 is intake only; after receipt, conversation continues by email from `support@` | Clear support boundary for users | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-004 | Workflow on @ATSupport (`users/KanopeeKa/projects/4`); built-in auto-add `is:issue`; category/priority as GitHub labels; no `support` label | Confirmed auto-add; DB stores category + issue number only | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-005 | `users.is_support_staff` via `server/scripts/support_staff.js` only; not in profile or tokens; DB lookup per staff request; any staff can read all tickets | Simple ops model; closed former “admin role” open point | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-006 | Agents use `pawpet-bot`; may comment/label; cannot move board cards; issue text untrusted | Token cannot reach personal board fields | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-007 | Retention from submission: tickets 12 months, screenshots 90 days | Bounded private data | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-008 | Issues only in private AgathaTrackPrivate; startup check; empty repo → `disabled`; non-private → `blocked` then `pending` when fixed | Never leak support content to public repo | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-009 | No API issue delete; erasure/retention **redact** title/body to `[removed]` + `redacted` label; owner deletes issue within 7 days (`Redacted: delete` view) | Removes edit history and comments when owner deletes | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-010 | Engineering handover is human; AgathaCheck issue from template with `AT-` ref only; Phase 4+ may automate; agent comments removed only when redacted issue deleted | No PII in public engineering backlog | Live | 2026-11-13 | TBD |
| SUPPORT-TICKETING-D-011 | Email stays Nodemailer + SMTP; Brevo not adopted | Closed former Brevo open point | Live | 2026-11-13 | TBD |

## Related

| Kind | Link |
| ---- | ---- |
| Roadmap | [support-roadmap.md](../changes/support-roadmap.md) |
| Ops runbook | [support-intake-runbook.md](/docs/ops/support-intake-runbook.md) |
| Help | [help_about/specs.md](/docs/domains/help_about/features/specs.md) |
| Mail | [observability.md](/docs/ops/observability.md) |

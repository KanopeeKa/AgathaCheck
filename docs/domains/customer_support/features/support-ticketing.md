---
title: Support ticketing and contact hub
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, support-ticketing]
domain: customer_support
feature_id: support-ticketing
---

# Support ticketing and contact hub

## Summary / scope

- **Owns:** Contact hub, support submission, ticket persistence, customer-visible status, basic admin reply, transactional email notifications for support.
- **Does not own:** People directory contacts, in-app notification feed, FAQ content ([help_about](/docs/domains/help_about/README.md)), automated triage (Phase 4+).
- **Depends on:** Auth, mail transport, private file storage, Postgres migrations.

Roadmap: [support-roadmap.md §4](../changes/support-roadmap.md#4-phase-1--contact-foundation-and-ticketing).

## Vocabulary

[terminology.md](/docs/design/terminology.md) §Customer support vs directory contacts.

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-TICKETING-R-001 | Contact hub reachable from Account (and consistent with navigation §Account utilities); three routes: Help & Support, Partnerships, Legal & Privacy. | Planned |
| SUPPORT-TICKETING-R-002 | Help & Support opens in-app adaptive support form; Partnerships and Legal & Privacy use mailto or copyable email with accessible fallback when launch fails. | Planned |
| SUPPORT-TICKETING-R-003 | Hub layout works on desktop, tablet, and mobile (stacked cards on narrow viewports). | Planned |
| SUPPORT-TICKETING-R-004 | Product exposes distinct support, partnerships, legal, and privacy contact addresses (routing/inbox rules documented in ops after audit). | Planned |
| SUPPORT-TICKETING-R-005 | Authenticated users submit via API; valid submissions create persistent tickets with human-readable reference numbers. | Planned |
| SUPPORT-TICKETING-R-006 | Form collects category, title, description; bug path adds expected/actual behaviour, steps, frequency with progressive disclosure. | Planned |
| SUPPORT-TICKETING-R-007 | Server stores permitted technical context (app version, browser family, platform, language, page id, timestamp) without arbitrary PII payloads. | Planned |
| SUPPORT-TICKETING-R-008 | Optional screenshots: private storage, validation, size limits, access control; only ticket parties and authorised support staff. | Planned |
| SUPPORT-TICKETING-R-009 | Ticket row: reporter, type, title, priority, status; users cannot read other users' tickets. | Planned |
| SUPPORT-TICKETING-R-010 | Messages, status history, attachments, external links (PostHog/GitHub placeholders), and notification outbox rows persist with audit-friendly history. | Planned |
| SUPPORT-TICKETING-R-011 | Diagnostic session metadata is not stored inside the main ticket blob; Phase 3 adds `support_diagnostic_sessions`. | Planned |
| SUPPORT-TICKETING-R-012 | Customer-visible lifecycle states; internal substates (e.g. `needs_information`, `fix_proposed`, `awaiting_release`) allowed. | Planned |
| SUPPORT-TICKETING-R-013 | Category, technical classification, and status are separate fields (reclassification without rewriting submission category). | Planned |
| SUPPORT-TICKETING-R-014 | Restricted admin/support view: read, reply, classify, assign, close; lightweight customer ticket history in app. | Planned |
| SUPPORT-TICKETING-R-015 | Email on meaningful status changes via outbox queue; ticket save succeeds if provider is temporarily down. | Planned |
| SUPPORT-TICKETING-R-016 | Templates minimum set: received, additional information needed, investigation update, resolved; dedupe on retry. | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given a signed-in user on the contact hub When they submit a valid bug report Then a ticket reference is shown and email acknowledgement is queued | SUPPORT-TICKETING-R-005, R-015 | TBD — phase 1 issue |
| Given a user opens their ticket When support posts a reply Then the user sees the message in-app | SUPPORT-TICKETING-R-010, R-014 | TBD — phase 1 issue |
| Given user A When they request ticket ids belonging to user B Then the API returns forbidden/not found | SUPPORT-TICKETING-R-009 | TBD — phase 1 issue |
| Given partnerships route When selected Then mailto or copy uses partnerships address not support queue | SUPPORT-TICKETING-R-002, R-004 | TBD — phase 1 issue |

## States & data

Indicative entities: `support_tickets`, `support_messages`, `support_status_history`, `support_attachments`, `support_issue_links`, `support_notifications`. API surface TBD in execute-plan after phase audit.

## UX surfaces

- Replace or extend Account **Contact** (`account_screen.dart`) with hub route.
- Customer ticket list/detail TBD.
- Admin console TBD (role-gated).

## Out of scope (Phase 1)

AI classification, diagnostic mode, GitHub issue automation, live chat.

## Still open

- Brevo API vs existing Nodemailer SMTP (phase audit).
- Support admin role model (phase audit).

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-TICKETING-D-001 | Native AgathaTrack ticketing in Postgres | Avoid helpdesk SaaS; own records for automation later | Live | 2026-11-11 | TBD |
| SUPPORT-TICKETING-D-002 | `customer_support` domain slug; code under `support/` not `contact/` | Disambiguate from People directory Contacts | Live | 2026-11-11 | TBD |

## Related

| Kind | Link |
| ---- | ---- |
| Roadmap | [support-roadmap.md](../changes/support-roadmap.md) |
| Help | [help_about/specs.md](/docs/domains/help_about/features/specs.md) |
| Mail | [observability.md](/docs/ops/observability.md) |

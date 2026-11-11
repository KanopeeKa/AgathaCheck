---
title: Support diagnostic sessions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, diagnostics]
domain: customer_support
feature_id: support-diagnostics
---

# Support diagnostic sessions

## Summary / scope

- **Owns:** Server-authorised five-minute diagnostic sessions, optional support codes, enhanced allowlisted events, optional masked replay, diagnostic report metadata on tickets.
- **Does not own:** Always-on DEBUG logging; product analytics outside an active session.

Roadmap: [support-roadmap.md §6](../changes/support-roadmap.md#6-phase-3--temporary-diagnostic-sessions).

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-DIAGNOSTICS-R-001 | User starts diagnostics from own ticket (self-service) without a code. | Planned |
| SUPPORT-DIAGNOSTICS-R-002 | Support can issue single-use expiring code bound to user + ticket; only hashed code stored; rate-limited. | Planned |
| SUPPORT-DIAGNOSTICS-R-003 | `support_diagnostic_sessions` records id, ticket_id, user_id, client_session_id, started/expires/stopped, status, volume, optional posthog_session_id. | Planned |
| SUPPORT-DIAGNOSTICS-R-004 | Five-minute server expiry; client countdown; stop on logout/revoke; client stops if timer expires offline. | Planned |
| SUPPORT-DIAGNOSTICS-R-005 | Persistent in-app indicator, Stop control, plain-language collection summary. | Planned |
| SUPPORT-DIAGNOSTICS-R-006 | Extra diagnostic events only while session active; normal logging unchanged. | Planned |
| SUPPORT-DIAGNOSTICS-R-007 | Event families: user action, UI transition, API call, validation, data operation, performance, unexpected behaviour — allowlisted metadata only. | Planned |
| SUPPORT-DIAGNOSTICS-R-008 | Optional PostHog replay: programmatic start/stop; mask inputs/text; no unsafe network bodies by default. | Planned |
| SUPPORT-DIAGNOSTICS-R-009 | Server assembles bounded report (summary, environment, timeline, backend refs, optional replay link, investigator notes). | Planned |
| SUPPORT-DIAGNOSTICS-R-010 | Raw diagnostic telemetry retention 7–14 days (product/privacy sign-off). | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given active diagnostics When five minutes elapse Then collection stops client- and server-side | SUPPORT-DIAGNOSTICS-R-004 | TBD — phase 3 issue |
| Given completed session When staff opens ticket report Then timeline excludes non-session unrelated activity | SUPPORT-DIAGNOSTICS-R-009 | TBD — phase 3 issue |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-DIAGNOSTICS-D-001 | Structured events mandatory; replay optional | Privacy if masking cannot be guaranteed | Live | 2026-11-11 | TBD |

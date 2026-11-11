---
title: Support observability and correlation
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, observability]
domain: customer_support
feature_id: support-observability
---

# Support observability and correlation

## Summary / scope

- **Owns:** Support-oriented error capture, structured logging schema, correlation from ticket → technical events, redaction policy tests, monitoring hooks for support jobs.
- **Does not own:** General audit trail ([observability.md](/docs/ops/observability.md) audit_events), product analytics consent UI.
- **Depends on:** Phase 1 ticket links (`support_issue_links`), existing `request_id` on API errors.

Roadmap: [support-roadmap.md §5](../changes/support-roadmap.md#5-phase-2--observability-and-reliable-diagnostic-context).

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-OBSERVABILITY-R-001 | Unhandled FE exceptions and relevant BE failures reach PostHog Error Tracking (or agreed equivalent) with app version and grouping. | Planned |
| SUPPORT-OBSERVABILITY-R-002 | Production JS errors support source maps where deployed. | Planned |
| SUPPORT-OBSERVABILITY-R-003 | Operational logs use fixed schema (level, service, operation, result, error_code, request_id, app_version, diagnostic_id). | Planned |
| SUPPORT-OBSERVABILITY-R-004 | No arbitrary payloads, pet notes, tokens, or form contents in exported logs. | Planned |
| SUPPORT-OBSERVABILITY-R-005 | Distinct identifiers: support ticket id, request/trace id, browser session id, diagnostic session id (Phase 3). | Planned |
| SUPPORT-OBSERVABILITY-R-006 | Support ticket id is not reused as primary log correlation id. | Planned |
| SUPPORT-OBSERVABILITY-R-007 | Staff can navigate from ticket to correlated PostHog/log references stored on `support_issue_links`. | Planned |
| SUPPORT-OBSERVABILITY-R-008 | Allowlist-based logging policy documented; redaction tests in CI. | Planned |
| SUPPORT-OBSERVABILITY-R-009 | Failed support notification / sync jobs raise alerts (e.g. healthchecks.io or existing health pattern). | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given a failed save operation When support opens linked ticket Then correlated FE error and BE log references are reachable | SUPPORT-OBSERVABILITY-R-001, SUPPORT-OBSERVABILITY-R-007 | none — #2272 |
| Given a log export When scanned Then prohibited fields are absent per policy | SUPPORT-OBSERVABILITY-R-004, SUPPORT-OBSERVABILITY-R-008 | none — #2272 |

## Out of scope (Phase 2)

Five-minute diagnostic mode, session replay for support, GitHub automation.

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-OBSERVABILITY-D-001 | Reuse PostHog EU project unless audit finds hard limit | Cost and existing wiring | Live | 2026-11-11 | TBD |

---
title: Contact, support and automated bug resolution roadmap
owner: Product / Documentation
audience: both
status: proposed
status_since: 2026-11-11
last_updated: 2026-11-13
tags: [customer_support, roadmap, support]
folds_into: docs/domains/customer_support/features/support-ticketing.md
---

# Contact, support and automated bug resolution roadmap

Functional specifications, technical approach, vendor notes, and phased delivery for **customer support** on AgathaTrack.

**Canonical requirements** by phase: `../features/support-*.md`. **Terminology:** [terminology.md](/docs/design/terminology.md) §Customer support vs directory contacts.

## 1. Executive recommendation

Build a **native AgathaTrack support system** with progressive AI automation — not a large customer-support SaaS.

Objectives (end state):

1. Receive and acknowledge user requests.
2. Collect privacy-safe diagnostic evidence.
3. Classify issues and identify probable duplicates.
4. Ask users to reproduce via temporary diagnostic sessions.
5. Investigate bugs with an AI coding agent.
6. Propose fixes through pull requests.
7. Route behavioural changes and feature requests into a product backlog.
8. Keep users informed until resolution.

**Architectural decision:** AgathaTrack owns customer support records; GitHub and Cursor own engineering work. See [SUPPORT-TICKETING-D-001](../features/support-ticketing.md#decision-log).

## 2. Current situation versus target

| Component | Current (code-verified where noted) | Target |
| --------- | ----------------------------------- | ------ |
| Contact entry | Account **Contact** → `mailto:contact@agathatrack.com` | Contact hub: Help & Support, Partnerships, Legal & Privacy |
| Customer support workflow | None | Native tickets, reference IDs, status history |
| Partnerships / legal | Same mailto | Distinct visible addresses; legal/privacy separable from support queue |
| Product analytics | PostHog EU (see [observability.md](/docs/ops/observability.md)) | Reuse for diagnostic context |
| Error monitoring | PostHog; production depth unverified | Reliable baseline errors + correlated logs |
| Temporary diagnostics | None | User-activated five-minute sessions |
| Session replay | PostHog; config unverified | Optional, tightly controlled |
| Engineering backlog | GitHub (assumed) | Private technical issues linked to tickets |
| AI development | Cursor (manual) | Automated investigation and fix PRs (Phase 5) |
| Transactional email | Nodemailer ([mail.js](/server/config/mail.js)) | Reliable queue + templates (Brevo or existing SMTP — TBD in audit) |
| Job monitoring | Partial (`cleanup_jobs` pattern) | Heartbeats for support/notification jobs |

## 3. Delivery sequence

| Phase | Summary | Indicative effort | Canonical doc |
| ----- | ------- | ----------------- | --------------- |
| 1 | Contact hub, form, tickets, email | 6–10 dev-days | [support-ticketing.md](../features/support-ticketing.md) |
| 2 | Errors, structured logs, correlation, redaction | 4–7 dev-days | [support-observability.md](../features/support-observability.md) |
| 3 | Five-minute diagnostic sessions, optional replay | 6–10 dev-days | [support-diagnostics.md](../features/support-diagnostics.md) |
| 4 | Classification, duplicates, GitHub issues, AI summaries | 5–8 dev-days | [support-triage.md](../features/support-triage.md) |
| 5 | Cursor agent, PRs, approval, release-linked updates | 7–12 dev-days | [support-automation.md](../features/support-automation.md) |

Each phase issue includes a **phase audit** (roadmap §13) before execute-plan scope is frozen.

### Stopping points

- After Phase 2 — launch-ready support with baseline diagnostics.
- After Phase 3 — guided technical support with reproduction evidence.
- After Phase 5 — semi-autonomous support engineering with human merge/deploy control.

## 4. Phase 1 — Contact foundation and ticketing

Goal: Users contact AgathaTrack, receive acknowledgement, and follow request progress without a helpdesk product.

### 4.1 Contact page

Responsive hub (web/mobile): **Help & Support** (in-app form), **Partnerships** and **Legal & Privacy** (mailto or copyable addresses). Accessible without auth where appropriate. Requirement IDs: `SUPPORT-TICKETING-R-001`–`R-003`.

### 4.2 Email channels

Visible addresses (routing TBD in audit): `support@`, `partnerships@`, `legal@` (legal **and** privacy enquiries share `legal@`; no separate `privacy@`) — `SUPPORT-TICKETING-R-004`.

### 4.3 Support form

Adaptive form (bug / question / suggestion); auto context (version, browser, page, locale); optional screenshots with private storage — `SUPPORT-TICKETING-R-005`–`R-008`.

### 4.4 Data model

Tables (names indicative): `support_tickets`, `support_messages`, `support_status_history`, `support_attachments`, `support_issue_links`, `support_notifications`; diagnostic metadata deferred to Phase 3 — `SUPPORT-TICKETING-R-009`–`R-011`.

### 4.5 Lifecycle and admin

Customer-visible statuses; internal workflow; category vs classification vs status — `SUPPORT-TICKETING-R-012`–`R-014`.

### 4.6 Notifications

DB-backed outbox; templates: received, need info, investigation update, resolved — `SUPPORT-TICKETING-R-015`–`R-016`.

**Phase 1 exit:** User submits issue, receives reference, reads responses, informed on close; partnerships/legal independent; no AI required.

## 5. Phase 2 — Observability and reliable diagnostic context

Goal: Technical evidence for later automation without excessive always-on logging. Reuse PostHog EU where possible.

- Error/exception tracking (FE + BE) — `SUPPORT-OBSERVABILITY-R-001`–`R-002`
- Structured application logging (allowlisted schema, OTLP/PostHog Logs) — `R-003`–`R-004`
- Correlation IDs: ticket, request/trace, session, diagnostic session — `R-005`–`R-007`
- Redaction policy and support-job monitoring — `R-008`–`R-009`

**Phase 2 exit:** Trace a failed operation FE→BE and link evidence to a support ticket.

## 6. Phase 3 — Temporary diagnostic sessions

Goal: Five-minute, privacy-safe capture linked to a ticket.

- Activation (self-service + expiring support code) — `SUPPORT-DIAGNOSTICS-R-001`–`R-003`
- Lifecycle and UI indicator — `R-004`–`R-005`
- Enhanced diagnostic event families (allowlisted) — `R-006`–`R-007`
- Optional PostHog session replay (masked) — `R-008`
- Diagnostic report assembly — `R-009`–`R-010`

**Phase 3 exit:** User reproduces failure under diagnostics; sanitised timeline linked to ticket.

## 7. Phase 4 — AI triage and investigation

Goal: Organise reports and prepare engineering handover — **no automated code change in this phase**. Phase 1 already opens the private AgathaTrackPrivate issue; this phase automates **SUPPORT-TICKETING-D-015** (cleaned technical summary and AgathaTrack/AgathaTrack issue linkage), not first-issue creation.

- Classification with override — `SUPPORT-TRIAGE-R-001`–`R-002`
- Duplicate grouping (PostHog fingerprints + DB) — `R-003`
- Engineering handover automation (sanitised AgathaTrack issues; `AT-` reference only) — `R-004`–`R-005`
- AI-assisted diagnostic review (sanitised brief) — `R-006`

**Phase 4 exit:** New ticket classified, engineering handover assisted where appropriate, user gets appropriate status update.

## 8. Phase 5 — Automated bug fixes and release feedback

Goal: Coding agent proposes fixes with human review and controlled deployment.

- Agent orchestration (`ai-investigate` label gate) — `SUPPORT-AUTOMATION-R-001`–`R-002`
- Investigation contract and PR output — `R-003`–`R-004`
- CI/review safeguards — `R-005`
- Webhook sync: PR merge, deploy, user notification — `R-006`–`R-007`

**Phase 5 exit:** Eligible bug flows report → evidence → GitHub → agent PR → review → deployed fix → customer update.

## 9. Target architecture

```text
AgathaTrack app → Contact hub · form · ticket history · diagnostic activation
Support API     → Auth · ticket DB · status · job processing
PostHog         → Errors · logs · diagnostic evidence · optional replay
GitHub          → Issues · PRs · release events
Email (Brevo/SMTP) → Customer notifications
Cursor agent    → Investigate · test · PR (human approval · deploy confirms ticket update)
```

## 10. Vendor and cost notes (indicative)

Native ticketing (no new SaaS), existing Postgres, PostHog EU (watch single-project limits on free tier), GitHub, Brevo or existing mail, healthchecks.io for jobs, Cursor Automations (budget caps). Details in phase audits.

## 11. Security and privacy (all phases)

| Area | Rule |
| ---- | ---- |
| Authentication | Phase 1: no in-app ticket view for customers (`SUPPORT-TICKETING-R-009`); staff read-only queue only. Later phases: users see only their tickets and diagnostic sessions |
| Administration | Server-enforced support roles |
| Privacy/legal | Separate handling from automated bug triage |
| Diagnostics | Predefined safe fields only |
| Support codes | Single-use, bounded, rate-limited |
| AI | Sanitised evidence; minimum repo permissions |
| Retention | Explicit expiry for attachments and diagnostic blobs |
| Communication | No “resolved” until verified release/corrective action |

## 12. Deliberately postponed

Live chat, conversational support bot, complex FAQ, sophisticated support dashboard, unattended agent merge/deploy, automating all product decisions.

## 13. Phase audit checklist (before each execute-plan)

Verify and record gaps before freezing phase scope:

1. Contact routes and responsive UI patterns ([help_about](/docs/domains/help_about/README.md), Account screen).
2. Authentication and admin roles.
3. Database conventions and private file storage ([safeUpload](/server/lib/safeUpload.js)).
4. PostHog SDKs: EU endpoints, exceptions, replay, logs.
5. Transactional email infrastructure (Nodemailer vs API provider).
6. GitHub repo, CI, deployment, webhook patterns.
7. Job queue / `cleanup_jobs` / webhook idempotency.

Output: gap table + phased requirement adjustments in the canonical doc for that phase.

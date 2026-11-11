---
title: Support triage and GitHub linkage
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, triage]
domain: customer_support
feature_id: support-triage
---

# Support triage and GitHub linkage

## Summary / scope

- **Owns:** Rules-first classification, duplicate suggestions, sanitised GitHub engineering issues, AI-generated investigation briefs (no code changes).
- **Does not own:** Merging PRs, changing product rules without review.

Roadmap: [support-roadmap.md §7](../changes/support-roadmap.md#7-phase-4--ai-triage-and-investigation).

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-TRIAGE-R-001 | Classifications: probable bug, behavioural change, feature request, usage question, insufficient information, security/privacy — each with reason, confidence, human override. | Planned |
| SUPPORT-TRIAGE-R-002 | User content treated as untrusted input for automation prompts. | Planned |
| SUPPORT-TRIAGE-R-003 | Duplicate suggestions via error fingerprints and technical context; tickets remain individually trackable. | Planned |
| SUPPORT-TRIAGE-R-004 | Create/link private GitHub issues with sanitised reproduction, versions, error refs — no customer PII/diagnostics dump. | Planned |
| SUPPORT-TRIAGE-R-005 | Idempotent GitHub webhooks; labels include `bug`, `needs-reproduction`, `ai-investigate`, `product-review`, `security-review`, `human-required`. | Planned |
| SUPPORT-TRIAGE-R-006 | AI review output: observation vs hypothesis, recommended next action, linked evidence refs only. | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given new bug ticket with error ref When triage runs Then classification and optional duplicate suggestion are stored | SUPPORT-TRIAGE-R-001, SUPPORT-TRIAGE-R-003 | none — #2274 |
| Given approved investigation When GitHub issue created Then ticket stores issue id and issue body has no email/conversation dump | SUPPORT-TRIAGE-R-004 | none — #2274 |

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-TRIAGE-D-001 | Phase 4 prepares engineering issues only | Avoid automated code changes before Phase 5 gates | Live | 2026-11-11 | TBD |

---
title: Support automation and release feedback
owner: Documentation Team
audience: both
status: active
last_updated: 2026-11-11
tags: [domain, customer_support, automation]
domain: customer_support
feature_id: support-automation
---

# Support automation and release feedback

## Summary / scope

- **Owns:** Label-gated Cursor/cloud agent runs, investigation contract, PR creation, sync from GitHub/deploy events to ticket status and customer email.
- **Does not own:** Unattended production deploy, silent product behaviour changes.

Roadmap: [support-roadmap.md §8](../changes/support-roadmap.md#8-phase-5--automated-bug-fixes-and-release-feedback).

## Requirements

| ID | Rule | Status |
| ---- | ------ | ------ |
| SUPPORT-AUTOMATION-R-001 | Only authorised application of `ai-investigate` (or equivalent) starts agent; user submission alone must not trigger unrestricted coding. | Planned |
| SUPPORT-AUTOMATION-R-002 | Agent environment: no production DB secrets, no bypass of branch protection, minimal permissions. | Planned |
| SUPPORT-AUTOMATION-R-003 | Agent deliverables: root cause, evidence, minimal fix, tests, residual risk; product-rule conflicts → product decision not silent code change. | Planned |
| SUPPORT-AUTOMATION-R-004 | Regression test where defect is reproducible before merge recommendation. | Planned |
| SUPPORT-AUTOMATION-R-005 | Human approval required before merge and deploy; agent cannot self-merge. | Planned |
| SUPPORT-AUTOMATION-R-006 | Map engineering events to ticket states: investigation, fix proposed, awaiting release, released, reopen on continued failure. | Planned |
| SUPPORT-AUTOMATION-R-007 | Customer notified after verified deploy/validation — merged PR alone does not close ticket as resolved. | Planned |

## Acceptance criteria

| Given / When / Then | Requirement | Coverage |
| ------------------- | ----------- | -------- |
| Given eligible GitHub issue When label applied by policy Then agent run starts with scoped credentials | SUPPORT-AUTOMATION-R-001, SUPPORT-AUTOMATION-R-002 | none — #2275 |
| Given deploy success for fix When validation passes Then affected tickets move to released and notify users | SUPPORT-AUTOMATION-R-006, SUPPORT-AUTOMATION-R-007 | none — #2275 |

## Still open

- GitHub branch protection availability on current plan (phase audit).

## Decision log

| ID | Decision | Rationale | Status | Date | PR |
| ---- | -------- | --------- | ------ | ---- | -- |
| SUPPORT-AUTOMATION-D-001 | Customer-visible resolution requires deploy verification | Merged ≠ user-observable fix | Live | 2026-11-11 | TBD |

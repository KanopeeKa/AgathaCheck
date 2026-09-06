---
title: Pet Care security headers + upload rate limit (F-15, F-16)
owner: Agent
audience: agent
status: active
---

# pet-care-security-hardening

## Goal

Add Helmet security headers (F-15) and static upload rate limiting (F-16) for the Node server, with Flutter-web-tolerant CSP in production and CSP disabled under `E2E=1` for Playwright localhost canary.

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T17:40:00Z |
| **approved_until** | 2026-09-08T17:40:00Z |
| **control_issue** | TBD |
| **autonomy** | active |

Standing grant: Pet Care hardening roadmap (user chat 2026-09-05).

## Runtime

```yaml
autonomy: completed
current_phase: null
last_completed_phase: 1
halt_reason: null
next_action: "plan complete"
artifact_ref:
  branch: cursor/pet-care-security-hardening-runtime-sync-75cb
  plan_path: .agents/plans/pet-care-security-hardening.md
  plan_commit: fc4c27f48de91979686fc4c0608be22bba7d8249
  snapshot_path: .agents/plans/pet-care-security-hardening.snapshot.json
  snapshot_commit: fc4c27f48de91979686fc4c0608be22bba7d8249
open_prs: []
merge_commits: {"1":"fc4c27f48de91979686fc4c0608be22bba7d8249"}
debt_issue_refs: []
```

## Phase 1 — Helmet headers + static upload rate limit (F-15, F-16)

- `server/config/securityHeaders.js` — Helmet + Flutter-tolerant CSP; skip CSP when `E2E=1`
- `createStaticUploadLimiter()` on `/uploads` and `/backend/uploads`
- `server/test/securityHeaders.test.js`

**Branch:** `cursor/pet-care-security-hardening-75cb`  
**PR:** #1031 (merged)

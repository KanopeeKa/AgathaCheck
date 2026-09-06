---
title: Pet Care API contract (F-14)
owner: Documentation Team
audience: agent
status: draft
last_updated: 2026-09-06
tags: [pet_care, api, execute-plan, openapi]
---

# Plan: pet-care-api-contract

## Goal

Introduce an OpenAPI 3.1 subset for critical Pet Care endpoints (pets CRUD, lifecycle, auth session tokens), a repo validation script wired into governance pre-push, and Jest contract tests that assert live route DTOs match the documented schemas (F-14).

**Standing grant:** Pet Care hardening roadmap (user chat 2026-09-05; continued 2026-09-06).

## Autonomy

| Field | Value |
|-------|-------|
| **approved_at** | 2026-09-06T13:30:00Z |
| **approved_until** | 2026-09-08T13:30:00Z |
| **approved_by** | standing grant — Pet Care hardening roadmap (user chat 2026-09-05) |
| **control_issue** | TBD |
| **autonomy** | `active` |

## Phases

### Phase 1 — OpenAPI subset + validation + contract tests (F-14)

| Field | Value |
|-------|-------|
| **branch** | `cursor/pet-care-api-contract-75cb` |
| **exit_checklist** | `governance` |

**Exit criteria:**

- [ ] `docs/architecture/openapi/pet-care-critical.json` documents pets CRUD, lifecycle, and auth token DTOs
- [ ] `scripts/validate_openapi.js` validates spec structure (runs in pre-push governance)
- [ ] `server/test/openapi/petCareContract.test.js` asserts critical responses match schemas
- [ ] `docs/architecture/api-reference.md` links to the OpenAPI subset

## Runtime state

```yaml
autonomy: active
current_phase: 1
last_completed_phase: null
halt_reason: null
next_action: "continue phase 1 on branch cursor/pet-care-api-contract-75cb"
artifact_ref:
  branch: cursor/pet-care-api-contract-75cb
  plan_path: .agents/plans/pet-care-api-contract.md
  plan_commit: 79039e5f9dfc5884de867e482f73ac2ee342fc79
  snapshot_path: .agents/plans/pet-care-api-contract.snapshot.json
  snapshot_commit: 79039e5f9dfc5884de867e482f73ac2ee342fc79
open_prs: ["https://github.com/KanopeeKa/AgathaCheck/pull/1022"]
merge_commits: {}
debt_issue_refs: []
```

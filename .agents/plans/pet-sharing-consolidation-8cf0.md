# Pet sharing consolidation

## Goal

Consolidate pet sharing into one module with PET_ACCESS_ROLES (`carer`, `co_parent`), server-side permission enforcement (co-parent = owner minus transfer), remove dead pending-share code, expose `access_role` on pet API, add hide UI for personal collaborators, and update docs/tests.

## Autonomy

| Field | Value |
|-------|-------|
| approved_at | 2026-09-16T10:05:00Z |
| approved_until | 2026-09-18T10:05:00Z |
| approved_by | standing grant — user chat 2026-09-16 execute-plan autonomous |
| control_issue | TBD |
| base_branch | cursor/pet-sharing-consolidation-integration-8cf0 |

## Phases

### Phase 1 — Server foundation

Docs, petSharing module, PET_ACCESS_ROLES migration, permissions split, dead code removal, access_role wire field.

### Phase 2 — Flutter consolidation + roles + hide

Move sharing UI, role-aware viewer, co-parent/carer labels, hide affordance, repository cleanup.

### Phase 3 — Tests, BDD, OpenAPI

Jest/Flutter tests, sharing.feature, api-reference, integration PR to main.

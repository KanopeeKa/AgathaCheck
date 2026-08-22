# Pet activity model (product layer)

**Status:** Locked for Organisation v2 (Slice 1)  
**Related:** [/docs/domains/organization/changes/organisation-v2-delivery-plan.md](/docs/domains/organization/changes/organisation-v2-delivery-plan.md) (D-v2-ACT-*), [/docs/observability.md](/docs/observability.md)

---

## Purpose

Organisation v2 needs **last-activity sorting** for the 12-pet profile preview and future activity UI. This is a **product** concern — distinct from compliance audit (`audit_events`) and guardian timeline (`pet_timeline_entries`).

## Storage

| Artifact | Role |
|----------|------|
| `pet_activity_events` | Append-only event log (type, pet_id, org_id, actor, occurred_at, safe metadata) |
| `pets.last_activity_at` | Denormalized column updated in the **same transaction** as each event insert |

**No backfill** — existing pets sort by `COALESCE(last_activity_at, created_at)` until new activity occurs.

## Event types (v1)

| Type | Trigger |
|------|---------|
| `health_log` | Health/weight/other entry write visible to org foster context |
| `foster_session` | Foster placement create/update/end |
| `profile_edit` | Pet profile field update |
| `document_upload` | Foster-visible document upload |

## Write contract

All product activity writes go through `server/lib/petActivity.js` → `recordPetActivity()`:

1. Insert `pet_activity_events` row (no sensitive payloads — D-v2-ACT-3).
2. Update `pets.last_activity_at` for the pet.
3. Commit in one transaction.

**Hook manifest:** `server/test/contracts/petActivityHooks.contract.test.js` — CI fails if required write sites drift without contract update.

## What this is not

| Layer | Use instead |
|-------|-------------|
| Compliance / permission changes | `audit_events` via `logAuditEventSafe` |
| Guardian-facing timeline cards | `pet_timeline_entries` + composite read |
| Org sort / preview | This model |

## Read paths (v2)

- `GET /organizations/:orgId/pets/summary?limit=12&sort=last_activity` — requires `view_org_pets`.
- Org pets list may adopt same sort in later slices.

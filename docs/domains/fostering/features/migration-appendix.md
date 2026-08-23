---
title: Fostering migration appendix
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
tags: [domain, fostering, specs]
domain: fostering
feature_id: migration-appendix
---
# Migration appendix — fostering platform

**Status:** `locked` (J3 gate satisfied)  
**Last updated:** 2026-07-24  
**Parent:** [`g0-contract-pack.md`](g0-contract-pack.md) §6, §12

This document finalises current → target evolution decisions. Journey agents **must not** invent alternate status names or parallel tables.

---

## 1. Compatibility gate summary (G0 §12)

| Legacy entity | Disposition | Owner | Gate |
|---------------|-------------|-------|------|
| `org_foster_parents` | **Evolve** | J1 | `locked` |
| `foster_placements` | **Evolve** | J3 | `locked` |
| Placement statuses | **Wrap and deprecate** | J3 | `locked` |
| In-placement adoption states | **Replace** (J5 workflow) | J5 | `locked` |
| `FosterParent` Flutter entity | **Wrap and deprecate** | J1 | `locked` |
| Org role `foster` | **Keep** | Platform | `locked` |
| `externalFosterNotice` email | **Keep and extend** | J1, J4 | `locked` |
| `pet_access.role = foster` | **Keep** | J3 | `locked` |
| Custody / shadow on adoption | **Keep** | J5 | `locked` |

---

## 2. Table evolution strategy

### 2.1 `foster_placements` → fostering sessions

**Decision:** extend `foster_placements` in place for v1. Optional SQL view `fostering_sessions` may alias columns for new code; **no second placement table**.

New columns (J3 migrations — illustrative):

| Column | Type | Purpose |
|--------|------|---------|
| `shelter_foster_relationship_id` | UUID FK → evolved `org_foster_parents` | Canonical foster link |
| `session_type` | `standard_foster` \| `foster_in_view_to_adopt` | Default `standard_foster` |
| `foster_request_response_id` | UUID nullable | J2 handoff provenance |
| `shelter_start_confirmed_at` | TIMESTAMPTZ nullable | Dual start (shelter) |
| `foster_start_confirmed_at` | TIMESTAMPTZ nullable | Dual start (foster) |

Status column values migrate to G0 §6.2 enum (see §3).

### 2.2 `org_foster_parents` → shelter–foster relationship

**Decision:** extend `org_foster_parents` in place; add `foster_profile_id` FK when `foster_profiles` table lands (J1 Phase 2).

New columns (J1 migrations — illustrative):

| Column | Type | Purpose |
|--------|------|---------|
| `approval_state` | `under_review` \| `approved` \| `declined` \| `archived` | Default `approved` for legacy rows |
| `foster_profile_id` | UUID nullable | Link to global profile |
| `creation_source` | `invite` \| `manual_shelter_entry` \| `member` | Provenance |
| `lawful_basis_attested_at` | TIMESTAMPTZ | Art. 14 path (existing attestation) |
| `opt_out_at` | TIMESTAMPTZ nullable | Suppress outreach |

Staff notes remain `notes` column (staff-only per G0 §10).

### 2.3 `foster_profiles` (new — J1 Phase 2)

New table keyed by `id UUID PK`. Registered users link via `user_id UUID UNIQUE nullable`.

### 2.4 `foster_user_id NOT NULL` blocker

**Decision (locked):**

1. **Until J1 Phase 3:** sessions require registered `foster_user_id` (current behaviour).
2. **J1 Phase 3:** manual foster records may exist without `user_id`.
3. **J3 migration:** make `foster_placements.foster_user_id` **nullable**; require `shelter_foster_relationship_id NOT NULL` for new rows.
4. **Care access (`pet_access.role = foster`):** granted only when session status is `active` (or `adoption_in_progress`) **and** `foster_user_id` is set. Manual fosters without accounts cannot receive `pet_access` until merge/registration.

---

## 3. Status mapping (locked)

### 3.1 Legacy → target (one-time data migration)

| Legacy `foster_placements.status` | Target status | J5 row? | Notes |
|-----------------------------------|---------------|---------|-------|
| `pending` | `pending_acceptance` | No | No prep checklist in legacy data |
| `in_progress` | `active` | No | Map `responded_at` → `foster_start_confirmed_at` |
| `waiting_adoption_confirmation` | `adoption_in_progress` | Yes (open) | Create `adoption_journey` stub |
| `pending_adoption_conditions` | `adoption_in_progress` | Yes (open) | Copy `adoption_conditions` to journey |
| `adopted` | `converted_to_adoption` | Yes (closed) | Terminal |
| `not_in_foster` | `cancelled` | No | Terminal; historical rows only |

### 3.2 Canonical target statuses (J3)

Non-terminal: `pending_acceptance`, `preparation`, `ready_to_start`, `active`, `end_pending_confirmation`, `adoption_in_progress`

Terminal: `returned_to_shelter`, `transferred`, `converted_to_adoption`, `cancelled`

**Forbidden:** `end_pending` (use `end_pending_confirmation`), duplicate adoption states on placement row after J5 ships.

### 3.3 One open session per pet (I4)

Replace index `idx_foster_placements_one_active_pet` with:

```sql
CREATE UNIQUE INDEX idx_foster_placements_one_open_session_per_pet
  ON foster_placements (pet_id)
  WHERE status IN (
    'pending_acceptance',
    'preparation',
    'ready_to_start',
    'active',
    'end_pending_confirmation',
    'adoption_in_progress'
  );
```

During dual-write window, legacy statuses `pending`, `in_progress`, `waiting_adoption_confirmation`, `pending_adoption_conditions` remain in index until sunset (§4).

---

## 4. Dual-write and sunset

| Window | Behaviour |
|--------|-----------|
| **J3 Phase 1** | API accepts legacy status strings; writes map to target; reads return target (+ optional `legacy_status` field for one release) |
| **J3 Phase 2** | Flutter uses target statuses only |
| **J5 Phase 1** | Stop writing `waiting_adoption_confirmation` / `pending_adoption_conditions`; open rows migrated |
| **Sunset** | Remove legacy status strings from API + drop from partial index — **one release after J5 merge** |

Compatibility tests: `server/test/fosterPlacements.test.js` + new `fosteringSessionMigration.test.js`.

---

## 5. `pet_access.role = foster` timing (Q5 locked)

| Session status | `pet_access.foster` granted? |
|----------------|------------------------------|
| `pending_acceptance`, `preparation`, `ready_to_start` | No |
| `active`, `adoption_in_progress` | Yes (when `foster_user_id` set) |
| Terminal statuses | No (revoke / end placement) |

Matches current product: foster accepts (`pending` → `in_progress`) before care access.

---

## 6. Adoption journey replacement (J5)

| Legacy placement field/flow | J5 target |
|----------------------------|-----------|
| `waiting_adoption_confirmation` | `adoption_journey.status = awaiting_foster_confirmation` |
| `pending_adoption_conditions` | `adoption_journey.status = pending_conditions` |
| `adopted` | `adoption_journey.status = finalised` + session `converted_to_adoption` |
| Direct adopt shortcut | J5 `adoption_journey` without visit path |
| Custody transfer | Existing `applyIndividualGuardianshipTransfer` — **no change** |

J5 **supersedes** in-placement adoption API paths. Sunset per §4.

---

## 7. Flutter domain deprecation

| Legacy type | Target | Strategy |
|-------------|--------|----------|
| `FosterParent` | `ShelterFosterRelationship` + `FosterProfile` view model | Typedef alias `FosterParent` → relationship VM until J1 Phase 2 removes |
| `FosterPlacement` | `FosteringSession` | Status enum extension; alias during J3 Phase 1 |

---

## 8. Activity summary for Manage Fosters (J1 reads J3)

Until J3 ships dedicated aggregate API, **J1 Phase 1** derives tab buckets from existing `active_pets` on foster-parents API:

| Tab | Rule (interim) |
|-----|----------------|
| **Fostering** | `active_pet_count > 0` with any `in_progress` / adoption-in-progress placement |
| **Recently fostered** | No active placements; has historical placement ended within 90 days (future API) — **Phase 1: empty stub** |
| **Inactive** | No active placements |
| **New** | Manual/external kind or member without placements — **Phase 1 stub** |
| **All** | Full list |

J3 Phase 1 replaces interim rules with `fostering_activity_summary` read model (G0 §4.4).

Approval filters (`under_review`, `approved`, `archived`) — **J1 Phase 2** when `approval_state` column exists. Phase 1 UI shows filters disabled with helper text.

---

## 9. Rollback

| Scenario | Action |
|----------|--------|
| J3 Phase 1 revert | Keep legacy status strings in API; migration down restores index |
| J5 revert | Re-enable placement adoption statuses from feature flag |
| Data migration failure | Transactional migration; backup `foster_placements` status before UPDATE |

---

## 10. Agent checklist before starting

- [x] G0 §12 rows marked `locked`
- [x] Status enum consistent (no undefined values)
- [x] `foster_user_id` path documented
- [x] Index definition written
- [ ] J1 spec references §2.2, §8
- [ ] J3 spec references §2.1, §3, §4, §5

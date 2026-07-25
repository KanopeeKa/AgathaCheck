# J1 — Foster onboarding and approval

**Status:** Phase 2 in progress  
**Parent:** [`g0-contract-pack.md`](g0-contract-pack.md) · [`migration-appendix.md`](migration-appendix.md)

## Purpose

A person becomes an approved foster for a shelter with reusable global profile data and shelter-local screening.

## Phase 1 — Manage Fosters shell (complete)

- [x] Dedicated screen at `/o/orgs/:id/fosters`
- [x] Tabs: New, Fostering, Recently fostered, Inactive, All
- [x] Foster summary cards from existing foster-parents API
- [x] Rename "Add external foster" → "Add foster manually"
- [x] BDD skeleton (`foster_onboarding.feature`)

## Phase 2 — Approval state (this plan)

- [ ] Migration `022`: `approval_state`, `creation_source` on `org_foster_parents`
- [ ] GET foster-parents exposes `approval_state` (members virtual `approved`)
- [ ] POST manual foster → `under_review` + audit `manual_foster_record_created`
- [ ] PATCH `/:id/approval` → approve / decline / archive + G0 audit events
- [ ] Flutter approval filters enabled
- [ ] Approve / decline / archive actions on external foster cards

## Out of scope (Phase 2)

- `foster_profiles` table (J1 Phase 3)
- Foster invite flow changes
- Playwright E2E (debt — map BDD after API stable)

## Depends on

- G0 contract pack
- Migration appendix §2.2, §8

## Exposes to J2

- Approved-foster read model with `approval_state`
- Manage Fosters approval filters

## Open questions

- See G0 Q1 (non-member foster portal access)

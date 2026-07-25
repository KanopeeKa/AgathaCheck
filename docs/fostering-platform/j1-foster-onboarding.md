# J1 — Foster onboarding and approval

**Status:** Phase 2 complete  
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

- [x] Migration `022`: `approval_state`, `creation_source` on `org_foster_parents`
- [x] GET foster-parents exposes `approval_state` (members virtual `approved`)
- [x] POST manual foster → `under_review` + audit `manual_foster_record_created`
- [x] PATCH `/:id/approval` → approve / decline / archive + G0 audit events
- [x] Flutter approval filters enabled
- [x] Approve / decline / archive actions on external foster cards

**Status:** Phase 3 complete

## Phase 3 — Foster profiles and manual merge (complete)

- [x] Migration `023`: `foster_profiles` table; `foster_profile_id` on `org_foster_parents`
- [x] Backfill profiles for existing external fosters
- [x] GET foster-parents exposes `foster_profile_id`
- [x] POST manual foster creates linked `foster_profiles` row
- [x] GET `merge-suggestions?email=` for registered-user hints
- [x] POST `/:id/merge` links manual record to target user + audit `foster_merge_completed`
- [x] Flutter merge flow

## Phase 4 — Compliance, retention, and privacy copy

- [x] Migration `024`: `opt_out_at`, `retention_category` on `org_foster_parents`
- [x] PATCH opt-out and retention routes + audit events
- [x] Refresh Art. 14 external foster notice email (EN/FR)
- [x] DPIA checklist items for J1 Ph4
- [x] Flutter: opt-out toggle, retention chip, updated lawful-basis copy

**Status:** Phase 4 complete (pending integration → main)

## Out of scope (Phase 3 backend)

- Foster invite flow changes
- Playwright E2E (debt — map BDD after API stable)

## Previously out of scope (Phase 2)

- ~~`foster_profiles` table (J1 Phase 3)~~ — delivered in Phase 3

## Depends on

- G0 contract pack
- Migration appendix §2.2, §8

## Exposes to J2

- Approved-foster read model with `approval_state`
- Manage Fosters approval filters

## Open questions

- See G0 Q1 (non-member foster portal access)

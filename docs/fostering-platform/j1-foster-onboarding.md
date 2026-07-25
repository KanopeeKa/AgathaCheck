# J1 — Foster onboarding and approval

**Status:** Phase 1 in progress  
**Parent:** [`g0-contract-pack.md`](g0-contract-pack.md) · [`migration-appendix.md`](migration-appendix.md)

## Purpose

A person becomes an approved foster for a shelter with reusable global profile data and shelter-local screening.

## Phase 1 (this plan) — Manage Fosters shell

- [x] Dedicated screen at `/o/orgs/:id/fosters`
- [x] Tabs: New, Fostering, Recently fostered, Inactive, All
- [x] Approval filter chips (disabled until Phase 2)
- [x] Foster summary cards from existing foster-parents API
- [x] Rename "Add external foster" → "Add foster manually"
- [x] BDD skeleton (`foster_onboarding.feature`)

## Out of scope (Phase 1)

- Global foster profile table
- Approval workflow backend
- Shelter-specific questionnaire
- Foster invite flow changes
- Playwright E2E (debt — map BDD after Phase 2 API)

## Depends on

- G0 contract pack
- Migration appendix §8 (interim tab rules)

## Exposes to J2

- Manage Fosters screen route
- Tab/filter vocabulary (l10n keys)

## Open questions

- See G0 Q1 (non-member foster portal access)

---
title: Organisation member privacy (v3)
owner: Architecture Team
audience: both
status: active
last_updated: 2026-08-21
tags: [architecture,design,domain]
domain: shelter
feature_id: org-member-privacy
---
# Organisation member privacy (v3)

**Status:** Design note for Organisation UX v3 Phase 8  
**Parent:** [/docs/domains/shelter/changes/organisation-ux-v3-delivery-plan.md](/docs/domains/shelter/changes/organisation-ux-v3-delivery-plan.md) · **D-v3-PRIV-1/2**

## Purpose

Unify per-org visibility settings previously split across admin-contact self-prefs and foster self-prefs into one Account-owned model with named-person grants.

## Enums (wire values)

### `card_visibility`

Who can see the member’s directory card (photo + name at minimum when allowed).

| Value | Meaning |
|-------|---------|
| `all` | All active org members (default for all roles) |
| `admins` | Admins + Super Admins only |
| `named` | Super Admin always + named grants only |

**Floors (server-enforced, cannot go below):**

| Role | Minimum visibility |
|------|--------------------|
| associate / member / foster | Super Admin always sees **name** (and may message when messaging exists) even if card is otherwise hidden |
| admin / super_admin | At least `admins` |

### `phone_visibility` / `email_visibility`

| Value | Meaning |
|-------|---------|
| `admins` | Admins + Super Admins |
| `admins_and_foster_managers` | Admins + Super Admins + holders of `manage_fosters` (foster default) |
| `admins_or_named` | Admins + Super Admins **or** named grant holders (member/admin default) |
| `named` | Named grants only (plus Super Admin emergency? **No** — phone/email stay grant-based; name floor is separate) |
| `nobody` | Hidden from everyone except as required by law/ops — **not** in v3 defaults; omit unless product adds later |

**Defaults:**

| Role | Phone / email default |
|------|------------------------|
| associate / member / admin / super_admin | `admins_or_named` |
| foster | `admins_and_foster_managers` (named grants still additive) |

Implementation note: store base enum + always OR named grants from `organization_visibility_grants`.

### `address_visibility`

| Value | Meaning |
|-------|---------|
| `admins_or_named` | Admins + Super Admins or named (default for all roles) |
| `admins` | Admins + Super Admins only |
| `named` | Named only |
| `hidden` | Nobody (optional; map from legacy foster `hidden`) |

Default: `admins_or_named`.

## Named grants table

```sql
CREATE TABLE organization_visibility_grants (
  id UUID PRIMARY KEY,
  organization_id UUID NOT NULL REFERENCES organizations(id),
  subject_user_id UUID NOT NULL REFERENCES users(id),
  grantee_user_id UUID NOT NULL REFERENCES users(id),
  field TEXT NOT NULL CHECK (field IN ('card', 'phone', 'email', 'address')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (organization_id, subject_user_id, grantee_user_id, field)
);
```

Grantee must be an **active** member of the same organisation at grant time and at read time.

## Storage on membership

On `organization_users`:

- `card_visibility TEXT NOT NULL DEFAULT 'all'`
- `phone_visibility TEXT NOT NULL DEFAULT 'admins_or_named'`
- `email_visibility TEXT NOT NULL DEFAULT 'admins_or_named'`
- `address_visibility TEXT NOT NULL DEFAULT 'admins_or_named'`

Role-specific defaults applied on membership create / migrate:

- Foster role → phone/email default `admins_and_foster_managers`
- Admin/super_admin → card floor `admins` if user tries to set below

## Legacy migration

| Legacy | Target |
|--------|--------|
| Admin `AdminPhoneVisibility` | Map into `phone_visibility` (+ grants empty) |
| Foster `visible_to` / `contact_visibility` / `address_visibility` | Map into card/phone/email/address enums; best-effort |

Exact mapping table lands in Phase 8 Jest fixtures.

## API (Phase 8)

- `GET /organizations/:orgId/members/me/privacy`
- `PUT /organizations/:orgId/members/me/privacy` (body: enums + grant user ids per field)
- Directory/list endpoints redact phone/email/address/card fields using resolver

## Audit

`member_visibility_changed` on successful PUT (extend program-contract catalog in Phase 8).

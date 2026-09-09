---
title: Care entitlements
owner: Product / Documentation
audience: both
domain: pet_care
feature_id: care_entitlements
status: active
related_prs: []
related_bdd: []
---

# Care entitlements

**Status:** Principles only — **no runtime implementation in Care Progression V1.**

This document defines how future subscription tiers may gate **optional** Pet Care capabilities without fragmenting care semantics or paywalling safety.

**Related:** [Care Progression](care-progression.md) · [Care Intelligence](care-intelligence.md)

---

## Purpose

Entitlements control **access** to capabilities — not care meaning, measurement validity, or progression truth.

```text
Entitlements answer:  “May this guardian use this optional capability?”
CareFamily answers:   “What area of care is this?”
Capabilities answer:  “What does this family support?”
```

---

## Not entitlements

`server/lib/petCapabilityPolicy.js` is **sharing ACL** (who may view/edit a pet’s health data). It is **not** product-tier entitlements. Do not conflate them.

---

## Core principles

1. **Essential care is not premium.** Core care families, core observations, Established markers, and core milestones for an entitled family are included with that family.
2. **Safety remains free.** Safety-relevant conclusions derivable from data available to a free user must not be hidden behind a paywall.
3. **Do not separately paywall** Established or core milestones for a care family the user is entitled to track.
4. **Historical progression persists** after downgrade — already-achieved milestones and establishment remain visible.
5. **No ad hoc tier logic** in screens, route handlers, or partner integrations. One canonical entitlement decision per optional capability.

---

## Illustrative future model

| Tier | Examples |
|------|----------|
| **Free / core** | Vaccination, parasite prevention, medication, wellness review, dental, grooming, nail care, weight; basic rhythms; Established; core milestones; essential safeguards from free data |
| **Paid / richer** | Larger optional care/observation catalog; specialised measurements; richer trend views; device imports; partner integrations |

Exact SKU boundaries are product decisions — implement only when pricing ships.

---

## Capability classes (conceptual)

```text
entitlementClass on CareFamilyCapabilities
  core              always available when family is supported for species
  optional_catalog  selectable optional tracking
  device_backed     requires integration entitlement
  partner_import    requires partner entitlement
```

Entitlements gate **availability** of optional classes. They do not change:

- `CareStatus` determinism
- Establishment semantics
- Milestone identity
- Observation validity rules
- CIM suppression hierarchy

---

## Implementation (deferred)

When entitlements ship:

- Single module: `care_entitlements` (server policy + Flutter read model)
- Canonical policy location remains this document until a cross-product entitlement doc supersedes it
- Feature flags / subscription service integrate through explicit ports — not scattered `if (plus)` checks

---

## Delivery status

Runtime entitlements are **out of scope** for Care Progression V1 (CP-0–CP-7). Capability registry may include `entitlementClass` fields as **documentation hooks** only.

---
title: Frozen domains philosophy
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-07
tags: [engineering, frozen-domains]
---

# Frozen domains — philosophy

## Purpose

AgathaTrack is pivoting to **Pet Care MVP**. Shelter (organisation workspace) and Fostering (platform + Pet Care session surfaces) remain in the repository as reference implementation, but are **explicitly removed from the product and CI lifecycle**.

This is not deletion and not a git-branch archive. It is a **controlled disconnect** so engineering effort focuses on Pet Care and Subscription.

## What frozen means

| Dimension | Active (Pet Care, Subscription) | Frozen (Shelter, Fostering) |
|-----------|--------------------------------|-----------------------------|
| Product | Shipped, refined | Not shown, not supported |
| Production APIs | Mounted | **Not mounted** (opt-in `ENABLE_FROZEN_DOMAINS=true` only) |
| CI / pre-push | Blocking | Excluded |
| `flutter analyze` | Full active tree | Frozen roots excluded after disconnect |
| Agents | May implement | Must not extend; no active→frozen imports |
| Database | MVP migrations must not break pets | Org/foster tables retained; no new org features |
| Source | Normal paths | **Same paths** — no `_archived/` moves |

## What frozen does not mean

- Deleting routes, tables, or feature folders.
- Expecting frozen tests to stay green on every Pet Care PR.
- Building manifest generators, archived CI ecosystems, or exhaustive test catalogs.
- Ignoring **data protection** for rows stored by frozen domains.

## Core principles

1. **Honest pivot** — Policy and automation encode MVP scope; not tribal knowledge.
2. **Preserve option value** — Source remains for future redesign (expected to be substantial).
3. **Accept controlled decay** — Frozen code will drift; that is OK if it cannot block Pet Care.
4. **Minimal machinery** — Automate one invariant: **active must not import frozen roots**.
5. **Reversible** — Git tags, manifest, rehydration runbook; manual `test-frozen-domains.sh` only.

## Data protection exception

Frozen **product** does not suspend frozen **data** obligations. Security, privacy, deletion, export, and retention for personal data in org/foster tables remain **active shared infrastructure**. “Shelter is frozen” never means “we can skip account deletion for org membership rows.”

## Pet Care fostering semantics

Fostered animals are **ordinary pets** in Pet Care UI — no fostering tab, session detail, or status badges. Carers enter information manually. This is a product simplification (D-MVP-2), not a promise that historical DB columns disappear immediately.

## Relationship to Subscription

Subscription is **active** and in MVP scope. It is not part of the freeze wall.

## Success criterion

> Shelter can rot without infecting Pet Care.

When disconnect, API unmount, analyze exclusion, and active CI are in place, **stop freeze work** and return to Pet Care features.

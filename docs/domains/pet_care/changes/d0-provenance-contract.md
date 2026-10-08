---
title: D0 — Weight provenance contract
owner: Product / Agent
audience: both
status: in-delivery
status_since: 2026-10-08
folds_into: docs/domains/pet_care/features/care-intelligence.md
plan: documentation-migration-514a
last_updated: 2026-10-08
---

# D0 — Weight provenance contract

**Canonical behaviour:** [care-intelligence.md](../features/care-intelligence.md) — requirements, acceptance criteria, and decision log live there.

This file retains **engineering artifacts** for D0; durable product rules are folded into the canonical doc.

---

## Code artifacts

| Artifact | Path |
|----------|------|
| Server validators | `server/routes/careIntelligence/provenance.js` |
| WeightChangeSpec sketch | `server/routes/careIntelligence/weightChangeSpec.js` |
| Evidence trace factory | `server/routes/careIntelligence/evidenceTrace.js` |
| D6 benchmark JSON schema | `server/routes/careIntelligence/benchmark/caseSchema.json` |
| Flutter enums | `flutter_app/lib/features/care_intelligence/domain/weight_provenance.dart` |
| Migration | `db/migrations/055_weight_provenance_contract.sql` |

---

## Regulatory touchpoints

| Data | Classification | Notes |
|------|----------------|-------|
| `measurement_source` | Pet health metadata | Low sensitivity; audit on weight entry writes |
| Weight reference/context | Pet health metadata | Used for suppression only in Phase D |
| `PhaseDEvidenceTrace` | Internal research | Ephemeral by default; map before persistence in DATA_MAP |

Update [DATA_MAP.md](/regulatory/DATA_MAP.md) when traces persist beyond ephemeral evaluation.

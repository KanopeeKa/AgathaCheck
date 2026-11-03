# Absences and per-pet away plans

## Goal

Deliver per-pet away plans under an absence wrapper: filtered co-parent visibility, add/remove pets, new Flutter routes and hub/pet surfaces, then fold canonical docs. One integration branch; release PR to `main`; Pre-UAT covers AP-1–AP-18 and UAT seed journeys.

**Spec:** `docs/domains/pet_care/changes/absence-per-pet-away-plans-spec.md` (requires PR #2035 merged before phase 1 worker starts).

## Phases

### Phase 1 — Server per-pet read (additive)

```json
{
  "allowed_paths": [
    "server/routes/careContext/**",
    "server/test/careContext/**",
    "docs/architecture/api-reference.md",
    "server/routes/careContext/README.md"
  ],
  "forbidden_paths": ["flutter_app/**", "e2e/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [],
  "exit_checklist": [
    "GET per-pet away plan + pet-page away list + per-pet status facts (additive endpoints or fields)",
    "No change to declarer-only hub list behaviour yet",
    "server Jest careContext green",
    "pre-push-changed green",
    "api-reference draft for new read shapes"
  ]
}
```

Scope: Per-pet away plan read model, per-pet status facts (carer gap, review count), list of current/upcoming away plans for a pet. Additive API only — existing monolithic plan read unchanged for old clients until phase 4.

Out of scope: Full-access filtering (phase 2), add/remove pets (phase 3), Flutter.

### Phase 2 — Server visibility and security

```json
{
  "allowed_paths": [
    "server/routes/careContext/**",
    "server/routes/people/**",
    "server/test/careContext/**",
    "server/test/people/**",
    "docs/architecture/api-reference.md",
    "docs/domains/pet_care/features/care-context.md",
    "docs/domains/people/features/people-care-team.md"
  ],
  "forbidden_paths": ["flutter_app/**", "e2e/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [],
  "exit_checklist": [
    "Security review completed per .cursor/agent-kernel/protocols/security.md (PR link in control issue)",
    "Full-access viewers read/edit one pet's plan; absence payloads omit inaccessible pet ids/names",
    "Hub list API includes co-visible absences with declarer display name",
    "Full-trip handover assembly filtered server-side for accessible pets only",
    "Tests: declarer, Full partial, Can log care, guest, no access — non-disclosure asserted on JSON",
    "pre-push-changed green"
  ]
}
```

Scope: Implement CARE-CONTEXT-R-032, R-039, R-040 server-side; retire declarer-only reads internally. Document visibility in api-reference and Planned rows (still Planned until fold).

Out of scope: Flutter UI, add/remove pets.

### Phase 3 — Server add/remove pets and lifecycle

```json
{
  "allowed_paths": [
    "server/routes/careContext/**",
    "server/test/careContext/**",
    "server/db/migrations/**",
    "server/test/migrations/**",
    "docs/architecture/api-reference.md",
    "docs/engineering/privacy/erasure-data-map.md"
  ],
  "forbidden_paths": ["flutter_app/**", "e2e/**"],
  "allowed_exceptions": ["docs", "tests"],
  "companions": [],
  "exit_checklist": [
    "Add pet to saved absence (empty plan, overlap warn, guest access confirm per PEOPLE D16)",
    "Remove pet: carer/notes/decisions cleared, access revoked, invites trimmed, care dates unchanged",
    "Last pet removes absence; pet delete cascades absence when empty",
    "AWAY-PLANNING-CARER-R-016 traveller not carer enforced",
    "Migration tests if schema touched",
    "pre-push-changed green"
  ]
}
```

Scope: CARE-CONTEXT-R-033–R-036, R-034, AWAY-PLANNING-CARER-R-016 on server.

Out of scope: Flutter.

### Phase 4 — Flutter absence and away plan screens

```json
{
  "allowed_paths": [
    "flutter_app/lib/features/pet_care/context/**",
    "flutter_app/lib/core/router/**",
    "flutter_app/lib/features/experience/**",
    "flutter_app/test/features/pet_care/context/**",
    "flutter_app/test/bdd/features/away*.feature",
    "flutter_app/test/bdd/features/care_item_absence.feature",
    "docs/e2e/navigation-contract.md"
  ],
  "forbidden_paths": ["server/**"],
  "allowed_exceptions": ["docs", "tests", "l10n"],
  "companions": [],
  "exit_checklist": [
    "Route /pc/away/:id/pets/:petId with return-path navigation",
    "Absence screen: pills, summary Edit -> /pc/away/:id/edit, no duplicated multi-pet sections",
    "Away plan screen: read-only trip, See absence, inline pet notes (R-017), move care sections",
    "Deep links: care item absence module + S7 -> pet plan (R-038)",
    "Widget tests + BDD updates for AP-1–AP-4, AP-6–AP-7, AP-12–AP-13, AP-16–AP-17",
    "flutter analyze + flutter test context suite green",
    "pre-push-changed green"
  ]
}
```

Scope: CARE-CONTEXT-R-025–R-031, R-038 partial UI, AWAY-PLANNING-CARER-R-017 presentation.

Out of scope: Hub co-visible list UI, pet page section, add/remove UI (phase 5).

### Phase 5 — Flutter hub, pet page, add/remove

```json
{
  "allowed_paths": [
    "flutter_app/lib/features/pet_care/context/**",
    "flutter_app/lib/features/pet_profile/**",
    "flutter_app/lib/features/experience/**",
    "flutter_app/test/features/pet_care/**",
    "flutter_app/test/bdd/**",
    "e2e/playwright/tests/away*.spec.ts",
    "e2e/playwright/tests/care.item.absence.spec.ts",
    "docs/e2e/navigation-contract.md",
    "docs/e2e/uat-demo-data.md",
    "server/db/seeds/**"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs", "tests", "l10n", "seeds"],
  "companions": [],
  "exit_checklist": [
    "Hub: co-visible absences, dedupe, section labels (Your absences / pets you help with)",
    "Pet page away section + Plan an absence menu entry",
    "Add pet + Remove pet flows including last-pet confirmation copy",
    "Care item module visible for Full access (R-041)",
    "UAT seed: Frederique 3-pet + co-parent on one pet",
    "Playwright reference + co-parent journeys; navigation-contract EN+FR keys",
    "BDD/E2E check_bdd_coverage report-only no new gaps",
    "pre-push-changed green"
  ]
}
```

Scope: R-031, R-033–R-035 UI, R-039–R-041, AP-5, AP-8–AP-11, AP-14–AP-15, AWAY-PLANNING-CARER-R-018 invite UX.

Out of scope: Canonical fold (phase 6).

### Phase 6 — Fold and release

```json
{
  "allowed_paths": [
    "docs/domains/pet_care/**",
    "docs/domains/people/features/people-care-team.md",
    "docs/design/terminology.md",
    "docs/domains/notifications/features/notifications-v2-spec.md",
    "docs/architecture/api-reference.md"
  ],
  "forbidden_paths": [],
  "allowed_exceptions": ["docs"],
  "companions": [],
  "exit_checklist": [
    "CARE-CONTEXT-R-025–R-041 and AWAY-PLANNING-CARER-R-016–R-018 -> Live with acceptance coverage",
    "Retire R-005, R-008 pet-edit clause, R-012 presentation; reword R-007, R-016 for absence screen",
    "Delete absence-per-pet-away-plans-spec.md and update README delivery table",
    "check_docs_canonical.js 0 block",
    "pre-push.sh green on release PR"
  ]
}
```

Scope: Canonical-docs Mode A fold; delete change spec; mark delivery plan historical or delete per standards.

Out of scope: New behaviour.

## Proof on UAT

See `docs/domains/pet_care/changes/absence-per-pet-away-plans-delivery-plan.md` § Proof on UAT.

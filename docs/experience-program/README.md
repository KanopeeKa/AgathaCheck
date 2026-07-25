# Experience program — navigation, Guardian dashboard, Organisation presentation

Planning and contract documents for the navigation reversal + Guardian dashboard redesign +
Organisation presentation/access-control rework. Master briefs are locked, product-truth
documents; everything else here is the delivery plan built on top of them.

| Doc | Purpose |
|---|---|
| [`briefs/navigation-brief.md`](briefs/navigation-brief.md) | Locked master brief — navigation redesign |
| [`briefs/guardian-dashboard-brief.md`](briefs/guardian-dashboard-brief.md) | Locked master brief — Guardian dashboard redesign |
| [`briefs/organisation-dashboard-brief.md`](briefs/organisation-dashboard-brief.md) | Locked master brief — Organisation dashboard and architecture |
| [`decisions-log.md`](decisions-log.md) | **Read first.** Every locked/TBD product decision, with IDs referenced everywhere else |
| [`program-contract.md`](program-contract.md) | Cross-cutting contract: vocabulary, notification model, permission model, gates, testing, logging, localisation, asset rules |
| [`roadmap-delivery-plan.md`](roadmap-delivery-plan.md) | Phase order, sprint breakdown, branch naming, merge policy |
| [`phase-r-reconciliation.md`](phase-r-reconciliation.md) | Close out navigation-v2 and the paused org-mode-nav plan before new work starts |
| [`phase-0-foundation.md`](phase-0-foundation.md) | Shared primitives (notification schema, dashboard-section widget, permission helper scaffolding) |
| [`phase-1-navigation.md`](phase-1-navigation.md) | Drawer, header, bell, unified notifications, Account area |
| [`phase-2-guardian-journey.md`](phase-2-guardian-journey.md) | Guardian dashboard, Events redefinition, pet timeline, vets, bulk share |
| [`phase-3-organisation-presentation.md`](phase-3-organisation-presentation.md) | Org dashboard, modular org detail, admin contacts, discoverability, legal fields, pet tabs |
| [`phase-4-foster-pet-operations.md`](phase-4-foster-pet-operations.md) | Foster self-management, agreement withdrawal, permission threading |
| [`phase-5-organisation-customisations.md`](phase-5-organisation-customisations.md) | Templates relocation, roles/permissions admin UI, audit log viewer |

**Related prior work this program reconciles with:**

- `docs/design/navigation-v2.md` — superseded (see `phase-r-reconciliation.md`)
- `docs/fostering-platform/` — kept and extended, not replaced (foster/pet operational model)
- `docs/architecture/org-custody-model.md` — kept as-is, pet timeline reads from it

**Status tracking:** phase docs carry their own exit criteria; there is no separate execute-plan
snapshot for this program (single-agent, sequential delivery per decision D33) — see
`roadmap-delivery-plan.md` for the reasoning.

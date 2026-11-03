---
title: Absences and per-pet away plans — delivery plan
owner: Product / Agent
audience: both
status: proposed
status_since: 2026-11-03
folds_into: docs/domains/pet_care/features/care-context.md
related_spec: docs/domains/pet_care/changes/absence-per-pet-away-plans-spec.md
execute_plan_id: absence-per-pet-away-plans-a7566
last_updated: 2026-11-03
---

# Absences and per-pet away plans — delivery plan

**Functional spec:** [absence-per-pet-away-plans-spec.md](./absence-per-pet-away-plans-spec.md) (merge [PR #2035](https://github.com/KanopeeKa/AgathaCheck/pull/2035) first).  
**Execute-plan:** `.agents/plans/absence-per-pet-away-plans-a7566.md` — control issue created by `init`.  
**Canonical contract:** `CARE-CONTEXT-R-025`–`R-041`, `AWAY-PLANNING-CARER-R-016`–`R-018` (Planned until fold).

## Goal

Ship the absence / per-pet away plan UX and API: trip screen with pills, `/pc/away/:id/pets/:petId`, pet page section, co-parent visibility without cross-pet leakage, add/remove pets, then fold canonical docs and retire `R-005` / pet-edit part of `R-008`.

Programme uses **execute-plan v2** (integration branch → one release PR to `main` → Pre-UAT). Slices remain **atomic PRs** squash-merged into integration via the driver.

## Prerequisites

| Item | Status |
|------|--------|
| Functional spec + Planned rows in canonical docs | PR #2035 |
| Product decisions D-011–D-015 | Recorded in spec PR |
| Security review for Full-access absence reads | Phase 2 (approved in principle 2026-11-03) |

## Router (design-scoped summary)

| Surface | Risk | Protocols |
|---------|------|-----------|
| Flutter away/absence/pet hub UI | R2 behaviour | accessibility, flutter-mobile, testing |
| AuthZ / filtered API payloads | R2 | authorization, **security** (phase 2) |
| Migrations (if any) | R2 | database-and-migrations |
| Docs fold | R1 | canonical-docs |

## UI design ( `/ui-design-deep` )

### Scope

| Route / surface | Change |
|-----------------|--------|
| `/pc/away/:id` | **Absence screen** — summary, attention line, pet pills, Add pet, full-trip PDF; remove long multi-pet body |
| `/pc/away/:id/pets/:petId` | **New away plan screen** — read-only trip header + See absence; Who's caring; inline pet notes; care sections; per-pet PDF; Remove pet (overflow) |
| `/pc/away/:id/edit` | **Unchanged route** — trip title, dates, notes, cancel; declarer only; no add/remove pets here |
| `/pc/away`, hub cards | Own absences + co-visible absences (`{Name} is away`); dedupe when viewer is declarer |
| Pet page | Section above People around {Pet}; **Plan an absence** in actions menu |
| Deep links | Care item absence module, S7 → pet away plan; hub/tile → absence |

### System rules (requirement)

1. **Tokens:** away chrome uses `awayContextSurface` / `awayContextAccent` (`docs/design/tokens.md`) — not semantic info/teal for trip chrome.
2. **Hierarchy:** trip summary → pill list → one pet detail; no duplicate Who's caring / Care during blocks on absence screen.
3. **Touch / a11y:** pills and row taps ≥48dp; `Semantics`/`MergeSemantics` on pill cards; FR/EN via ARB keys listed in spec §11.2.
4. **States:** empty Pebble plan (nothing scheduled); cancelled read-only; co-parent single pill; last-pet remove confirmation copy verbatim from spec §3.4.
5. **Hub UX (recommendation):** two sections — **Your absences** / **Absences for pets you help with** — chronological within each; one card per absence (declarer wins copy when both apply).

### Residual product note (recommendation)

Trip-wide notes are visible to any Full-access viewer who can see a pet on the absence (spec §4.2). Free text may name other pets; pills still hide other pets. Accept or add copy guardrail in a follow-up — not blocking delivery.

### UI acceptance checklist (every Flutter phase)

- [ ] Theme tokens, not ad-hoc colours
- [ ] Focus visible; touch ≥48dp on pills and overflow actions
- [ ] l10n EN+FR for new strings (spec §11.2 list)
- [ ] Empty / loading / error on hub list and pet section
- [ ] Experience context `/pc/*` only
- [ ] Widget tests + BDD/E2E updates per phase exit checklist
- [ ] `./scripts/pre-push-changed.sh` green before push

## Phase map (execute-plan)

| Phase | Outcome | Merge to integration |
|-------|---------|----------------------|
| 1 | Server: per-pet read, status facts, pet-page away list (additive API) | Yes |
| 2 | Server: Full-access visibility; filtered absence/pet payloads; PDF data scope; **security review** | Yes |
| 3 | Server: add/remove pets, last-pet delete, cascades, traveller ≠ carer | Yes |
| 4 | Flutter: away plan route + absence screen refactor (pills, inline notes, navigation) | Yes |
| 5 | Flutter: hub co-visible absences, pet section, Plan an absence, add/remove UI | Yes |
| 6 | Fold: Live requirements, acceptance + coverage, terminology, delete change docs | Yes → **release PR to main** |

Phase JSON and paths: see `.agents/plans/absence-per-pet-away-plans-a7566.md`.

## Tests and documentation (per phase)

Each phase PR body must include **## Docs** (canonical-docs sync for behaviour touched) and run `./scripts/pre-push-changed.sh`.

| Layer | When |
|-------|------|
| Server Jest | Phases 1–3 — matrix §5 visibility; add/remove; handover filter |
| Flutter unit/widget | Phases 4–5 — pills, headers, permissions, copy |
| BDD | Phase 4–5 — scenarios for AP-1–AP-18 (atomic scenarios, not one mega-scenario) |
| Playwright | Phase 5 — reference journey §3.1 + co-parent §3.5; update `docs/e2e/navigation-contract.md` |
| Migrations | Phase 1 or 3 only if schema change; `_down.sql` + migration tests |
| UAT seeds | Phase 5 — Frederique Buddy/Whiskers/Pebble + single-pet co-parent fixture (`uat-demo-data.md`) |

**Fold phase** must: move AP-1–AP-18 to canonical acceptance tables with `test:`/`bdd:`; retire `CARE-CONTEXT-R-005`, pet part of `R-008`, `AWAY-PLANNING-CARER-R-012` presentation; update `people-care-team.md` § Away Planning; delete `absence-per-pet-away-plans-spec.md` and this delivery plan row from README active delivery.

## Proof on UAT

1. Log in as Frederique — create or open seeded absence 15–21 Nov with three pets; absence screen shows three pills; Pebble plan shows calm empty-care state.
2. Open Buddy's away plan — edit carer and inline notes; See absence returns to trip.
3. Log in as co-parent with Full access to Buddy only — hub shows `{Name} is away`; absence shows Buddy pill only; cannot Edit trip or Add pet; can edit Buddy's plan.
4. Remove last pet — confirmation mentions absence deletion; absence gone from hub.

## Related

- [care-context.md](../features/care-context.md)
- [away-planning-carer-model.md](../features/away-planning-carer-model.md)
- `.cursor/agent-kernel/protocols/security.md` (phase 2)

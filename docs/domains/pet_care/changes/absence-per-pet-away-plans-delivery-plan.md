---
title: Absences and per-pet away plans — delivery plan
owner: Product / Agent
audience: both
status: in-delivery
last_updated: 2026-11-03
tags: [pet_care, delivery, away]
---

**Execute-plan id:** `absence-per-pet-away-plans-a7566` · **Folds into:** [care-context.md](../features/care-context.md)

# Absences and per-pet away plans — delivery plan

**Functional spec:** [absence-per-pet-away-plans-spec.md](./absence-per-pet-away-plans-spec.md) (merge [PR #2035](https://github.com/KanopeeKa/AgathaCheck/pull/2035) first).  
**Execute-plan:** `.agents/plans/absence-per-pet-away-plans-a7566.md` — control issue [#2036](https://github.com/KanopeeKa/AgathaCheck/issues/2036).  
**Canonical contract:** `CARE-CONTEXT-R-025`–`R-041`, `AWAY-PLANNING-CARER-R-016`–`R-018` (Planned until fold).

## Goal

Ship the absence / per-pet away plan UX and API: trip screen with pills, `/pc/away/:id/pets/:petId`, pet page section, co-parent visibility without cross-pet leakage, add/remove pets, then fold canonical docs and retire `R-005` / pet-edit part of `R-008`.

Programme uses **execute-plan v2** (integration branch → one release PR to `main` → Pre-UAT). Slices remain **atomic PRs** squash-merged into integration via the driver.

## Prerequisites

| Item | Status |
|------|--------|
| Functional spec + Planned rows in canonical docs | PR #2035 |
| Programme registration | PR #2037 |
| Security review for Full-access absence reads | Phase 2 — **owner sign-off on phase 2 PR** before integration merge |
| Release PR to `main` | `release_owner_review: true` on snapshot — owner approves release merge |

## Router (design-scoped summary)

| Surface | Risk | Protocols |
|---------|------|-----------|
| Flutter away/absence/pet hub UI | R2 behaviour | accessibility, flutter-mobile, testing |
| AuthZ / filtered API payloads | R2 | authorization, **security** (phase 2) |
| Migrations (if any) | R2 | database-and-migrations (`db/migrations/**`) |
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
| Deep links | Care item absence module → pet away plan; hub/tile → absence (S7 preference exists but app does not send that notification today) |

### System rules (requirement)

1. **Tokens:** away chrome uses `awayContextSurface` / `awayContextAccent` (`docs/design/tokens.md`) — not semantic info/teal for trip chrome.
2. **Hierarchy:** trip summary → pill list → one pet detail; no duplicate Who's caring / Care during blocks on absence screen.
3. **Touch / a11y:** pills and row taps ≥48dp; `Semantics`/`MergeSemantics` on pill cards; FR/EN via ARB keys (committed `flutter_app/lib/l10n/**` in Flutter phases).
4. **States:** empty Pebble plan (nothing scheduled); cancelled read-only; co-parent single pill; last-pet remove confirmation copy verbatim from spec §3.4.
5. **Hub UX (requirement):** two sections — **Your absences** / **Other people's absences** (FR **Absences des autres**) — chronological within each; one card per absence (declarer's own absences never duplicated under "other").

### Trip notes and co-parents (requirement)

Trip-wide notes are visible to any Full-access viewer who can see a pet on the absence. Matches per-pet PDF trip note inclusion (AWAY-PLANNING-CARER-R-009). Pills still hide other pets.

### UI acceptance checklist (every Flutter phase)

- [ ] Theme tokens, not ad-hoc colours
- [ ] Focus visible; touch ≥48dp on pills and overflow actions
- [ ] l10n EN+FR for new strings
- [ ] Empty / loading / error on hub list and pet section
- [ ] Experience context `/pc/*` only
- [ ] Widget tests + BDD/E2E updates per phase exit checklist
- [ ] `./scripts/pre-push-changed.sh` green before push

## Phase map (execute-plan)

| Phase | Outcome | Merge to integration |
|-------|---------|----------------------|
| 1 | Server: per-pet read, status facts, pet-page away list (additive API) | Yes |
| 2 | Server: Full-access visibility; filtered payloads; PDF scope; **R-041 server**; owner security sign-off | Yes |
| 3 | Server: add/remove pets, last-pet delete, cascades, traveller ≠ carer | Yes |
| 4 | Flutter: away plan route + absence screen refactor (pills, inline notes, navigation) | Yes |
| 5 | Flutter: hub, pet section, add/remove UI, seeds, Playwright + spec-domains | Yes |
| 6 | Fold: Live requirements, acceptance + coverage, delete change docs | Yes → **release PR to main** |

Phase JSON and paths: see `.agents/plans/absence-per-pet-away-plans-a7566.md`.

## Tests and documentation (per phase)

Each phase PR body must include **## Docs** (canonical-docs sync for behaviour touched) and run `./scripts/pre-push-changed.sh`.

| Layer | When |
|-------|------|
| Server Jest | Phases 1–3 — matrix §5 visibility; `loadHealthEntryAbsenceContext`; add/remove; handover filter |
| Flutter unit/widget | Phases 4–5 — pills, headers, permissions, copy |
| BDD | Phases 4–5 — atomic scenarios for AP-1–AP-18 |
| Playwright | Phase 5 — register spec in `e2e/scripts/spec-domains.mjs`; reference §3.1 + co-parent §3.5 (Dave on Buddy); update `navigation-contract.md` and `spec-durations.json` if needed |
| Migrations | Phase 3 only if schema change — `db/migrations/**`, `_down.sql` + `server/test/migrations/**` |
| UAT seeds | Phase 5 — see below |

**Fold phase** must: move AP-1–AP-18 to canonical acceptance tables with `test:`/`bdd:`; retire `CARE-CONTEXT-R-005`, pet part of `R-008`, `AWAY-PLANNING-CARER-R-012` presentation; update `people-care-team.md` § Away Planning; **delete** `absence-per-pet-away-plans-spec.md` and **this delivery plan**; remove README active-delivery row.

## UAT seed (phase 5)

| Fixture | Detail |
|---------|--------|
| Frederique 3-pet absence | Buddy, Whiskers, Pebble — **relative dates** (e.g. `starts_on = today+12`, `ends_on = today+18` at seed run); document offsets in `uat-demo-data.md` |
| Co-parent §3.5 | **Dave** — existing demo user — `co_parent` on **Buddy only** (not Carol; Carol stays `carer` / Can log care for AP-7) |
| Single-pet absence | One pet only — lands on pet plan (AP-2); use for last-pet removal proof |
| Pebble | Empty-care calm state on plan screen |

## Proof on UAT

1. Log in as **Frederique** — open seeded multi-pet absence; absence screen shows three pills; Pebble plan shows calm empty-care state.
2. Open Buddy's away plan — edit carer and inline notes; **See absence** returns to trip.
3. Log in as **Dave** — hub shows Frederique under **Other people's absences**; absence shows Buddy pill only; cannot Edit trip or Add pet; can edit Buddy's plan.
4. On single-pet seeded absence — remove last pet; confirmation mentions absence deletion; absence gone from hub.

## Related

- [care-context.md](../features/care-context.md)
- [away-planning-carer-model.md](../features/away-planning-carer-model.md)
- `.cursor/agent-kernel/protocols/security.md` (phase 2)

---
title: Active codebase metrics headline
owner: Engineering
audience: agent
status: active
last_updated: 2026-10-06
tags: [architecture, metrics, generated]
---

# Architecture size metrics (refined)

Generated: 2026-10-06T22:13:02+00:00 (runtime; commit-scoped counts below are stable)
Repository: `.`
Git commit: `afc7c4ad5c677f0e0b5719a2b0b61156202eb964`

## Exact definitions

- **Review-scope production (headline):** active Flutter library after manifest/generated exclusions, including exclusion of `manifest.activeSurfacesToRemove`, plus the active server route-registration approximation from `server/bin/server.js`, minus the conservative Shelter-family server list below.
- **Active server route-registration approximation:** recursive literal relative `import`, `export ... from`, and `require()` traversal from `server/bin/server.js`, with the three frozen routers whose `app.use` mounts are gated by `frozenDomainsEnabled()` suppressed as review policy: organizations, fosterPlacements, custodyTransfers. Their imports are static and therefore still load under ESM; only registration is gated. This approximation is not actual runtime import reachability or closure. External and dynamic imports are ignored.
- **Server inventory complement:** tracked server source surviving path exclusions but not selected by that review-scope approximation. This is inventory, not a claim of dead or unloaded code: scripts, alternate entries, dynamic loads, and policy-suppressed imports can appear here.
- **Review-safe tests:** code under a `test`, `tests`, `__tests__`, or `e2e` path segment, or with a `.test`/`.spec` filename, after manifest test-root exclusions, `server/jest.config.active.cjs` ignore entries, and exact spec basenames exported by `e2e/scripts/frozen-e2e-specs.mjs`.
- **Shelter-family quality exclusion:** review-scope `server/lib` basenames beginning `org`, `adoption`, `foster`, or `fostering`, plus `custodyTransfers.js`, `sessionDetail.js`, and `deriveSessionStatus.js`. This conservative lexical list follows frozen Jest/domain naming and prevents frozen/mixed internals entering size ranking; it is not a statement that the modules cannot load.
- Inventory is exactly `git ls-files`; untracked files are absent. Source extensions: .cjs, .dart, .js, .jsx, .mjs, .sh, .sql, .ts, .tsx.
- **Approximate nonblank/noncomment lines are heuristic**, not cloc: blank lines, whole-line comments and block-comment spans are removed; strings and SQL dialects are not parsed.

## Headline

| Comparable scope                           | Files | Physical lines | Approx. nonblank noncomment |
| :----------------------------------------- | ----: | -------------: | --------------------------: |
| Review-scope production                    | 1257  | 126,211        | 110,261                     |
|   active Flutter library                   | 926   | 92,130         | 82,544                      |
|   active server registration approximation | 331   | 34,081         | 27,717                      |
| Review-safe tests                          | 807   | 100,768        | 89,069                      |

## Programme comparison (review → roadmap start → Batch K)

Same script and exclusions as [baseline README](./README.md). SCC target for programme exit: **0** multi-feature components.

| Measure | Architecture review `a8c7db1` | Roadmap start `0cc739e` | Batch K integration `afc7c4ad` |
| :-- | --: | --: | --: |
| Unique directed feature edges | 50 | 59 | **35** |
| Matching import directives | 466 | 536 | **347** |
| Multi-feature SCC count | 12 | 1 | **0** |
| Largest review-scope file (physical lines) | — | `projectSchedule.js` (502) | `weightObservationService.js` (551) |
| Longest function span (top-8 heuristic) | — | `registerCrudRoutes` (386) | `registerFamilyEventsRoutes` (274) |

Hotspot deltas (Batch K phases 1–2): route `register*` giants and Flutter `build` spans above **120** lines were split along use-case boundaries; remaining large files are allowlisted in [`size-report.md`](./size-report.md) with owner and review date.

## Classification audit

| Class                                                       | Files | Physical lines | Meaning                       |
| :---------------------------------------------------------- | ----: | -------------: | :---------------------------- |
| Server registration approximation (before family exclusion) | 341   | 36,718         | review-policy traversal       |
| Shelter-family removed from quality scope                   | 10    | 2,637          | conservative lexical list     |
| Server inventory complement                                 | 97    | 9,757          | not selected by approximation |
| Additional frozen CI tests removed                          | 38    | 6,152          | active Jest + frozen E2E sets |

### Shelter-family inventory excluded from quality totals/ranking

Every matching file is excluded: `review scope; removed` means it was subtracted from the registration approximation, while `inventory complement` means it did not enter that approximation. Neither label claims runtime loading behavior.

- `server/lib/adoptionJourneys.js` — inventory complement
- `server/lib/adoptionVisits.js` — inventory complement
- `server/lib/custodyTransfers.js` — review scope; removed
- `server/lib/deriveSessionStatus.js` — inventory complement
- `server/lib/email/templates/fosterInvitationNewUser.js` — inventory complement
- `server/lib/fosterAgreementWithdrawal.js` — inventory complement
- `server/lib/fosterCapacity.js` — inventory complement
- `server/lib/fosterCompliance.js` — inventory complement
- `server/lib/fosterInvite.js` — inventory complement
- `server/lib/fosterParentPresenter.js` — inventory complement
- `server/lib/fosterPlacements.js` — review scope; removed
- `server/lib/fosterProfiles.js` — inventory complement
- `server/lib/fosterRequests.js` — inventory complement
- `server/lib/fosterSessions.js` — inventory complement
- `server/lib/fosterVisibility.js` — inventory complement
- `server/lib/fosteringActivitySummary.js` — inventory complement
- `server/lib/orgConnections.js` — review scope; removed
- `server/lib/orgMemberPrivacy.js` — review scope; removed
- `server/lib/orgPeople.js` — review scope; removed
- `server/lib/orgPermissions.js` — review scope; removed
- `server/lib/orgPetShadow.js` — review scope; removed
- `server/lib/orgPetTransfer.js` — review scope; removed
- `server/lib/orgPetViewAccess.js` — review scope; removed
- `server/lib/orgRoles.js` — review scope; removed
- `server/lib/sessionDetail.js` — inventory complement

### Additional frozen CI tests removed

These are the non-manifest-root files selected by active Jest ignore entries or the frozen E2E set; manifest-root tests are already counted in path exclusions.

- `e2e/playwright/tests/adoption.spec.ts`
- `e2e/playwright/tests/experience.foster-portal.spec.ts`
- `e2e/playwright/tests/foster.onboarding.spec.ts`
- `e2e/playwright/tests/fostering.platform.spec.ts`
- `e2e/playwright/tests/fostering.session-detail.spec.ts`
- `e2e/playwright/tests/org.onboarding.spec.ts`
- `e2e/playwright/tests/org.timeline.spec.ts`
- `e2e/playwright/tests/organisation.admin-contacts.spec.ts`
- `e2e/playwright/tests/organisation.connections.spec.ts`
- `e2e/playwright/tests/organisation.customisations.spec.ts`
- `e2e/playwright/tests/organisation.dashboard.spec.ts`
- `e2e/playwright/tests/organisation.discovery.spec.ts`
- `e2e/playwright/tests/organisation.edit.spec.ts`
- `e2e/playwright/tests/organisation.management.spec.ts`
- `e2e/playwright/tests/organisation.member.privacy.spec.ts`
- `e2e/playwright/tests/organisation.permissions.spec.ts`
- `e2e/playwright/tests/organisation.pet-filters.spec.ts`
- `e2e/playwright/tests/organisation.pet.management.spec.ts`
- `e2e/playwright/tests/organisation.profile.spec.ts`
- `e2e/playwright/tests/organisation.redacted-pet.spec.ts`
- `e2e/playwright/tests/organisation.sessions.spec.ts`
- `server/test/adoptionJourneys.test.js`
- `server/test/adoptionVisits.test.js`
- `server/test/custodyTransfers.test.js`
- `server/test/externalFosterNotice.test.js`
- `server/test/fosterCapacity.test.js`
- `server/test/fosterPlacements.test.js`
- `server/test/fosteringActivitySummary.test.js`
- `server/test/orgConnections.test.js`
- `server/test/orgPeople.test.js`
- `server/test/orgPeopleRedaction.test.js`
- `server/test/orgPermissions.test.js`
- `server/test/orgPetTransfer.test.js`
- `server/test/orgRoles.test.js`
- `server/test/organizationsDiscover.test.js`
- `server/test/pets/orgMembership.test.js`
- `server/test/sessionDetail.test.js`
- `server/test/sessionLifecycle.test.js`

## Active Flutter library by feature/core

| Area                            | Files | Physical lines | Heuristic lines |
| :------------------------------ | ----: | -------------: | --------------: |
| app_care_provider_contacts.dart | 1     | 28             | 24              |
| app_pet_care_sync.dart          | 1     | 28             | 22              |
| core/branding                   | 1     | 85             | 54              |
| core/care                       | 1     | 18             | 15              |
| core/config                     | 1     | 20             | 12              |
| core/experience                 | 1     | 31             | 25              |
| core/files                      | 5     | 63             | 46              |
| core/legal                      | 1     | 53             | 49              |
| core/network                    | 1     | 83             | 57              |
| core/providers                  | 6     | 147            | 117             |
| core/router                     | 10    | 1,135          | 1,022           |
| core/services                   | 4     | 322            | 277             |
| core/theme                      | 4     | 560            | 470             |
| core/utils                      | 5     | 345            | 274             |
| core/web                        | 6     | 182            | 127             |
| core/weight                     | 2     | 44             | 27              |
| core/widgets                    | 36    | 3,129          | 2,769           |
| feature/about                   | 8     | 351            | 323             |
| feature/auth                    | 39    | 4,868          | 4,507           |
| feature/care_intelligence       | 20    | 1,274          | 1,124           |
| feature/care_item               | 29    | 3,014          | 2,493           |
| feature/care_taxonomy           | 13    | 651            | 600             |
| feature/experience              | 149   | 18,603         | 16,756          |
| feature/health_tracking         | 159   | 17,067         | 15,266          |
| feature/help                    | 2     | 241            | 208             |
| feature/notifications           | 43    | 4,335          | 3,938           |
| feature/people                  | 111   | 12,530         | 11,436          |
| feature/pet_care                | 73    | 7,648          | 6,845           |
| feature/pet_profile             | 110   | 7,081          | 6,230           |
| feature/pet_tags                | 12    | 789            | 702             |
| feature/sharing                 | 35    | 3,800          | 3,462           |
| feature/subscription            | 9     | 800            | 714             |
| feature/weight_tracking         | 27    | 2,647          | 2,409           |
| main.dart                       | 1     | 158            | 144             |

## Active server route-registration approximation by area

| Area       | Files | Physical lines | Heuristic lines |
| :--------- | ----: | -------------: | --------------: |
| bin        | 1     | 180            | 160             |
| config     | 10    | 468            | 309             |
| db         | 5     | 516            | 457             |
| lib        | 200   | 23,412         | 18,216          |
| middleware | 2     | 76             | 59              |
| routes     | 102   | 8,210          | 7,453           |
| services   | 11    | 1,219          | 1,063           |

## Review-safe tests

| Area        | Files | Physical lines | Heuristic lines |
| :---------- | ----: | -------------: | --------------: |
| .github     | 5     | 365            | 311             |
| e2e         | 112   | 22,048         | 18,611          |
| flutter_app | 363   | 42,631         | 38,165          |
| scripts     | 60    | 3,680          | 3,159           |
| server      | 267   | 32,044         | 28,823          |

## Biggest 15 review-scope production files

| File                                                                                                  | Physical lines | Heuristic lines |
| :---------------------------------------------------------------------------------------------------- | -------------: | --------------: |
| server/lib/care/observations/weightObservationService.js                                              | 551            | 470             |
| server/lib/care/occurrence/occurrenceRepository.js                                                    | 501            | 331             |
| flutter_app/lib/features/weight_tracking/presentation/sheets/record_weight_sheet.dart                 | 473            | 441             |
| server/lib/people/vetProjection.js                                                                    | 470            | 383             |
| flutter_app/lib/features/experience/presentation/care_item/detail/care_item_detail_body.dart          | 468            | 433             |
| flutter_app/lib/features/experience/presentation/care_item/occurrence/occurrence_blocks.dart          | 467            | 439             |
| flutter_app/lib/core/router/app_router.dart                                                           | 440            | 425             |
| server/lib/care/schedule/projectSchedule.js                                                           | 434            | 299             |
| server/lib/people/contactsRepo.js                                                                     | 432            | 396             |
| flutter_app/lib/features/health_tracking/domain/entities/health_entry.dart                            | 418            | 289             |
| flutter_app/lib/features/notifications/presentation/widgets/notification_settings_matrix_section.dart | 417            | 398             |
| flutter_app/lib/features/people/data/dto/people_dtos.dart                                             | 417            | 403             |
| flutter_app/lib/features/experience/presentation/care_item/detail/care_item_dates_section.dart        | 402            | 373             |
| server/lib/care/observations/weightFulfilmentService.js                                               | 402            | 342             |
| flutter_app/lib/features/health_tracking/presentation/controllers/health_entry_form_controller.dart   | 401            | 343             |

## Function-length heuristic: top 8

This is deliberately narrow and approximate: only JS/TS/Dart functions whose complete signature and opening brace are on one line are candidates. Comments and simple quoted strings are stripped, then physical lines are counted until braces balance. Multiline signatures are missed; regex literals, interpolation, unusual syntax, or braces in complex strings can distort spans. Use only as a triage signal, never a quality gate.

| Function                       | File:line                                                                                         | Physical span |
| :----------------------------- | :------------------------------------------------------------------------------------------------ | ------------: |
| registerFamilyEventsRoutes     | server/routes/pets/familyEventsRouter.js:9                                                        | 274           |
| build                          | flutter_app/lib/features/notifications/presentation/widgets/notification_tile.dart:32             | 225           |
| createWeightEntriesWriteRouter | server/routes/weightEntries/writeRouter.js:24                                                     | 214           |
| build                          | flutter_app/lib/features/experience/presentation/care_item/detail/care_item_detail_screen.dart:29 | 210           |
| build                          | flutter_app/lib/features/experience/presentation/widgets/experience_shell_scaffold.dart:87        | 205           |
| build                          | flutter_app/lib/features/auth/presentation/screens/signup_screen.dart:57                          | 202           |
| updateHealthEntry              | server/lib/health/healthEntryWriteService.js:178                                                  | 194           |
| build                          | flutter_app/lib/features/weight_tracking/presentation/widgets/weight_chart.dart:25                | 193           |

## Cross-feature Flutter imports

Only literal Dart `import`, `export`, and `part` directives are scanned. Package paths resolve at `flutter_app/lib`; relative paths normalize from the importer. URI conditionals, interpolation, aliases and runtime references are ignored; self-feature edges are omitted.

Unique directed feature edges: **35**; matching directives: **347**.

| Edge                                | Importing files | Directives |
| :---------------------------------- | --------------: | ---------: |
| care_intelligence → auth            | 1               | 1          |
| care_intelligence → health_tracking | 1               | 1          |
| care_intelligence → pet_profile     | 3               | 3          |
| experience → auth                   | 6               | 6          |
| experience → care_intelligence      | 7               | 7          |
| experience → care_item              | 14              | 14         |
| experience → care_taxonomy          | 3               | 3          |
| experience → health_tracking        | 46              | 51         |
| experience → notifications          | 7               | 7          |
| experience → people                 | 11              | 11         |
| experience → pet_care               | 31              | 31         |
| experience → pet_profile            | 71              | 71         |
| experience → pet_tags               | 2               | 2          |
| experience → sharing                | 7               | 7          |
| experience → weight_tracking        | 7               | 7          |
| health_tracking → auth              | 5               | 5          |
| health_tracking → care_item         | 3               | 3          |
| health_tracking → care_taxonomy     | 15              | 15         |
| health_tracking → pet_profile       | 30              | 30         |
| notifications → auth                | 1               | 1          |
| notifications → pet_profile         | 6               | 6          |
| people → auth                       | 2               | 2          |
| people → pet_profile                | 3               | 3          |
| pet_care → auth                     | 3               | 3          |
| pet_care → care_item                | 3               | 3          |
| pet_care → health_tracking          | 11              | 14         |
| pet_care → people                   | 3               | 3          |
| pet_care → pet_profile              | 12              | 12         |
| pet_profile → auth                  | 3               | 3          |
| pet_profile → care_taxonomy         | 3               | 3          |
| pet_tags → auth                     | 1               | 1          |
| sharing → auth                      | 4               | 4          |
| sharing → pet_profile               | 12              | 12         |
| subscription → auth                 | 1               | 1          |
| weight_tracking → auth              | 1               | 1          |

### Cycles

Strongly connected multi-feature components: **0**. Components mean mutual reachability, not every simple cycle.

_No multi-feature cycle found under these assumptions._

## Exclusions

| Reason                             | Tracked files | Source files | Source physical lines |
| :--------------------------------- | ------------: | -----------: | --------------------: |
| frozen manifest roots              | 354           | 351          | 49,008                |
| manifest active surfaces to remove | 2             | 2            | 329                   |
| generated source                   | 3             | 3            | 31,939                |
| build/tool outputs                 | 0             | 0            | 0                     |
| dependency outputs                 | 0             | 0            | 0                     |
| design/media outputs               | 251           | 175          | 15,827                |

Tracked files total: **4,082**. Eligible source files after path exclusions: **2,569**. Files outside exact headline definitions remain inventory only. Frozen CI test removals are classification removals in addition to path exclusions and are reported above.

## Reproduce

```sh
python3 scripts/architecture/architecture-metrics.py --repo "$(git rev-parse --show-toplevel)" --output /tmp/architecture-metrics.md
```

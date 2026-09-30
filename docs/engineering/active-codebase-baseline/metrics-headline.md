---
title: Active codebase metrics headline
owner: Engineering
audience: agent
status: active
last_updated: 2026-09-29
tags: [architecture, metrics, generated]
---

# Architecture size metrics (refined)

Generated: 2026-09-29T22:42:58+00:00 (runtime; commit-scoped counts below are stable)
Repository: `.`
Git commit: `f669b3ef18dbd5939caefc211c6ed05599aee524`

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
| Review-scope production                    | 914   | 98,755         | 86,833                      |
|   active Flutter library                   | 704   | 75,405         | 67,558                      |
|   active server registration approximation | 210   | 23,350         | 19,275                      |
| Review-safe tests                          | 570   | 79,246         | 69,601                      |

## Classification audit

| Class                                                       | Files | Physical lines | Meaning                       |
| :---------------------------------------------------------- | ----: | -------------: | :---------------------------- |
| Server registration approximation (before family exclusion) | 220   | 25,987         | review-policy traversal       |
| Shelter-family removed from quality scope                   | 10    | 2,637          | conservative lexical list     |
| Server inventory complement                                 | 76    | 8,328          | not selected by approximation |
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

| Area                      | Files | Physical lines | Heuristic lines |
| :------------------------ | ----: | -------------: | --------------: |
| core/branding             | 1     | 85             | 54              |
| core/config               | 1     | 20             | 12              |
| core/network              | 1     | 83             | 57              |
| core/providers            | 6     | 143            | 114             |
| core/router               | 8     | 1,116          | 1,014           |
| core/services             | 4     | 321            | 276             |
| core/theme                | 4     | 559            | 469             |
| core/utils                | 5     | 345            | 274             |
| core/web                  | 6     | 182            | 127             |
| core/widgets              | 26    | 2,558          | 2,281           |
| feature/about             | 7     | 454            | 419             |
| feature/auth              | 27    | 4,404          | 4,084           |
| feature/care_intelligence | 18    | 1,133          | 1,005           |
| feature/care_taxonomy     | 7     | 401            | 369             |
| feature/experience        | 62    | 8,148          | 7,111           |
| feature/health_tracking   | 144   | 18,241         | 16,453          |
| feature/help              | 1     | 237            | 206             |
| feature/notifications     | 18    | 2,325          | 2,107           |
| feature/people            | 16    | 2,257          | 2,094           |
| feature/pet_care          | 72    | 7,610          | 6,800           |
| feature/pet_profile       | 180   | 16,325         | 14,696          |
| feature/pet_tags          | 11    | 779            | 694             |
| feature/sharing           | 40    | 4,007          | 3,649           |
| feature/subscription      | 4     | 722            | 651             |
| feature/vet               | 27    | 2,443          | 2,104           |
| feature/weight_tracking   | 7     | 396            | 341             |
| main.dart                 | 1     | 111            | 97              |

## Active server route-registration approximation by area

| Area       | Files | Physical lines | Heuristic lines |
| :--------- | ----: | -------------: | --------------: |
| bin        | 1     | 178            | 159             |
| config     | 10    | 430            | 280             |
| db         | 3     | 467            | 426             |
| lib        | 111   | 12,451         | 9,449           |
| middleware | 2     | 76             | 59              |
| routes     | 79    | 8,764          | 8,024           |
| services   | 4     | 984            | 878             |

## Review-safe tests

| Area        | Files | Physical lines | Heuristic lines |
| :---------- | ----: | -------------: | --------------: |
| .github     | 5     | 365            | 311             |
| e2e         | 89    | 16,684         | 13,904          |
| flutter_app | 282   | 36,220         | 31,988          |
| scripts     | 36    | 2,706          | 2,322           |
| server      | 158   | 23,271         | 21,076          |

## Biggest 15 review-scope production files

| File                                                                                                   | Physical lines | Heuristic lines |
| :----------------------------------------------------------------------------------------------------- | -------------: | --------------: |
| server/lib/care/schedule/projectSchedule.js                                                            | 502            | 362             |
| flutter_app/lib/features/auth/presentation/widgets/landing/landing_auth_forms.dart                     | 488            | 467             |
| server/routes/healthEntries/occurrencesRouter.js                                                       | 474            | 453             |
| flutter_app/lib/core/widgets/consent_banner.dart                                                       | 463            | 435             |
| flutter_app/lib/features/subscription/presentation/screens/paywall_screen.dart                         | 457            | 435             |
| server/services/sharing/shareInviteService.js                                                          | 456            | 408             |
| flutter_app/lib/features/pet_profile/presentation/screens/pet_form_screen.dart                         | 441            | 406             |
| flutter_app/lib/features/notifications/presentation/widgets/notification_panel.dart                    | 437            | 398             |
| flutter_app/lib/core/router/app_router.dart                                                            | 427            | 412             |
| flutter_app/lib/features/experience/presentation/screens/pet_care/pet_care_due_events_screen.dart      | 421            | 342             |
| server/routes/healthEntries/crudRouter.js                                                              | 416            | 409             |
| server/routes/pets/coreRouter.js                                                                       | 416            | 409             |
| flutter_app/lib/features/pet_profile/presentation/screens/widgets/manage_events_collection_filter.dart | 411            | 372             |
| flutter_app/lib/features/experience/presentation/screens/pet_care/global_events_list.dart              | 409            | 317             |
| flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart                         | 409            | 391             |

## Function-length heuristic: top 8

This is deliberately narrow and approximate: only JS/TS/Dart functions whose complete signature and opening brace are on one line are candidates. Comments and simple quoted strings are stripped, then physical lines are counted until braces balance. Multiline signatures are missed; regex literals, interpolation, unusual syntax, or braces in complex strings can distort spans. Use only as a triage signal, never a quality gate.

| Function                     | File:line                                                                                            | Physical span |
| :--------------------------- | :--------------------------------------------------------------------------------------------------- | ------------: |
| registerCrudRoutes           | server/routes/healthEntries/crudRouter.js:31                                                         | 386           |
| registerCoreRoutes           | server/routes/pets/coreRouter.js:47                                                                  | 370           |
| registerOccurrenceRoutes     | server/routes/healthEntries/occurrencesRouter.js:65                                                  | 358           |
| build                        | flutter_app/lib/features/pet_profile/presentation/screens/pet_list_screen.dart:58                    | 351           |
| registerFamilyEventsRoutes   | server/routes/pets/familyEventsRouter.js:9                                                           | 274           |
| registerCompletionRoutes     | server/routes/healthEntries/completionRouter.js:17                                                   | 261           |
| registerPlannedAbsenceRoutes | server/routes/careContext/plannedAbsencesRouter.js:44                                                | 253           |
| build                        | flutter_app/lib/features/pet_profile/presentation/widgets/pet_detail/pet_detail_profile_card.dart:33 | 242           |

## Cross-feature Flutter imports

Only literal Dart `import`, `export`, and `part` directives are scanned. Package paths resolve at `flutter_app/lib`; relative paths normalize from the importer. URI conditionals, interpolation, aliases and runtime references are ignored; self-feature edges are omitted.

Unique directed feature edges: **59**; matching directives: **536**.

| Edge                                | Importing files | Directives |
| :---------------------------------- | --------------: | ---------: |
| auth → about                        | 1               | 1          |
| auth → experience                   | 4               | 4          |
| care_intelligence → auth            | 1               | 1          |
| care_intelligence → health_tracking | 1               | 1          |
| care_intelligence → pet_care        | 4               | 5          |
| care_intelligence → pet_profile     | 4               | 5          |
| care_taxonomy → health_tracking     | 1               | 2          |
| care_taxonomy → pet_profile         | 3               | 3          |
| experience → auth                   | 5               | 6          |
| experience → health_tracking        | 8               | 19         |
| experience → notifications          | 2               | 2          |
| experience → people                 | 1               | 4          |
| experience → pet_care               | 5               | 7          |
| experience → pet_profile            | 23              | 55         |
| experience → pet_tags               | 1               | 3          |
| experience → sharing                | 3               | 3          |
| experience → vet                    | 1               | 3          |
| health_tracking → auth              | 3               | 3          |
| health_tracking → care_taxonomy     | 13              | 25         |
| health_tracking → experience        | 2               | 4          |
| health_tracking → people            | 2               | 3          |
| health_tracking → pet_care          | 9               | 22         |
| health_tracking → pet_profile       | 38              | 75         |
| health_tracking → weight_tracking   | 1               | 1          |
| notifications → auth                | 1               | 1          |
| notifications → pet_profile         | 6               | 10         |
| people → auth                       | 1               | 1          |
| people → experience                 | 2               | 4          |
| people → pet_profile                | 1               | 2          |
| people → sharing                    | 1               | 2          |
| people → vet                        | 2               | 3          |
| pet_care → auth                     | 3               | 3          |
| pet_care → care_intelligence        | 3               | 7          |
| pet_care → experience               | 4               | 8          |
| pet_care → health_tracking          | 8               | 17         |
| pet_care → people                   | 1               | 2          |
| pet_care → pet_profile              | 12              | 16         |
| pet_profile → auth                  | 4               | 4          |
| pet_profile → care_intelligence     | 2               | 4          |
| pet_profile → care_taxonomy         | 5               | 6          |
| pet_profile → experience            | 17              | 29         |
| pet_profile → health_tracking       | 31              | 67         |
| pet_profile → notifications         | 4               | 4          |
| pet_profile → people                | 2               | 3          |
| pet_profile → pet_care              | 12              | 18         |
| pet_profile → pet_tags              | 1               | 1          |
| pet_profile → sharing               | 7               | 7          |
| pet_profile → vet                   | 3               | 3          |
| pet_profile → weight_tracking       | 10              | 16         |
| pet_tags → auth                     | 1               | 1          |
| pet_tags → experience               | 1               | 2          |
| sharing → auth                      | 6               | 6          |
| sharing → experience                | 2               | 4          |
| sharing → pet_profile               | 12              | 15         |
| subscription → auth                 | 1               | 1          |
| vet → auth                          | 1               | 1          |
| vet → experience                    | 1               | 1          |
| vet → pet_profile                   | 6               | 9          |
| weight_tracking → auth              | 1               | 1          |

### Cycles

Strongly connected multi-feature components: **1**. Components mean mutual reachability, not every simple cycle.

- auth ↔ care_intelligence ↔ care_taxonomy ↔ experience ↔ health_tracking ↔ notifications ↔ people ↔ pet_care ↔ pet_profile ↔ pet_tags ↔ sharing ↔ vet ↔ weight_tracking

## Exclusions

| Reason                             | Tracked files | Source files | Source physical lines |
| :--------------------------------- | ------------: | -----------: | --------------------: |
| frozen manifest roots              | 354           | 351          | 48,995                |
| manifest active surfaces to remove | 2             | 2            | 329                   |
| generated source                   | 3             | 3            | 27,157                |
| build/tool outputs                 | 0             | 0            | 0                     |
| dependency outputs                 | 0             | 0            | 0                     |
| design/media outputs               | 251           | 175          | 15,827                |

Tracked files total: **3,280**. Eligible source files after path exclusions: **1,917**. Files outside exact headline definitions remain inventory only. Frozen CI test removals are classification removals in addition to path exclusions and are reported above.

## Reproduce

```sh
python3 scripts/architecture/architecture-metrics.py --repo "$(git rev-parse --show-toplevel)" --output /tmp/architecture-metrics.md
```

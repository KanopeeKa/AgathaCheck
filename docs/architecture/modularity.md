---
title: Modularity conventions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-09-29
tags: [architecture, modularity]
---
# Modularity & refactoring rules

Conventions for Agatha Track to keep files small, testable, and aligned across
Flutter and Node.js.

---

## General principles

1. **Prefer many small files over few large ones.** When unsure, split.
2. **Tests and docs lead refactors** — extract or add tests before moving production code.
3. **Preserve business logic** — behaviour-preserving moves only; no drive-by feature changes.
4. **Domain by domain** — finish one bounded context (routes + tests + Flutter UI) before starting the next.
5. **Committed code must run** — `flutter analyze`, `flutter test`, and `npx jest` green before push.

---

## File size targets (hand-written code)

| Lines | Action |
|------:|--------|
| &lt; 300 | Ideal for screens, route modules, widgets |
| 300–500 | Acceptable; split when adding features |
| 500–800 | Split on next touch |
| &gt; 800 | Split immediately |

**Exceptions:** generated code (`l10n/`, `*.g.dart`), lockfiles, canonical SQL schema.

---

## Backend (Node.js)

```
server/routes/<domain>/
  index.js          # Composes sub-routers; default export for server.js
  shared.js         # Auth helpers, mappers, constants (no routes)
  <area>Router.js   # e.g. invitesRouter.js, placementsRouter.js
server/lib/         # Cross-route business logic (already used)
server/test/<domain>/
  helpers.js        # Mock pool, fixtures
  <area>.test.js    # Mirrors route modules
```

- Export test-only helpers from `shared.js` when needed (`getMemberRole`, etc.).
- Mount order: **static paths before `/:id`** (invites, join, etc. before param routes).
- Keep `/api/...` and `/backend/api/...` dual mount in `server.js` only.

---

## Flutter

```
features/<feature>/
  presentation/
    controllers/    # Form/screen logic (StateNotifier or plain classes)
    screens/        # Thin composition; target &lt; 300 lines
    widgets/        # One primary widget per file; subfolders for complex screens
  domain/
  data/
test/features/<feature>/   # Mirror lib structure
```

- **No private widget classes &gt; 80 lines in screen files** — move to `widgets/`.
- Controllers own validation, submit, and async orchestration; screens own layout.
- Stub controllers: keep file, mark `@pending-review` in `refactoring-debt.md`, do not wire until approved.

---

## Cross-feature imports (D5/D6 gate)

`node scripts/check_feature_imports.js` blocks **new** cross-feature import violations in `flutter_app/lib`. It runs in `scripts/pre-push.sh`, `scripts/pre-push-changed.sh` and the CI governance job. Existing violations are recorded by **identity** (`rule|importer|target`, not counts) in `scripts/feature-import-baseline.json`, so removing one violation cannot hide a different new one.

| Rule | Fails when |
|---|---|
| R1 `domain-to-experience` | A feature other than `experience` imports anything under `features/experience/` (domain features never depend on the shell). |
| R2 `cross-feature-data` | Code outside feature X imports `features/X/data/**`. Use X's domain port or provider instead. |
| R3 `cross-feature-presentation` | Code outside feature X imports `features/X/presentation/**`. |
| R4 `new-feature-edge` | A feature → feature import edge appears that is not in the baseline edge list. |

**Composition entrypoints (D5):** `lib/features/experience/**`, `lib/core/router/**` and the root wiring files `lib/*.dart` may import other features' presentation (R3 exempt). They are still subject to R2. There is no blanket `core/**` exemption.

**Scope:** active Dart files only. Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/l10n/`), the frozen `sourceRoots` and `activeSurfacesToRemove` from `docs/engineering/frozen-domains/manifest.json` are skipped. Every run also prints the feature-level strongly connected components (informational until the no-cycle rule lands).

**Baseline workflow — it only shrinks:**

- Fixed a violation? The check fails with `RESOLVED …` until you run `node scripts/check_feature_imports.js --update-baseline` and commit the smaller baseline in the same PR.
- `--update-baseline` refuses to add anything.
- A genuinely approved exception uses `--accept-new "<reason + approval link>"`, which records the identity, reason and date under `exceptions`. Only use it with explicit human approval recorded on the PR.
- `--summary` prints the current counts without failing.

## Feature ports and transport (Flutter)

This is the target shape for a feature's data access. Batch H of `active-codebase-completion-e41f` converts auth and health documents to it. New or rewritten data layers (for example the People client refactor) should use it from the start, so they are not converted twice.

| Layer | Owns | Must not |
|---|---|---|
| `domain/` | Entities with value equality, and **ports**: abstract repositories such as `AuthRepository`, `SessionStore` or `HealthDocumentsRepository`. Ports return domain types and typed failures. | Import `application/`, `data/`, `package:http` or Flutter widgets. |
| `data/` | Port implementations, remote data sources, DTOs and their mapping to entities. The only place wire strings exist. | Be imported from another feature (R2 above) or from its own `presentation/`. |
| `application/` | Wiring and use-case state: one provider per port that picks the `data/` implementation, derived providers, commands and form controllers. With `data/`, the only layer that may import `data/`. | Import `presentation/`. |
| `presentation/` | Screens, widgets and routes. They read `application/` providers and `domain/` types. | Construct services or clients (`AuthService()`, `http.Client()`), or import `data/**`. |

**One transport authority.** Every authenticated request goes through the injected `AuthHttpClient` (`lib/core/network/auth_http_client.dart`), obtained through `authHttpClientProvider`. It injects the bearer token and performs the single 401 → refresh → replay. Features never:

- build `Authorization` headers by hand;
- call the refresh endpoint;
- keep their own copy of the access token.

A session that cannot be refreshed surfaces as `SessionExpiredException`. Map it, and HTTP 4xx, 5xx and network errors, to the port's typed failures inside `data/`, not in widgets.

**Wiring.** One provider per port in `application/`, typed as the port (`Provider<XRepository>`). Tests override that provider with a fake, so presentation tests need no HTTP mocking. Never keep two providers for the same data source. A provider that loads an entity never writes back into the provider it watches: without value equality this refetches forever (the People detail loop, B1 in `docs/domains/people/changes/people-domain-refactor.md`).

Existing features still declare providers under `presentation/providers/`. They move to `application/` when their data layer is converted (Batch H for auth and health documents; the People client refactor for People).

**Public entrypoint (D20, Batch I1).** Each feature will expose one entrypoint, `lib/features/<feature>/<feature>.dart`, that exports its domain types, ports, providers and the UI surfaces other features may use. It never exports `data/`. Once it exists, other features import only the entrypoint. Until then, the cross-feature import gate above keeps new edges out.

## Testing expectations

| Layer | Tool | When |
|---|---|---|
| Node routes | Jest + supertest | Every route module |
| Node shared libs | Jest (integration via route tests) | When adding cross-route helpers |
| Flutter domain/data | `flutter test` | Models, repos, datasources |
| Flutter UI | Widget tests | Extracted widgets + critical screens |
| Journeys | Playwright (`e2e/`) | After domain stabilises; annotate `@bdd` |

Add tests **before or during** extraction, not after.

---

## Documentation

- Update `docs/architecture/api-reference.md` only when wire format changes.
- Park deferrals in `docs/debt/debt.md` (open items only).

---

## Legal assets

- Source of truth: `regulatory/legal/`
- App bundle: `flutter_app/assets/legal/` via `node scripts/sync_legal_documents.js`
- Run sync before release builds (CI step recommended).

---
title: Modularity conventions
owner: Documentation Team
audience: both
status: active
last_updated: 2026-08-22
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

- Update `docs/api-reference.md` only when wire format changes.
- Park deferrals in `docs/debt/refactoring-debt.md`.
- Product/infra deferrals stay in `docs/debt/technical-debt.md`.

---

## Legal assets

- Source of truth: `regulatory/legal/`
- App bundle: `flutter_app/assets/legal/` via `node scripts/sync_legal_documents.js`
- Run sync before release builds (CI step recommended).

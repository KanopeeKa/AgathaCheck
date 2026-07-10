# Sprint 9 — Dart org foster parity branch audit

**Agent:** `dart-foster-audit`  
**Date:** 2026-07-10  
**Stale branch:** `origin/cursor/dart-org-foster-parity-b4c2`  
**Compared to:** `origin/main`  
**Merge base:** `8685772` (`test(org): split organization_providers_test by provider group` — PR #63)

---

## 1. Summary verdict

**Superseded — safe to delete the branch; do not cherry-pick or merge.**

The branch’s substantive work landed on `main` via **PR #64** (`3a0ac48`, 2026-07-07). `main` has since moved ahead with Sprint 5.4 (placements module split), Sprint 6–7 org custody (Node connections + custody transfers), and Sprint 8 agent-efficiency infra. The branch tip adds no unique behaviour—only an obsolete 567-line placements monolith (superseded by modular files under 500 lines) and trivial formatting deltas.

| Option | Assessment |
|--------|------------|
| Cherry-pick | **No** — commits already on `main` |
| Partial merge | **No** — would regress modular layout and miss 40+ `main` commits |
| Superseded | **Yes** — PR #64 + later sprints absorbed and improved the work |
| Obsolete | **Yes** — branch pointer is stale; keeping it risks mistaken reuse |

---

## 2. File-by-file diff analysis

**Command:** `git diff origin/main...origin/cursor/dart-org-foster-parity-b4c2`  
**Scope:** 12 files, +1,699 / −16 lines (three-dot diff = branch-only delta vs merge base).

### Branch commits (not on `main` as branch tip)

| Commit | Message | Status on `main` |
|--------|---------|------------------|
| `2eb43e5` | `test(org): split organization_providers_test by provider group` | Merged **#63** (`8685772`) |
| `210c791` | `fix(test): update imports after organization_providers_test split` | Merged in **#64** |
| `037e3f6` | `feat(server): Dart org foster/placements/people parity with Node` | Merged **#64** (`3a0ac48`) |
| `c22fc8f` | `merge: resolve main conflict in refactoring-debt.md` | Branch-only merge commit; doc text already on `main` |

`git diff 037e3f6 3a0ac48` shows a **single-line** `docs/refactoring-debt.md` delta — the merged PR is effectively identical to the branch feature commit.

### Per-file breakdown

| File | Branch delta | Unique vs `main`? | Notes |
|------|--------------|-------------------|-------|
| `docs/refactoring-debt.md` | Marks foster/placements/people Dart parity **Done** | **No** — same updates on `main` | Changelog entry dated 2026-07-06 |
| `server/lib/foster_placements.dart` | +151 lines (new) | **No** — present on `main` since #64 | Diff vs `main`: whitespace only (~1 line) |
| `server/lib/notification_helper.dart` | +37 lines (new) | **No** — on `main` | Identical |
| `server/lib/org_people.dart` | +408 lines (new) | **No** — on `main` | Diff vs `main`: formatting only |
| `server/lib/org_roles.dart` | +55 lines (new) | **No** — on `main` | Identical |
| `server/lib/organizations/foster_parents_routes.dart` | +300 lines (new) | **No** — on `main` (330 lines) | `main` is **newer** (includes `foster_address` field parity); branch diff is formatting |
| `server/lib/organizations/members_routes.dart` | +160 lines (people + role routes) | **No** — on `main` (285 lines) | Same routes; indentation/formatting only |
| `server/lib/organizations/org_shared.dart` | Role guard alignment | **No** — on `main` | No functional diff |
| `server/lib/organizations/organization_routes.dart` | Registers foster + placements | **No** — on `main` | Identical wiring |
| `server/lib/organizations/placements_routes.dart` | +567 lines **monolith** | **Obsolete shape** | `main` has 12-line aggregator + split under `placements/` (Sprint 5.4 #104) |
| `server/lib/organizations/README.md` | Documents full parity | **No** — on `main` | Identical intent |
| `server/routes/organizations/README.md` | Updates Dart parity note | **No** — on `main` | Identical |

**Branch-only file layout (removed on `main`):** none — the branch does not add files that `main` lacks. Conversely, `main` adds files the branch lacks:

- `server/lib/organizations/placements/placements_query_routes.dart`
- `server/lib/organizations/placements/placements_create_routes.dart`
- `server/lib/organizations/placements/placements_action_routes.dart`
- `server/lib/organizations/placements/placements_shared.dart`

### Node (canonical) vs Dart (Shelf) route parity on `main`

Compared `server/routes/organizations/` to `server/lib/organizations/` **as of `main`** (the relevant baseline after supersession).

| Domain | Node routes | Dart on `main` | Branch would change? |
|--------|-------------|----------------|----------------------|
| Foster parents | `GET/POST/PUT/DELETE …/foster-parents` | **Implemented** (`foster_parents_routes.dart`) | No — already merged |
| Placements lifecycle | 9 routes (list, history, start, end, adoption steps, direct-adopt) | **Implemented** (split modules) | No — branch monolith is older layout |
| People directory | `GET …/people`, detail, contact update | **Implemented** (`members_routes.dart` + `org_people.dart`) | No |
| Member roles | invite, role change, leave/remove | **Implemented** | No |
| Org pets (basic) | `GET …/pets`, `GET …/archived` | **Implemented** | No |
| Org pets (custody) | `POST …/pets`, transfer, custody-transfers, home-hidden | **Not in Dart** | Branch did not add these either |
| Org connections | `connectionsRouter.js` (Sprint 6–7 #107/#108) | **Not in Dart** | Branch predates custody sprint |
| External foster email | Node sends via `mailService` on create | **Not in Dart** (documented gap) | Same gap on branch |

**Sprint 6–8 supersession:** Org custody (#107, #108), org-operator BDD (#116), and placements/foster monolith split (#104) all post-date the branch and are **not** contained in `dart-org-foster-parity-b4c2`. The branch targeted Increment 3–6 foster/placement parity only; that scope is **done on `main`**. Remaining Dart gaps are **custody/connections** (later sprints), not foster-parent/placement stubs.

**Note on Sprint 9 integration log:** The deferred item “Dart org `501` stubs (`placements_routes.dart` etc.)” is **outdated**. Current `main` implements placements in Dart with no `501` responses in `server/lib/organizations/`. Close that deferral; track custody/connections parity separately if Dart backend remains in scope.

---

## 3. Risk if we delete the branch

| Risk | Severity | Mitigation |
|------|----------|------------|
| Lose unmerged foster/placement Dart code | **None** | Landed in PR #64; verify via `git log origin/main -- server/lib/foster_placements.dart` |
| Lose provider test split | **None** | Landed in PR #63 |
| Lose unique bugfix | **None** | `git diff origin/main origin/cursor/dart-org-foster-parity-b4c2` on the 12 files shows formatting-only deltas |
| Accidental merge of stale branch | **High** if kept | Deleting avoids regressing to 567-line monolith and missing custody routes |
| Unknown Dart parity regression | **Low** | Node Jest suite covers org foster/placements; Dart `dart analyze lib` in CI |

**Conclusion:** Deleting `cursor/dart-org-foster-parity-b4c2` carries **negligible product risk**. The main risk is **keeping** a branch that looks actionable but is strictly behind `main`.

---

## 4. Recommended next steps for integration sprint

1. **Delete** remote branch `cursor/dart-org-foster-parity-b4c2` after this audit merges (or mark archived in sprint log).
2. **Close** Sprint 9 deferral “audit-dependent Dart org 501 stubs” — foster/placements/people Dart parity is **complete** on `main`.
3. **Do not** spawn a cherry-pick agent for this branch.
4. **If Dart backend parity remains a goal**, open a **new** scoped task for post-custody gaps (not this branch):
   - `connectionsRouter.js` → new `connections_routes.dart`
   - `petsRouter.js` custody/transfer/home-hidden → extend `pets_routes.dart`
   - Document Node-only external foster email as intentional until mail service exists in Dart
5. **Update** `docs/refactoring-log.md` Sprint 9 row 9.0 to **Done** when this doc lands on the integration branch.

---

## Appendix: commands used

```bash
git fetch origin main cursor/dart-org-foster-parity-b4c2
git log --oneline origin/main..origin/cursor/dart-org-foster-parity-b4c2
git log --oneline origin/cursor/dart-org-foster-parity-b4c2..origin/main
git diff --stat origin/main...origin/cursor/dart-org-foster-parity-b4c2
git diff 037e3f6 3a0ac48 --stat
git log origin/main -- server/lib/foster_placements.dart server/lib/organizations/
```

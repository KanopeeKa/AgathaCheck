## Outcome

<!-- One sentence: what this PR achieves (cross-domain OK if same outcome) -->

## Scope

<!-- Areas touched — confirm they all serve the outcome above -->

## Snags

<!-- Fixed inline / micro-PR #___ / issue #___ — or "none" -->

## Checklist

- [ ] **One outcome** — no unrelated "and also…" changes ([policy](docs/agent-efficiency/atomic-pr-policy.md))
- [ ] **Snags** — trivial fixes applied or tracked (issue / micro-PR); no silent deferrals
- [ ] Synced with `main` (`git fetch origin main && git rebase origin/main`) — no unresolved conflicts
- [ ] `cd server && npx jest --env=node --forceExit` passes
- [ ] `cd flutter_app && flutter analyze` and `flutter test --concurrency=1 --exclude-tags=integration` pass
- [ ] Codegen run if Mockito mocks changed (`dart run build_runner build --delete-conflicting-outputs`)
- [ ] New/changed Node routes have Jest coverage
- [ ] New/changed widgets have widget tests (mirrored path)
- [ ] HTTP behaviour changes mirrored in Dart routes (if applicable)
- [ ] `docs/architecture/api-reference.md` updated if wire format changed
- [ ] No raw `err.message` / `e.toString()` in 5xx responses (`publicError()` used)
- [ ] Form fields have labels; interactive cards use semantics where appropriate
- [ ] Flutter UI touched → `/ui-check` done or N/A (note in PR if non-trivial)
- [ ] User journeys: Gherkin + Playwright with `@bdd` (or debt issue linked)
- [ ] `docs/debt/refactoring-log.md` updated if part of sprint refactor work
- [ ] `docs/debt/refactoring-debt.md` or `docs/debt/technical-debt.md` updated for deferrals

## Test plan

<!-- How you verified the change -->

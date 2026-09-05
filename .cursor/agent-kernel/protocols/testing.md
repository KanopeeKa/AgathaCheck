# Protocol: testing

**When:** Any behaviour change, bug fix, refactor with risk, new feature.

**Ambient rule:** `.cursor/rules/testing.mdc` (path-scoped on test dirs).

**Phase exits:** `docs/agent-efficiency/phase-exit-checklists.md`.

---

## 1. Identify before writing tests

| Step | Question |
|------|----------|
| Invariant | What must always be true? |
| Layer | Unit / service / integration / widget / E2E? |
| Happy path | Expected success |
| Invalid input | Rejection behaviour |
| Forbidden actor | Who must be denied? |
| Boundary | Edge values, empty, max size |
| Persistence | Survives round-trip? |
| Concurrency | Retry/idempotency if relevant |

## 2. Layer guide

| Layer | Tool | Use for |
|-------|------|---------|
| Pure logic | Jest / Dart unit | Calculations, parsers |
| Routes | Jest + supertest | HTTP contract (mock pool) |
| AuthZ/persistence | Real DB integration | IDOR, grants — **target for Pet Care** |
| Flutter data | `flutter test` | Repos, models |
| Flutter UI | Widget tests | Extracted widgets, critical screens |
| Journeys | Playwright + BDD | High-value cross-system flows |

## 3. Anti-patterns

- Mocking the component whose behaviour is under test
- Arbitrary `sleep` in tests
- Weakening assertions to go green
- Tests that only assert "no throw"

## 4. Bug fixes

- **Regression test required** before or with fix
- Security bug → negative regression (`security.md`)

## 5. Verification map

```bash
./scripts/pre-push-changed.sh
# merge attempt:
./scripts/pre-push.sh
```

E2E remedial: `./scripts/pre-push-changed.sh --e2e-shards <n>`.

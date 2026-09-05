# Protocol: flutter-mobile

**When:** Flutter UI, state, networking, client errors, session handling, multi-platform behaviour.

**Reference:** `docs/architecture/index.md`, `.agents/memory/auth-token-refresh.md`.

---

## 1. Inspect

- Repository/datasource boundary (not raw HTTP in widgets)
- Platform: web, iOS, Android — no browser-only assumptions in domain layer
- API backwards compatibility for installed clients

## 2. Invariants

- Presentation should not own: raw URL construction, storage technology, low-level HTTP (use existing repos)
- Secure credential storage per platform
- Network timeouts and failure handling surfaced to user
- Offline vs online distinctions where product requires
- Session expiry handled safely
- Retry safety (no duplicate side effects)
- Background/resume behaviour for in-flight requests
- Pagination / payload size for large lists

## 3. UI rule

> UI visibility is not authorization. Backend must enforce capabilities.

## 4. Tests

- Widget/state tests for client behaviour changes
- Repository tests for mapping/parsing
- E2E only for high-value journeys (`e2e.md`, `release-verification.md`)

## 5. Verification

```bash
cd flutter_app && flutter analyze --no-fatal-warnings --no-fatal-infos
cd flutter_app && flutter test --concurrency=1 --exclude-tags=integration
```

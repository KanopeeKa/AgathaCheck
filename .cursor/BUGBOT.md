# Bugbot rules — Agatha Track

Project-specific review context for Cursor Bugbot on pull requests. See `docs/agent-efficiency/pr-review-cost-efficiency.md` for dashboard settings.

## Must flag (blocking)

- **Security:** Raw exception text in prod 5xx responses (`err.message`, `e.toString()`, `$e`) — use `publicError()` / redaction patterns in `docs/agent-efficiency/` and `.agents/memory/error-leak-redaction-patterns.md`.
- **Auth / org scope:** Mutations that accept `organization_id` in the body without verifying membership in `organization_users`.
- **Calendar dates:** User-facing dates must be `YYYY-MM-DD` on the wire (`docs/calendar-dates.md`).
- **Migrations:** Changes under `db/migrations/` or `server/scripts/migrate.js` paths without explicit human approval for agent PRs (`agent-pr-safety-gate`).
- **Dual backend:** New or changed API behavior only in `server/` (Node.js) — no Dart backend in `server/`.
- **File size:** New hand-written `.js` / `.dart` files approaching or exceeding **500 lines** (`scripts/check_file_size.js`).

## Should flag (non-blocking unless severe)

- Missing tests for backend route or security-sensitive changes in touched domains.
- Drive-by refactors unrelated to the PR’s stated outcome (atomic PR policy).
- Flutter UI changes without considering accessibility (`accessibility.mdc`) or calm-care copy (`docs/design/copy-tone.md`).
- E2E locator/assertion brittleness — prefer stable roles/labels over implementation details.

## Prefer not to flag

- Pre-existing issues in untouched files (snag ladder: debt issue or separate PR).
- Style-only nits that contradict established patterns in the same file.
- Suggestions to add features outside the PR’s single verifiable outcome.

## Repo conventions

- Atomic PRs: one verifiable outcome per PR (`docs/agent-efficiency/atomic-pr-policy.md`).
- BDD gate: maintain mapped scenario coverage (`node e2e/scripts/check_bdd_coverage.js`).
- Local-first sync: server is source of truth; no re-push of local-only rows on read (`.agents/memory/local-first-sync.md`).

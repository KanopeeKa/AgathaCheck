# Agent memory index

Institutional knowledge for cloud agents. Domain workflows live in **Skills** (`.cursor/skills/`).

## Skills (prefer these for workflows)

| Skill | Replaces ad-hoc prompts for |
|-------|----------------------------|
| `/split-flutter-screen` | Screen extraction |
| `/add-bdd-playwright-scenario` | Gherkin → Playwright |
| `/single-backend-route-change` | Node API route changes |
| `/spawn-sprint-agents` | Parallel sprint coordination |
| `/security-error-audit` | 5xx redaction grep |
| `/pre-push-verify` | Which tests to run |

## Domain semantics (memories)

- [Auth token refresh + retry](auth-token-refresh.md) — authed API calls must use authHttpClientProvider (refresh+retry on 401); AuthService stays unwrapped; AppLocalizations.of(ctx) is nullable.
- [Local-first cache & remote sync](local-first-sync.md) — server is source of truth; never re-push local-only rows on read (resurrects deleted data); create rolls back + rethrows on remote failure.
- [Flutter web password-manager autofill](flutter-web-password-managers.md) — CanvasKit paints fields on canvas so extensions (Proton Pass) can't autofill; fix is a native HTML form in index.html bridged to Dart.
- [Tool-output token scrambling](tool-output-token-scrambling.md) — grep/bash can mangle source tokens in file content (e.g. weight→ln); read tool shows truth, edits use real tokens.
- [Health entry completion semantics](health-entry-completion.md) — UI derives overdue/completed from next_due_date only (no status field); mark-taken must advance/sentinel next_due_date in the backend.
- [JWT secret dev/test fallback](jwt-secret-dev-fallback.md) — keep the prod-gated 'default_secret' fallback; CI/Jest sign tokens with it and workflows set no secret.
- [Error-leak redaction patterns](error-leak-redaction-patterns.md) — grep err.message + e.toString() + $e + details on the backend; one pattern misses sites. Also: `/security-error-audit` skill.
- [Localization & enum .label](localization-enum-labels.md) — "fully localize" must also map enum `.label` getters (dropdowns/displays) to ARB keys, not just inline literals.
- [Replit agent operating policy](replit-agent-operating-policy.md) — READ FIRST every task: repo .cursor rules are binding; PR flow to main; sensitive paths need confirmation.
- [Flutter pub cache Matrix4 quirk](flutter-pubcache-matrix4.md) — `flutter test` failing inside the SDK's painting lib (Matrix4/Vector4 undefined) = stale cache; run `flutter pub get` first.
- [Body-supplied organization_id validation](body-supplied-org-id-validation.md) — pet create/update must verify caller is in organization_users before persisting org_id; backend enforces 403 on non-member.
- [UAT live E2E & deploy triage](uat-live-e2e-triage.md) — migrations/ownership, auth bypass, **`E2E=1` required on UAT Node**, API seed-before-login, 500/401/429 symptom map; full runbook `docs/e2e/uat-live-operations-runbook.md`.

## Quick references

- Domain map: `docs/architecture/index.md`
- Efficiency plan: `docs/agent-efficiency-plan.md`
- Pre-push: `./scripts/pre-push-changed.sh` (iteration) · `./scripts/pre-push.sh` (merge)
- PR reviews: fix valid Copilot/human feedback **in the same PR** before merge — no follow-up debt for locator/assertion hardening.

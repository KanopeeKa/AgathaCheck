# Flutter web build artifact contract

Single source of truth for release web builds across CI, UAT, and PROD.
Implementation: `scripts/ci/build-flutter-web.sh` (called directly or via
`.github/workflows/_reusable-build-web.yml`).

## Codegen parity policy

| Path | `RUN_CODEGEN` | `RUN_CLEAN` | Notes |
|------|---------------|-------------|-------|
| **CI** (`_reusable-test.yml` flutter job) | `false` at build time | `false` | `build_runner` runs earlier in the same job before analyze/tests |
| **UAT / PROD deploy** | `true` | `true`* | Standalone deploy job; full codegen before build |
| **Localhost E2E** (`_reusable-e2e-local.yml`) | `false` | `false` | Minimal path; follow-up debt if generated code required |

\* `RUN_CLEAN` on deploy may change in Phase 4 experiment.

## Build flags (defined once in `build-flutter-web.sh`)

- `flutter build web --release --no-tree-shake-icons`
- `--dart-define=POSTHOG_HOST=https://eu.i.posthog.com`
- `--dart-define=POSTHOG_API_KEY=…` when secret present
- PostHog HTML injection via `flutter_app/scripts/inject_posthog_web.sh`

## Artifact layout

Uploaded path: `flutter_app/build/web/`

| File | Purpose |
|------|---------|
| `main.dart.js` (or `.mjs`) | Compiled app |
| `index.html` | Includes `POSTHOG_WEB_BEGIN` when key set |
| `build-manifest.json` | Provenance metadata (no secrets) |

## `build-manifest.json` fields

| Field | Example |
|-------|---------|
| `git_sha` | Full commit SHA |
| `git_ref` | `refs/heads/main` |
| `repo` | `owner/repo` |
| `flutter_version` | `3.32.0` |
| `pubspec_lock_sha256` | SHA-256 of `pubspec.lock` |
| `posthog_injected` | `true` / `false` |
| `dart_defines.POSTHOG_HOST` | `https://eu.i.posthog.com` |
| `run_clean` | boolean |
| `run_codegen` | boolean |
| `source_workflow` | Calling workflow name |
| `source_run_id` | GitHub Actions run id |
| `artifact_name` | `web-build-<full-git-sha>` |
| `built_at` | ISO-8601 UTC |

**Never** include `POSTHOG_API_KEY` or other secrets in the manifest.

## Verification

`scripts/ci/verify-web-artifact.sh` runs after every manifest write:

- Compiled output exists
- PostHog markers present when key was set
- `build-manifest.json` exists

## UAT → PROD promotion (Phase 3)

UAT builds upload a versioned artifact: **`web-build-<full-commit-sha>`** (30-day
retention). PROD downloads that artifact instead of rebuilding when possible.

| Script | Role |
|--------|------|
| `scripts/ci/download-uat-artifact.sh` | Resolve UAT run, download artifact, call provenance check |
| `scripts/ci/materialize-web-artifact.sh` | Flatten download dir to `flutter_app/build/web/` (handles nested layouts) |
| `scripts/ci/assert-artifact-provenance.sh` | Manifest `git_sha`, `source_workflow`, `artifact_name`; optional `Prod ready` |

**Promotion path (default):**

1. UAT `build-web` job uploads `web-build-<sha>` via `_reusable-build-web.yml`.
2. UAT gates pass → `Prod ready` succeeds.
3. PROD `deploy` calls `download-uat-artifact.sh` for the same SHA.
4. Manifest provenance must match; UAT run `Prod ready` must be `success`.

**Fail closed:** Release publishes require a promoted artifact. `workflow_dispatch`
may pass `uat_run_id` to pin the source run. `rebuild_if_missing: true` is an
audited fallback only (emits `::warning::NON-PROMOTED REBUILD PATH USED`).

Gate details: [ci-cd-gates.md](./ci-cd-gates.md).

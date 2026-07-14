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
| `artifact_name` | e.g. `web-build` |
| `built_at` | ISO-8601 UTC |

**Never** include `POSTHOG_API_KEY` or other secrets in the manifest.

## Verification

`scripts/ci/verify-web-artifact.sh` runs after every manifest write:

- Compiled output exists
- PostHog markers present when key was set
- `build-manifest.json` exists

## Phase 3 promotion (preview)

PROD will download a UAT-produced artifact when manifest `git_sha` matches the
requested ref and the source UAT run passed `prod-ready`. See `docs/ci-cd-gates.md`.

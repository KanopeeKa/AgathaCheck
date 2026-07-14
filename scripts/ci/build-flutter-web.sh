#!/usr/bin/env bash
# Shared Flutter web release build (single implementation path for CI/UAT/PROD).
#
# Environment:
#   POSTHOG_API_KEY   — optional; when set, injects snippet and dart-define
#   RUN_CLEAN         — true|false (default false)
#   RUN_CODEGEN       — true|false (default true)
#   WRITE_MANIFEST    — true|false (default true)
#   VERIFY_ARTIFACT   — true|false (default true)
#   ARTIFACT_NAME     — manifest field (default web-build)
#   SOURCE_WORKFLOW   — manifest field (default GITHUB_WORKFLOW)
#   FLUTTER_VERSION   — manifest field (default 3.32.0)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

RUN_CLEAN="${RUN_CLEAN:-false}"
RUN_CODEGEN="${RUN_CODEGEN:-true}"
WRITE_MANIFEST="${WRITE_MANIFEST:-true}"
VERIFY_ARTIFACT="${VERIFY_ARTIFACT:-true}"
FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.0}"
ARTIFACT_NAME="${ARTIFACT_NAME:-web-build}"
SOURCE_WORKFLOW="${SOURCE_WORKFLOW:-${GITHUB_WORKFLOW:-local}}"
POSTHOG_HOST="${POSTHOG_HOST:-https://eu.i.posthog.com}"

echo "build-flutter-web: clean=${RUN_CLEAN} codegen=${RUN_CODEGEN} artifact=${ARTIFACT_NAME}"

if [[ "$RUN_CLEAN" == "true" ]]; then
  (cd flutter_app && flutter clean)
fi

(cd flutter_app && flutter pub get)

if [[ "$RUN_CODEGEN" == "true" ]]; then
  if grep -q "build_runner" flutter_app/pubspec.yaml; then
    (cd flutter_app && dart run build_runner build --delete-conflicting-outputs)
  else
    echo "build_runner not configured; skipping codegen."
  fi
fi

(
  cd flutter_app
  export POSTHOG_API_KEY="${POSTHOG_API_KEY:-}"
  bash scripts/inject_posthog_web.sh
)

(
  cd flutter_app
  export POSTHOG_API_KEY="${POSTHOG_API_KEY:-}"
  flutter build web --release --no-tree-shake-icons \
    --dart-define=POSTHOG_API_KEY="${POSTHOG_API_KEY:-}" \
    --dart-define=POSTHOG_HOST="${POSTHOG_HOST}"
)

if [[ "$WRITE_MANIFEST" == "true" ]]; then
  export FLUTTER_VERSION ARTIFACT_NAME SOURCE_WORKFLOW
  export RUN_CLEAN RUN_CODEGEN
  export POSTHOG_INJECTED="$([[ -n "${POSTHOG_API_KEY:-}" ]] && echo true || echo false)"
  export LOCKFILE_SHA256="$(sha256sum flutter_app/pubspec.lock | awk '{print $1}')"
  bash scripts/ci/write-build-manifest.sh
fi

if [[ "$VERIFY_ARTIFACT" == "true" ]]; then
  bash scripts/ci/verify-web-artifact.sh
fi

echo "build-flutter-web: complete"

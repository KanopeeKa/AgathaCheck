#!/usr/bin/env bash
# Changed-files pre-push — default during agent iteration.
# Runs a minimal subset based on git diff vs merge-base (origin/main).
#
# Usage:
#   ./scripts/pre-push-changed.sh           # vs origin/main
#   ./scripts/pre-push-changed.sh --full    # delegate to pre-push.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ "${1:-}" == "--full" ]]; then
  exec "$ROOT/scripts/pre-push.sh"
fi

git fetch origin main --quiet 2>/dev/null || true
MERGE_BASE="$(git merge-base HEAD origin/main 2>/dev/null || echo HEAD)"
CHANGED="$(git diff --name-only "$MERGE_BASE" HEAD 2>/dev/null; git diff --name-only; git diff --cached --name-only)" 
CHANGED="$(echo "$CHANGED" | sort -u | grep -v '^$' || true)"

if [[ -z "$CHANGED" ]]; then
  echo "No changed files detected — running governance gates only"
  node scripts/check_file_size.js
  node e2e/scripts/check_bdd_coverage.js
  exit 0
fi

echo "Changed files ($(echo "$CHANGED" | wc -l)):"
echo "$CHANGED" | sed 's/^/  /'

needs_governance=false
needs_server=false
needs_flutter=false
needs_dart_analyze=false
needs_codegen=false

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    scripts/*|.github/*|docs/agent-efficiency*|docs/architecture/index.md)
      needs_governance=true
      ;;
    server/routes/*|server/test/*|server/config/*|server/lib/*)
      needs_server=true
      needs_dart_analyze=true
      ;;
    flutter_app/lib/*|flutter_app/test/*)
      needs_flutter=true
      ;;
    flutter_app/pubspec.*|flutter_app/build.yaml|**/*.mocks.dart|**/*_test.dart)
      needs_codegen=true
      needs_flutter=true
      ;;
    e2e/*)
      needs_governance=true
      ;;
    .cursor/*)
      # config only — no product tests
      ;;
    *)
      needs_governance=true
      ;;
  esac
done <<< "$CHANGED"

run_governance() {
  echo "==> Governance"
  node scripts/check_file_size.js
  node scripts/validate_execute_plan_snapshot.js .agents/plans/_example.snapshot.json
  node scripts/validate_execute_plan_snapshot.js --drift-test
  node --test scripts/execute_plan_runtime.test.js
  node e2e/scripts/check_bdd_coverage.js
  bash scripts/ci/check-uat-ssh-action-pin.sh
  bash scripts/ci/shellcheck-uat-deploy-scripts.sh
}

run_server() {
  echo "==> Server tests"
  (
    cd server
    # Run domain tests matching changed paths when possible
    local jest_args=()
    while IFS= read -r f; do
      case "$f" in
        server/test/*.test.js) jest_args+=("$(basename "$f")") ;;
        server/test/*/*) jest_args+=("${f#server/}") ;;
        server/routes/pets/*) jest_args+=("test/pets/") ;;
        server/routes/auth/*) jest_args+=("test/auth/") ;;
        server/routes/organizations/*) jest_args+=("test/organizations/") ;;
        server/routes/healthEntries/*) jest_args+=("healthEntries.test.js") ;;
      esac
    done <<< "$CHANGED"
    if [[ ${#jest_args[@]} -gt 0 ]]; then
      # dedupe
      local unique
      unique="$(printf '%s\n' "${jest_args[@]}" | sort -u | tr '\n' ' ')"
      echo "    jest $unique"
      npx jest --env=node --forceExit $unique
    else
      npx jest --env=node --forceExit
    fi
  )
}

run_flutter() {
  echo "==> Flutter"
  (
    cd flutter_app
    if $needs_codegen; then
      dart run build_runner build --delete-conflicting-outputs
    fi
    flutter analyze --no-fatal-warnings --no-fatal-infos
    # Target feature test dirs when possible
    local test_dirs=()
    while IFS= read -r f; do
      if [[ "$f" =~ flutter_app/lib/features/([^/]+)/ ]]; then
        feat="${BASH_REMATCH[1]}"
        if [[ -d "test/features/$feat" ]]; then
          test_dirs+=("test/features/$feat")
        fi
      fi
      if [[ "$f" =~ flutter_app/test/features/([^/]+)/ ]]; then
        test_dirs+=("test/features/${BASH_REMATCH[1]}")
      fi
    done <<< "$CHANGED"
    if [[ ${#test_dirs[@]} -gt 0 ]]; then
      unique="$(printf '%s\n' "${test_dirs[@]}" | sort -u)"
      echo "    flutter test $unique"
      flutter test --concurrency=1 $unique
    else
      flutter test --concurrency=1 --exclude-tags=integration
    fi
  )
}

run_dart_analyze() {
  echo "==> Dart server analyze"
  (cd server && dart pub get && dart analyze lib)
}

$needs_governance && run_governance
$needs_server && run_server
$needs_flutter && run_flutter
$needs_dart_analyze && run_dart_analyze

echo "✓ Changed-files pre-push passed"
echo "  Run ./scripts/pre-push.sh before merging to main"

#!/usr/bin/env bash
# Run Flutter tests for one CI shard with coverage output (coverage/lcov.<shard>.info).
# Shard → test files come from flutter_app/test/ci_shards.json. Files run in batches
# (one `flutter test` per batch, --concurrency N) under a hang watchdog; failing or
# crashed batches are re-run file-by-file (flutter_tester segfault isolation).
# See scripts/ci/flutter-shard-runner.mjs for knobs (FLUTTER_TEST_CONCURRENCY, …).
set -euo pipefail

cd "$(dirname "$0")/.."
exec node ../scripts/ci/flutter-shard-runner.mjs "$@"

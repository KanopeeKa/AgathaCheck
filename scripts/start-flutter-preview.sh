#!/usr/bin/env bash

# Builds the current Flutter source for the local Replit preview, then starts
# the existing Node server that serves flutter_app/build/web.
set -euo pipefail

readonly WEB_BUILD_ENTRYPOINT="flutter_app/build/web/index.html"

# shellcheck source=scripts/flutter-sdk.sh
source "$(dirname "${BASH_SOURCE[0]}")/flutter-sdk.sh"
agatha_flutter_use
agatha_flutter_verify

readonly LOCKFILE="flutter_app/pubspec.lock"
needs_web_build() {
  if [[ ! -f "${WEB_BUILD_ENTRYPOINT}" ]]; then
    return 0
  fi

  local changed_source
  changed_source="$(
    find flutter_app/lib flutter_app/web \
      flutter_app/assets \
      flutter_app/pubspec.yaml flutter_app/pubspec.lock \
      -type f -newer "${WEB_BUILD_ENTRYPOINT}" -print -quit
  )"
  [[ -n "${changed_source}" ]]
}

if needs_web_build; then
  if ! git diff --quiet -- "${LOCKFILE}" ||
    ! git diff --cached --quiet -- "${LOCKFILE}"; then
    echo "Refusing to overwrite uncommitted changes in ${LOCKFILE}." >&2
    exit 1
  fi

  lockfile_backup="$(mktemp)"
  cp "${LOCKFILE}" "${lockfile_backup}"
  restore_lockfile() {
    cp "${lockfile_backup}" "${LOCKFILE}"
    touch -r "${lockfile_backup}" "${LOCKFILE}"
    rm -f "${lockfile_backup}"
  }
  trap restore_lockfile EXIT INT TERM
  build_status=0
  (
    cd flutter_app
    flutter pub get
    flutter build web --release --no-tree-shake-icons
  ) || build_status=$?
  restore_lockfile
  trap - EXIT INT TERM

  if [[ "${build_status}" -ne 0 ]]; then
    exit "${build_status}"
  fi
else
  echo "Flutter source unchanged; reusing the existing web bundle."
fi

cd server
npm ci
exec env PORT=5000 node bin/start.js
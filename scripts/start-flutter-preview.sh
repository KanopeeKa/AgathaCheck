#!/usr/bin/env bash

# Builds the current Flutter source for the local Replit preview, then starts
# the existing Node server that serves flutter_app/build/web.
set -euo pipefail

readonly FLUTTER_VERSION="3.44.0"
readonly FLUTTER_ARCHIVE="flutter_linux_3.44.0-stable.tar.xz"
readonly FLUTTER_ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"
readonly FLUTTER_ARCHIVE_SHA256="e1ec95e6c550458a34de93580cb85dac24da0e9bedb9bb42811f050ac5a0c7d5"
readonly TOOL_CACHE="${XDG_CACHE_HOME:-"${HOME}/.cache"}/agatha-track"
readonly FLUTTER_SDK="${TOOL_CACHE}/flutter-${FLUTTER_VERSION}"
readonly WEB_BUILD_ENTRYPOINT="flutter_app/build/web/index.html"

install_flutter() {
  if [[ -x "${FLUTTER_SDK}/bin/flutter" ]]; then
    return
  fi

  mkdir -p "${TOOL_CACHE}"
  local install_dir
  install_dir="$(mktemp -d "${TOOL_CACHE}/flutter-install.XXXXXX")"
  trap 'rm -rf "${install_dir}"' RETURN

  local archive_path="${install_dir}/${FLUTTER_ARCHIVE}"
  echo "Downloading Flutter ${FLUTTER_VERSION} for the local preview..."
  curl --fail --location --retry 3 --show-error \
    "${FLUTTER_ARCHIVE_URL}" \
    --output "${archive_path}"
  echo "${FLUTTER_ARCHIVE_SHA256}  ${archive_path}" | sha256sum --check --status

  tar --extract --xz --file "${archive_path}" --directory "${install_dir}"
  test -x "${install_dir}/flutter/bin/flutter"
  rm -rf "${FLUTTER_SDK}"
  mv "${install_dir}/flutter" "${FLUTTER_SDK}"
}

install_flutter
export PATH="${FLUTTER_SDK}/bin:${PATH}"

flutter --version

readonly LOCKFILE="flutter_app/pubspec.lock"
needs_web_build() {
  if [[ ! -f "${WEB_BUILD_ENTRYPOINT}" ]]; then
    return 0
  fi

  local changed_source
  changed_source="$(
    find flutter_app/lib flutter_app/web \
      flutter_app/pubspec.yaml flutter_app/pubspec.lock \
      -type f -newer "${WEB_BUILD_ENTRYPOINT}" -print -quit
  )"
  [[ -n "${changed_source}" ]]
}

if needs_web_build; then
  if ! git diff --quiet -- "${LOCKFILE}"; then
    echo "Refusing to overwrite uncommitted changes in ${LOCKFILE}." >&2
    exit 1
  fi

  lockfile_backup="$(mktemp)"
  cp "${LOCKFILE}" "${lockfile_backup}"
  build_status=0
  (
    cd flutter_app
    flutter pub get
    flutter build web --release --no-tree-shake-icons
  ) || build_status=$?
  cp "${lockfile_backup}" "${LOCKFILE}"
  touch -r "${lockfile_backup}" "${LOCKFILE}"
  rm -f "${lockfile_backup}"

  if [[ "${build_status}" -ne 0 ]]; then
    exit "${build_status}"
  fi
else
  echo "Flutter source unchanged; reusing the existing web bundle."
fi

cd server
npm ci
exec env PORT=5000 node bin/start.js
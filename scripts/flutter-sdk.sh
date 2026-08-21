#!/usr/bin/env bash
# Provision the repository's pinned Flutter SDK for local validation.
#
# This file is intended to be sourced. It prepends the verified SDK to PATH
# without changing the caller's working directory or shell options.

readonly AGATHA_FLUTTER_VERSION="3.44.0"
readonly AGATHA_FLUTTER_ARCHIVE="flutter_linux_${AGATHA_FLUTTER_VERSION}-stable.tar.xz"
readonly AGATHA_FLUTTER_ARCHIVE_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${AGATHA_FLUTTER_ARCHIVE}"
readonly AGATHA_FLUTTER_ARCHIVE_SHA256="e1ec95e6c550458a34de93580cb85dac24da0e9bedb9bb42811f050ac5a0c7d5"
readonly AGATHA_FLUTTER_CACHE="${XDG_CACHE_HOME:-"${HOME}/.cache"}/agatha-track"
readonly AGATHA_FLUTTER_SDK="${AGATHA_FLUTTER_CACHE}/flutter-${AGATHA_FLUTTER_VERSION}"

agatha_flutter_install() {
  if [[ -x "${AGATHA_FLUTTER_SDK}/bin/flutter" ]]; then
    return
  fi

  mkdir -p "${AGATHA_FLUTTER_CACHE}"
  local install_dir
  install_dir="$(mktemp -d "${AGATHA_FLUTTER_CACHE}/flutter-install.XXXXXX")"
  local archive_path="${install_dir}/${AGATHA_FLUTTER_ARCHIVE}"
  trap 'rm -rf "${install_dir}"' RETURN

  echo "Downloading Flutter ${AGATHA_FLUTTER_VERSION}..."
  curl --fail --location --retry 3 --show-error \
    "${AGATHA_FLUTTER_ARCHIVE_URL}" --output "${archive_path}"
  echo "${AGATHA_FLUTTER_ARCHIVE_SHA256}  ${archive_path}" |
    sha256sum --check --status

  tar --extract --xz --file "${archive_path}" --directory "${install_dir}"
  test -x "${install_dir}/flutter/bin/flutter"
  rm -rf "${AGATHA_FLUTTER_SDK}"
  mv "${install_dir}/flutter" "${AGATHA_FLUTTER_SDK}"
}

agatha_flutter_use() {
  agatha_flutter_install
  export PATH="${AGATHA_FLUTTER_SDK}/bin:${PATH}"
}

agatha_flutter_verify() {
  local dart_version
  local flutter_version
  dart_version="$(dart --version 2>&1)"
  flutter_version="$(flutter --version 2>&1 | head -n 1)"
  echo "${flutter_version}"
  echo "${dart_version}"

  if ! dart --version 2>&1 | grep -Eq 'Dart SDK version: 3\.(1[2-9]|[2-9][0-9])(\.| )'; then
    echo "Expected Dart 3.12 or newer; found: ${dart_version}" >&2
    return 1
  fi
  if [[ "${flutter_version}" != "Flutter ${AGATHA_FLUTTER_VERSION} "* ]]; then
    echo "Expected Flutter ${AGATHA_FLUTTER_VERSION}; found: ${flutter_version}" >&2
    return 1
  fi
}
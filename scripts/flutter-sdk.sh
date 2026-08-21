#!/usr/bin/env bash
# Provision the repository's pinned Flutter SDK for local validation.
#
# This file is intended to be sourced. It prepends the verified SDK to PATH
# without changing the caller's working directory or shell options.

readonly AGATHA_FLUTTER_VERSION="3.44.0"
readonly AGATHA_FLUTTER_CACHE="${XDG_CACHE_HOME:-"${HOME}/.cache"}/agatha-track"

agatha_flutter_install() {
  local platform
  local archive
  local archive_path
  local archive_sha256
  local archive_type
  local sdk_path

  case "$(uname -s)" in
    Linux*)
      platform="linux"
      archive="flutter_linux_${AGATHA_FLUTTER_VERSION}-stable.tar.xz"
      archive_sha256="e1ec95e6c550458a34de93580cb85dac24da0e9bedb9bb42811f050ac5a0c7d5"
      archive_type="tar.xz"
      ;;
    Darwin*)
      platform="macos"
      archive="flutter_macos_${AGATHA_FLUTTER_VERSION}-stable.zip"
      archive_sha256=""
      archive_type="zip"
      ;;
    MINGW*|MSYS*|CYGWIN*)
      platform="windows"
      archive="flutter_windows_${AGATHA_FLUTTER_VERSION}-stable.zip"
      archive_sha256=""
      archive_type="zip"
      ;;
    *)
      echo "Unsupported host platform: $(uname -s)" >&2
      return 1
      ;;
  esac

  sdk_path="${AGATHA_FLUTTER_CACHE}/flutter-${AGATHA_FLUTTER_VERSION}-${platform}"
  if [[ -x "${sdk_path}/bin/flutter" ]]; then
    return
  fi

  mkdir -p "${AGATHA_FLUTTER_CACHE}"
  local install_dir
  install_dir="$(mktemp -d "${AGATHA_FLUTTER_CACHE}/flutter-install.XXXXXX")"
  archive_path="${install_dir}/${archive}"

  echo "Downloading Flutter ${AGATHA_FLUTTER_VERSION}..."
  curl --fail --location --retry 3 --show-error \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/${platform}/${archive}" \
    --output "${archive_path}"
  if [[ -n "${archive_sha256}" ]]; then
    echo "${archive_sha256}  ${archive_path}" |
      sha256sum --check --status
  fi

  if [[ "${archive_type}" == "tar.xz" ]]; then
    tar --extract --xz --file "${archive_path}" --directory "${install_dir}"
  else
    unzip -q "${archive_path}" -d "${install_dir}"
  fi
  test -x "${install_dir}/flutter/bin/flutter"
  rm -rf "${sdk_path}"
  mv "${install_dir}/flutter" "${sdk_path}"
  rm -rf "${install_dir}"
}

agatha_flutter_use() {
  agatha_flutter_install
  local platform
  case "$(uname -s)" in
    Linux*) platform="linux" ;;
    Darwin*) platform="macos" ;;
    MINGW*|MSYS*|CYGWIN*) platform="windows" ;;
    *) echo "Unsupported host platform: $(uname -s)" >&2; return 1 ;;
  esac
  export PATH="${AGATHA_FLUTTER_CACHE}/flutter-${AGATHA_FLUTTER_VERSION}-${platform}/bin:${PATH}"
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
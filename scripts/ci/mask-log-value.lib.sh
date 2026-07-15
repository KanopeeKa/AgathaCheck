# Mask host/user values in CI step logs (summary fields may still show full hostname).
# shellcheck shell=bash

ci_mask_value() {
  local v="${1:-}"
  if [[ -z "$v" ]]; then
    echo "***"
    return
  fi
  local len=${#v}
  if ((len <= 4)); then
    echo "***"
    return
  fi
  echo "${v:0:2}***${v: -2}"
}

ci_mask_host() {
  ci_mask_value "$1"
}

ci_mask_user() {
  ci_mask_value "$1"
}

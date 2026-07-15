# Shared helpers for assert-node-modules-symlink.sh and uat-ssh-backend-deploy.sh (sourced, not executed).
# shellcheck shell=bash

uat_nm_remediation() {
  cat <<'EOF'
Manual recovery (cPanel):
  1. File Manager → uat.agathatrack.com/backend → delete node_modules if it is a real folder (not a symlink)
  2. Setup Node.js App → application root uat.agathatrack.com/backend → Run NPM Install
  3. Restart the Node.js application
  4. Verify: ls -la ~/uat.agathatrack.com/backend/node_modules  (must show -> .../nodevenv/.../lib/node_modules)
EOF
}

uat_nm_write_state() {
  local kind="$1"
  local target="${2:-}"
  local ht_ok="${3:-unknown}"
  local phase="${4:-unknown}"
  local appdir="${UAT_APP_DIR:-$HOME/uat.agathatrack.com/backend}"
  local state_file="${UAT_DEPLOY_STATE_FILE:-$HOME/.uat-deploy-state.env}"
  local hostname node_major
  hostname="$(hostname -f 2>/dev/null || hostname 2>/dev/null || echo unknown)"
  node_major="unknown"
  if command -v node >/dev/null 2>&1; then
    node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo unknown)"
  fi
  mkdir -p "$(dirname "$state_file")"
  {
    echo "node_modules_kind=${kind}"
    echo "node_modules_target=${target}"
    echo "passenger_htaccess_ok=${ht_ok}"
    echo "server_hostname=${hostname}"
    echo "node_major=${node_major}"
    echo "app_root=${appdir}"
    echo "invariant_phase=${phase}"
  } >"$state_file"
}

# Sets UAT_NM_KIND and returns exit code (0, 10, 11, 12).
uat_nm_classify() {
  local appdir="${UAT_APP_DIR:-$HOME/uat.agathatrack.com/backend}"
  local nm="${appdir}/node_modules"
  local target

  if [[ ! -e "$nm" && ! -L "$nm" ]]; then
    UAT_NM_KIND="missing"
    return 10
  fi
  if [[ -L "$nm" ]]; then
    target="$(readlink -f "$nm" 2>/dev/null || true)"
    if [[ -z "$target" || ! -d "$target" ]]; then
      UAT_NM_KIND="broken_symlink"
      return 12
    fi
    if [[ "$target" != "${HOME}/nodevenv/"* ]]; then
      UAT_NM_KIND="broken_symlink"
      return 12
    fi
    UAT_NM_KIND="symlink"
    UAT_NM_TARGET="$target"
    return 0
  fi
  if [[ -d "$nm" || -f "$nm" ]]; then
    UAT_NM_KIND="real_dir"
    return 11
  fi
  UAT_NM_KIND="missing"
  return 10
}

uat_nm_fail() {
  local code="$1"
  local kind="$2"
  local phase="$3"
  local msg="$4"
  uat_nm_write_state "$kind" "" "${PASSENGER_HTACCESS_OK:-unknown}" "$phase"
  echo "::error title=UAT node_modules invariant (${phase})::${msg}" >&2
  uat_nm_remediation >&2
  return "$code"
}

# Args: phase retry_attempts retry_sleep_sec
uat_nm_assert() {
  local phase="${1:-pre}"
  local retry_attempts="${2:-1}"
  local retry_sleep_sec="${3:-10}"
  local attempt=1
  local code kind msg

  while true; do
    uat_nm_classify || code=$?
    code="${code:-0}"
    kind="${UAT_NM_KIND:-unknown}"

    if [[ "$kind" == "symlink" ]]; then
      uat_nm_write_state "$kind" "${UAT_NM_TARGET:-}" "${PASSENGER_HTACCESS_OK:-unknown}" "$phase"
      echo "OK [${phase}]: node_modules -> ${UAT_NM_TARGET} (attempt ${attempt}/${retry_attempts})"
      return 0
    fi

    case "$kind" in
      missing) msg="backend/node_modules is missing (exit 10)" ;;
      real_dir) msg="backend/node_modules is a real directory — must be a symlink to nodevenv (exit 11)" ;;
      broken_symlink) msg="backend/node_modules symlink is broken or points outside ~/nodevenv (exit 12)" ;;
      *) msg="backend/node_modules in unknown state (exit 10)"; code=10 ;;
    esac

    if [[ "$attempt" -lt "$retry_attempts" ]]; then
      echo "WARN [${phase}]: ${msg} — retry ${attempt}/${retry_attempts} in ${retry_sleep_sec}s"
      sleep "$retry_sleep_sec"
      attempt=$((attempt + 1))
      continue
    fi

    uat_nm_fail "$code" "$kind" "$phase" "$msg"
    return "$code"
  done
}

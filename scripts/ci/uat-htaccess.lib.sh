# UAT Apache .htaccess helpers (o2switch CloudLinux Passenger + SPA).
# shellcheck shell=bash
# Globals below are set for callers (uat-ssh-backend-deploy.sh / bundled remote script).
# shellcheck disable=SC2034

uat_htaccess_has_passenger() {
  local f="$1"
  [[ -f "$f" ]] && grep -qE \
    'Passenger(AppRoot|Enabled|BaseURI|Nodejs|AppType|StartupFile)|CLOUDLINUX PASSENGER CONFIGURATION' \
    "$f" 2>/dev/null
}

uat_htaccess_has_spa_backend_exclusion() {
  local f="$1"
  [[ -f "$f" ]] && grep -qE 'RewriteCond[[:space:]]+%\{REQUEST_URI\}[[:space:]]+!\^/backend' "$f" 2>/dev/null
}

# Extract CloudLinux Passenger + env blocks from an existing .htaccess.
uat_extract_cloudlinux_blocks() {
  local f="$1"
  [[ -f "$f" ]] || return 0
  awk '
    /CLOUDLINUX PASSENGER CONFIGURATION BEGIN/ { show=1 }
    show { print }
    /CLOUDLINUX ENV VARS CONFIGURATION END/ { show=0 }
  ' "$f" 2>/dev/null || true
}

# Phase 1: discover Passenger location and blocks before any root write.
uat_htaccess_discover_passenger() {
  local site_root="$1"
  local appdir="$2"
  local root="${site_root}/.htaccess"
  local backend="${appdir}/.htaccess"

  UAT_HT_PASSENGER_SOURCE=""
  UAT_HT_PRESERVED_BLOCKS=""

  if uat_htaccess_has_passenger "$root"; then
    UAT_HT_PASSENGER_SOURCE="$root"
    UAT_HT_PRESERVED_BLOCKS="$(uat_extract_cloudlinux_blocks "$root")"
  elif uat_htaccess_has_passenger "$backend"; then
    UAT_HT_PASSENGER_SOURCE="$backend"
    UAT_HT_PRESERVED_BLOCKS="$(uat_extract_cloudlinux_blocks "$backend")"
  fi
}

uat_htaccess_backup_root() {
  local site_root="$1"
  local target="${site_root}/.htaccess"
  local epoch backup

  [[ -f "$target" ]] || return 0
  epoch="$(date +%s)"
  backup="${site_root}/.htaccess.bak.${epoch}"
  cp -a "$target" "$backup"
  echo "Backed up ${target} → ${backup}"
}

# Phase 2: backup (if present), merge preserved Passenger blocks + SPA rules, write root.
uat_htaccess_apply_spa_merge() {
  local site_root="$1"
  local preserved="$2"
  local spa="${site_root}/htaccess.spa"
  local target="${site_root}/.htaccess"
  local merged

  UAT_HT_ROOT_APPLIED="false"
  UAT_HT_PASSENGER_MERGED_TO_ROOT="false"

  if [[ ! -f "$spa" ]]; then
    if [[ -f "$target" ]]; then
      echo "OK: ${target} already present (no htaccess.spa to apply)"
    else
      echo "::warning::no htaccess.spa or .htaccess at domain root — Flutter deep links may break"
    fi
    return 0
  fi

  uat_htaccess_backup_root "$site_root"

  if [[ -n "$preserved" ]]; then
    merged="$(mktemp)"
    { printf '%s\n\n' "$preserved"; cat "$spa"; } >"$merged"
    install -m 644 "$merged" "$target"
    rm -f "$merged"
    UAT_HT_PASSENGER_MERGED_TO_ROOT="true"
    echo "Installed ${target} — preserved CloudLinux Passenger/env blocks + SPA rules"
  else
    install -m 644 "$spa" "$target"
    echo "Installed ${target} from htaccess.spa (no CloudLinux Passenger blocks found to preserve)"
  fi
  UAT_HT_ROOT_APPLIED="true"
}

# Phase 3: hard-fail checks on merged root .htaccess.
# passenger_expected_in_root: Passenger was at root pre-merge or blocks were merged into root.
uat_htaccess_verify_merged_root() {
  local site_root="$1"
  local passenger_expected_in_root="$2"
  local root_applied="$3"
  local target="${site_root}/.htaccess"
  local ok=true
  local reasons=()

  if [[ "$root_applied" != "true" ]]; then
    return 0
  fi

  if ! uat_htaccess_has_spa_backend_exclusion "$target"; then
    ok=false
    reasons+=("missing SPA /backend exclusion in ${target}")
  fi

  if [[ "$passenger_expected_in_root" == "true" ]] && ! uat_htaccess_has_passenger "$target"; then
    ok=false
    reasons+=("Passenger markers missing in merged ${target}")
  fi

  if [[ "$ok" == "false" ]]; then
    echo "::error::Root .htaccess verification failed: ${reasons[*]}"
    echo "Action: cPanel → Setup Node.js App → Save (regenerates Passenger block) → Restart → redeploy"
    return 1
  fi

  echo "OK: merged root .htaccess verified (SPA /backend exclusion${passenger_expected_in_root:+, Passenger markers})"
  return 0
}

# Phase 4: Passenger may live at domain root (o2switch default) or backend/.htaccess.
uat_find_passenger_htaccess() {
  local site_root="$1"
  local appdir="$2"
  if uat_htaccess_has_passenger "${appdir}/.htaccess"; then
    printf '%s\n' "${appdir}/.htaccess"
  elif uat_htaccess_has_passenger "${site_root}/.htaccess"; then
    printf '%s\n' "${site_root}/.htaccess"
  fi
}

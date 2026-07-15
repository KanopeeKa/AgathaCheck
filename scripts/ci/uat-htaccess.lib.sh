# UAT Apache .htaccess helpers (o2switch CloudLinux Passenger + SPA).
# shellcheck shell=bash

uat_htaccess_has_passenger() {
  local f="$1"
  [[ -f "$f" ]] && grep -qE \
    'Passenger(AppRoot|Enabled|BaseURI|Nodejs|AppType|StartupFile)|CLOUDLINUX PASSENGER CONFIGURATION' \
    "$f" 2>/dev/null
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

# Install SPA rules at domain root without destroying Passenger blocks (o2switch puts them at root).
uat_install_root_htaccess() {
  local site_root="$1"
  local spa="${site_root}/htaccess.spa"
  local target="${site_root}/.htaccess"
  local preserved merged

  if [[ ! -f "$spa" ]]; then
    if [[ -f "$target" ]]; then
      echo "OK: ${target} already present (no htaccess.spa to apply)"
    else
      echo "::warning::no htaccess.spa or .htaccess at domain root — Flutter deep links may break"
    fi
    return 0
  fi

  preserved="$(uat_extract_cloudlinux_blocks "$target")"
  if [[ -z "$preserved" ]]; then
    preserved="$(uat_extract_cloudlinux_blocks "${site_root}/backend/.htaccess")"
  fi

  if [[ -n "$preserved" ]]; then
    merged="$(mktemp)"
    { printf '%s\n\n' "$preserved"; cat "$spa"; } >"$merged"
    install -m 644 "$merged" "$target"
    rm -f "$merged"
    echo "Installed ${target} — preserved CloudLinux Passenger/env blocks + SPA rules"
  else
    install -m 644 "$spa" "$target"
    echo "Installed ${target} from htaccess.spa (no CloudLinux Passenger blocks found to preserve)"
  fi
}

# Passenger may live at domain root (o2switch default) or backend/.htaccess.
uat_find_passenger_htaccess() {
  local site_root="$1"
  local appdir="$2"
  if uat_htaccess_has_passenger "${appdir}/.htaccess"; then
    printf '%s\n' "${appdir}/.htaccess"
  elif uat_htaccess_has_passenger "${site_root}/.htaccess"; then
    printf '%s\n' "${site_root}/.htaccess"
  fi
}

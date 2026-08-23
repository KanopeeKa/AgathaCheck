#!/usr/bin/env bash
# Run this script VIA SSH on the UAT server to diagnose why the Node.js app is returning 500.
#
# Usage (from a machine with authorized SSH access):
#   ssh <user>@<host> 'bash -s' < scripts/uat-diagnose.sh
#
# Or paste the entire contents into cPanel → Terminal if SSH is unavailable.
set -uo pipefail

APPDIR="$HOME/uat.agathatrack.com/backend"
NODEVENV_BASE="$HOME/nodevenv/uat.agathatrack.com/backend"

sep() { echo ""; echo "=== $* ==="; }

sep "App directory"
ls -la "$APPDIR" 2>&1 | head -20 || echo "ERROR: $APPDIR does not exist"

sep "node_modules state"
if [ -L "$APPDIR/node_modules" ]; then
  target="$(readlink -f "$APPDIR/node_modules")"
  echo "SYMLINK -> $target"
  [ -d "$target" ] && echo "Target exists (OK)" || echo "TARGET MISSING — re-run cPanel Run NPM Install"
elif [ -d "$APPDIR/node_modules" ]; then
  echo "REAL DIR (broken state — exit 11 in CI)"
  echo "Fix: rm -rf $APPDIR/node_modules && cPanel -> Setup Node.js App -> Run NPM Install"
  echo "See docs/pipelines/uat-backend-node-modules-runbook.md"
  echo "Count: $(find "$APPDIR/node_modules" -maxdepth 1 -mindepth 1 | wc -l) top-level packages"
else
  echo "MISSING (exit 10 in CI) — cPanel -> Setup Node.js App -> Run NPM Install"
fi

sep "nodevenv directory"
if [ -d "$NODEVENV_BASE" ]; then
  ls "$NODEVENV_BASE/"
else
  echo "nodevenv not found at $NODEVENV_BASE"
fi

sep ".env presence"
if [ -f "$APPDIR/.env" ]; then
  echo ".env exists"
  # Show keys (not values) to avoid leaking secrets in CI logs
  grep -E '^[A-Z_]+=.' "$APPDIR/.env" | sed 's/=.*/=<set>/' || true
else
  echo "MISSING — create $APPDIR/.env with DB and JWT_SECRET"
fi

sep "Node.js binary"
NODE="$(which node 2>/dev/null || echo "")"
if [ -z "$NODE" ]; then
  # Try nodevenv path
  for v in 22 20 18; do
    candidate="$NODEVENV_BASE/$v/bin/node"
    [ -x "$candidate" ] && NODE="$candidate" && break
  done
fi
if [ -n "$NODE" ]; then
  echo "node: $NODE"
  "$NODE" --version
else
  echo "node not found in PATH or nodevenv"
fi

sep "Syntax / startup check (dry-run)"
if [ -n "$NODE" ] && [ -f "$APPDIR/bin/start.js" ]; then
  cd "$APPDIR"
  # Check for syntax errors only — do NOT actually start the server
  "$NODE" --input-type=module --check < "$APPDIR/bin/start.js" 2>&1 && echo "Syntax OK" || echo "Syntax error in bin/start.js"
fi

sep "Passenger logs (last 30 lines)"
# o2switch Passenger logs location (adjust if different)
for logpath in \
    "$HOME/logs/uat.agathatrack.com/passenger.log" \
    "$HOME/logs/passenger.log" \
    "$HOME/.passenger/logs/passenger.log" \
    "/var/log/passenger/$(whoami).log"; do
  if [ -f "$logpath" ]; then
    echo "Log: $logpath"
    tail -30 "$logpath"
    break
  fi
done 2>/dev/null || echo "Passenger log not found — check cPanel -> Logs"

sep "cPanel error log (last 20 lines)"
for errlog in \
    "$HOME/logs/uat.agathatrack.com/error.log" \
    "$HOME/logs/error.log"; do
  if [ -f "$errlog" ]; then
    echo "Log: $errlog"
    tail -20 "$errlog"
    break
  fi
done 2>/dev/null || echo "Error log not found — check cPanel -> Error Log"

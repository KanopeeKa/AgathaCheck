#!/usr/bin/env bash
# Resolve and validate the GitHub Actions runner public IPv4 for o2switch SSH whitelist.
# Writes ipv4= to GITHUB_OUTPUT; fails on empty, non-IPv4, or injection-shaped responses.
set -euo pipefail

output="${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

raw="$(
  curl -sf --retry 3 https://api.ipify.org \
    || curl -sf --retry 3 https://ifconfig.me \
    || true
)"
ip="${raw//$'\r'/}"
ip="${ip//$'\n'/}"
ip="${ip//[[:space:]]/}"

if ! [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "::error::Could not resolve a valid IPv4 runner address (got: ${raw:-<empty>})" >&2
  exit 1
fi

IFS=. read -r o1 o2 o3 o4 <<<"$ip"
for octet in "$o1" "$o2" "$o3" "$o4"; do
  if (( octet < 0 || octet > 255 )); then
    echo "::error::Invalid IPv4 octet in runner address: ${ip}" >&2
    exit 1
  fi
done

{
  printf '%s=%s\n' ipv4 "$ip"
} >>"$output"
echo "Runner public IP: ${ip}"

#!/usr/bin/env bash
# Watch the GNOME wallpaper and color-scheme keys and re-derive the tinty
# scheme on each change. Event-driven via `gsettings monitor` (blocks on the
# dconf D-Bus signal, no polling). Started by the wallpaper-tinty systemd user
# service. The worker (wallpaper-tinty.py) respects auto/manual mode itself.
set -Eeuo pipefail
shopt -s inherit_errexit

readonly WORKER="${HOME}/.local/bin/wallpaper-tinty.py"
# Monitor both keys: a wallpaper swap AND a dark/light toggle should re-derive.
readonly BG_SCHEMA="org.gnome.desktop.background"
readonly IFACE_SCHEMA="org.gnome.desktop.interface"

run_worker() {
  # Never let a worker failure kill the watch loop; the service must stay up.
  "${WORKER}" run || true
}

# Debounce: GNOME often emits picture-uri and picture-uri-dark back to back.
# Collapse a burst into one run with a short settle delay.
last_run=0
debounced() {
  local now
  now=$(date +%s)
  if (( now - last_run < 2 )); then
    return 0
  fi
  last_run=$now
  run_worker
}

# gsettings monitor prints one line per change, for either schema. We do not
# parse the line; any change on these keys means "re-derive".
monitor() {
  gsettings monitor "${BG_SCHEMA}" picture-uri-dark &
  gsettings monitor "${BG_SCHEMA}" picture-uri &
  gsettings monitor "${IFACE_SCHEMA}" color-scheme &
  wait
}

main() {
  if [[ ! -x "${WORKER}" ]]; then
    printf 'wallpaper-tinty-watch: worker not found at %s\n' "${WORKER}" >&2
    exit 1
  fi
  # One run at startup so the scheme matches the current wallpaper after login.
  run_worker
  # Then react to each change.
  monitor | while IFS= read -r _line; do
    debounced
  done
}

main "$@"

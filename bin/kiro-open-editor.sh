#!/usr/bin/env bash
#
# Launch the editor to review the files the Kiro agent changed.
#
# Single source of truth for the host-aware editor launcher. Both the manual
# `vk` shell function and the Stop hook (.kiro/hooks/kiro-changed.json) call
# this, so the backend choice lives in one place.
#
# The editor runs `:KiroChanged`, which opens the queued files and clears the
# queue. Backend selection mirrors the `v` function in modern/shell/aliases.sh:
#   WSL + neovide.exe -> native Windows build, nvim inside this distro
#   neovide present   -> plain Linux GUI
#   otherwise         -> terminal nvim
#
# neovide forwards nvim args only after `--`; terminal nvim takes -c directly
# and would read a leading `--` as filenames. That split is why the launch
# commands differ per backend.

set -Eeuo pipefail
shopt -s inherit_errexit

readonly EX_CMD="KiroChanged"

# Restore the parent environment for the editor we spawn.
#
# kiro-personal overrides XDG_DATA_HOME to isolate its auth store (see the
# kiro-personal function in modern/shell/aliases.sh). That override leaks into
# this hook, so neovide/mise/nvim would otherwise read a forked tool state.
# _KIRO_PARENT_XDG_DATA_HOME carries the real value; restore it here.
restore_parent_env() {
  if [[ -n "${_KIRO_PARENT_XDG_DATA_HOME:-}" ]]; then
    export XDG_DATA_HOME="${_KIRO_PARENT_XDG_DATA_HOME}"
  fi
  # Kiro's env has no DISPLAY or WAYLAND_DISPLAY, so a GUI editor cannot reach
  # the X/Wayland server and panics. WSLg serves X on :0; set it when absent.
  if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
    export DISPLAY=":0"
  fi
}

main() {
  restore_parent_env
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v neovide.exe >/dev/null 2>&1; then
    exec neovide.exe --wsl -- -c "${EX_CMD}"
  fi
  if command -v neovide >/dev/null 2>&1; then
    exec neovide -- -c "${EX_CMD}"
  fi
  exec nvim -c "${EX_CMD}"
}

main "$@"

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

main() {
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] && command -v neovide.exe >/dev/null 2>&1; then
    exec neovide.exe --wsl -- -c "${EX_CMD}"
  fi
  if command -v neovide >/dev/null 2>&1; then
    exec neovide -- -c "${EX_CMD}"
  fi
  exec nvim -c "${EX_CMD}"
}

main "$@"

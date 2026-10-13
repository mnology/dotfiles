#!/usr/bin/env bash
#
# bootstrap.sh - Push-button setup for the modern terminal workflow.
#
# Reproduces the kitty / tmux / starship / neovim / neovide / atuin / fzf /
# ripgrep / zoxide / mise / cargo environment, including the base24-hivacruz
# theme, on a fresh workstation.
#
# What provides what (from the audit):
#   - mise           single source of truth for CLI dev tools (fzf, rg, bat,
#                    eza, fd, node, python, ruby, ...); adds precmd+chpwd hooks
#   - cargo          neovide, tinty, stylua, tree-sitter, autohide-tdrop
#   - prezto         zsh completion, history-substring-search, editor keybinds
#                    (KEEP: completion comes from here, not atuin)
#   - atuin          shell history search (ctrl-r / up-arrow)
#   - zoxide         'z' directory jumping (chpwd hook)
#   - starship       prompt (overrides prezto's prompt module by design)
#   - tinty          theme engine: base24-hivacruz -> shell + kitty + vivid
#   - vivid          LS_COLORS for eza/ls
#
# All shell hooks (mise/zoxide/atuin/direnv/tinty/starship) live in
# zsh/zshrc, which this script symlinks into place. The prezto submodule
# tracks upstream; our runcoms live in zsh/ to stay free of merge conflicts.
#
# Style: see ~/.kiro/steering/engineering-style.md (Bash section) -
#   strict mode, quoted expansions, printf over echo, case dispatch, an
#   associative array of steps, no eval, idempotent, trap cleanup.
#
# Usage:
#   ./bootstrap.sh                 # run every step in order
#   ./bootstrap.sh --help          # list steps
#   ./bootstrap.sh links mise      # run only the named steps, in that order
#   DRY_RUN=1 ./bootstrap.sh       # print actions, change nothing

set -Eeuo pipefail
shopt -s inherit_errexit 2>/dev/null || true

# --- constants -------------------------------------------------------------

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DOTFILES_DIR
readonly DRY_RUN="${DRY_RUN:-0}"
readonly THEME="base24-hivacruz"

# Cargo tools not available (or not preferred) via mise. Pinned to the versions
# currently in use; --locked keeps the build reproducible.
readonly -a CARGO_TOOLS=(
  "neovide@0.16.2"
  "tinty@0.34.1"
  "stylua@2.5.2"
  "tree-sitter-cli@0.26.12"
  "autohide-tdrop@1.1.4"
)

# Symlink table: "link_path|target_path". target_path lives inside the repo.
# Order matters: mise config must be linked before the 'mise' step installs
# from it. Our runcoms, including zshenv, live in zsh/ so the prezto submodule
# stays pristine against upstream.
readonly -a LINKS=(
  "${HOME}/.local/bin/meld-tinty.py|${DOTFILES_DIR}/bin/meld-tinty.py"
  "${HOME}/.local/bin/kiro-tinty.py|${DOTFILES_DIR}/bin/kiro-tinty.py"
  "${HOME}/.local/bin/win-sync.py|${DOTFILES_DIR}/bin/win-sync.py"
  "${HOME}/.local/bin/starship-tinty.py|${DOTFILES_DIR}/bin/starship-tinty.py"
  "${HOME}/.local/bin/kiro-queue-changed.py|${DOTFILES_DIR}/bin/kiro-queue-changed.py"
  "${HOME}/.local/bin/kiro-open-editor.sh|${DOTFILES_DIR}/bin/kiro-open-editor.sh"
  "${HOME}/.kiro/hooks/kiro-changed.json|${DOTFILES_DIR}/modern/kiro/hooks/kiro-changed.json"
  "${HOME}/.config/nvim|${DOTFILES_DIR}/nvim"
  "${HOME}/.tmux.conf|${DOTFILES_DIR}/.tmux.conf"
  "${HOME}/.tmux/status.conf|${DOTFILES_DIR}/modern/tmux/status.conf"
  "${HOME}/.config/mise/config.toml|${DOTFILES_DIR}/modern/mise/config.toml"
  "${HOME}/.config/shell/aliases.sh|${DOTFILES_DIR}/modern/shell/aliases.sh"
  "${HOME}/.config/tinted-theming/tinty/config.toml|${DOTFILES_DIR}/modern/tinty/config.toml"
  "${HOME}/.config/kitty/kitty.conf|${DOTFILES_DIR}/modern/kitty/kitty.conf"
  "${HOME}/.config/kitty/theme.conf|${DOTFILES_DIR}/modern/kitty/theme.conf"
  "${HOME}/.zprezto|${DOTFILES_DIR}/prezto"
  "${HOME}/.zshrc|${DOTFILES_DIR}/zsh/zshrc"
  "${HOME}/.zpreztorc|${DOTFILES_DIR}/zsh/zpreztorc"
  "${HOME}/.zprofile|${DOTFILES_DIR}/zsh/zprofile"
  "${HOME}/.zshenv|${DOTFILES_DIR}/zsh/zshenv"
  # Git. .gitconfig needs .gitignore_global for its excludesfile setting.
  "${HOME}/.gitconfig|${DOTFILES_DIR}/.gitconfig"
  "${HOME}/.gitignore|${DOTFILES_DIR}/.gitignore"
  "${HOME}/.gitignore_global|${DOTFILES_DIR}/.gitignore_global"
  "${HOME}/.ssh/config|${DOTFILES_DIR}/.ssh/config"
)

# --- output helpers --------------------------------------------------------

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m  OK\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31merror:\033[0m %s\n' "$*" >&2
  exit 1
}

# Run a command, or just print it under DRY_RUN.
run() {
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '    [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# --- cleanup ---------------------------------------------------------------

cleanup() { return 0; }
trap cleanup EXIT

# --- steps -----------------------------------------------------------------

step_check() {
  log "Checking prerequisites"
  local missing=0 tool
  for tool in git curl; do
    command -v "${tool}" >/dev/null 2>&1 || {
      warn "missing: ${tool}"
      missing=1
    }
  done
  [[ "${missing}" -eq 0 ]] || die "install the missing prerequisites and re-run"
  [[ -f "${DOTFILES_DIR}/modern/mise/config.toml" ]] ||
    die "missing modern/mise/config.toml (run from a full clone)"
  ok "git and curl present; repo looks complete"
}

# System packages for building the cargo tools (neovide) and running the TUI
# stack on Debian/Ubuntu/WSL. Found by hand on the first WSL setup.
#
# Split by whether a portable manager (mise/cargo) can provide it:
#   apt-only dev packages  - headers/.pc files and the system toolchain. No
#                            portable equivalent, so always ensure these.
#   runtime tools          - a plain binary. Install from apt only if it is
#                            not already on PATH by any method, so portable
#                            installs are not duplicated.
# This step uses sudo apt and only runs where apt-get exists.
step_sysdeps() {
  log "Installing system build dependencies (apt)"
  if ! command -v apt-get >/dev/null 2>&1; then
    warn "no apt-get; install the build deps with your package manager by hand"
    warn "(need: a C toolchain, freetype, fontconfig, libclang; and imagemagick, unzip, wl-clipboard)"
    return 0
  fi

  # apt-only: dev headers and toolchain. mise/cargo cannot supply -dev packages.
  local apt_only=(
    build-essential   # C/C++ toolchain for cargo native builds (neovide)
    libfreetype-dev   # neovide font rendering
    libfontconfig-dev # neovide font rendering
    libclang-dev      # bindgen for native cargo crates
    pkg-config        # lets the build find the -dev .pc files
  )

  # runtime tools, keyed by the binary that proves one is already present.
  # "binary|apt-package"
  local runtime=(
    "convert|imagemagick"  # image preview (snacks / kitty graphics)
    "unzip|unzip"          # mason / tool archive extraction
    "wl-copy|wl-clipboard" # WSLg / Wayland clipboard
  )

  local to_install=("${apt_only[@]}")
  local entry bin pkg
  for entry in "${runtime[@]}"; do
    bin="${entry%%|*}"
    pkg="${entry#*|}"
    if command -v "${bin}" >/dev/null 2>&1; then
      ok "${pkg} already available (${bin} on PATH); skipping apt"
    else
      to_install+=("${pkg}")
    fi
  done

  run sudo apt-get update
  run sudo apt-get install -y "${to_install[@]}"
  ok "system build dependencies installed"
}

# Create one symlink from the table, backing up anything real in the way.
link_one() {
  local link_path="$1" target_path="$2"
  [[ -e "${target_path}" ]] || {
    warn "target missing, skipping: ${target_path}"
    return 0
  }

  # Already correct? Nothing to do (idempotent).
  if [[ -L "${link_path}" &&
    "$(readlink -f -- "${link_path}")" == "$(readlink -f -- "${target_path}")" ]]; then
    ok "already linked: ${link_path}"
    return 0
  fi

  run mkdir -p -- "$(dirname -- "${link_path}")"

  # Something real is in the way: back it up rather than clobber it.
  if [[ -e "${link_path}" || -L "${link_path}" ]]; then
    local backup
    backup="${link_path}.pre-bootstrap.$(date +%Y%m%d%H%M%S)"
    warn "backing up ${link_path} -> ${backup}"
    run mv -- "${link_path}" "${backup}"
  fi

  run ln -s -- "${target_path}" "${link_path}"
  ok "linked ${link_path} -> ${target_path}"
}

step_links() {
  log "Linking configs into \$HOME"
  local entry
  for entry in "${LINKS[@]}"; do
    link_one "${entry%%|*}" "${entry#*|}"
  done
  ok "config links in place"

  # Seed the untracked local ssh host file from the committed example. The
  # committed ~/.ssh/config Includes this; without it, ssh warns on every call.
  local ssh_local="${HOME}/.ssh/config.local"
  if [[ -e "${ssh_local}" ]]; then
    ok "ssh config.local present"
  else
    run mkdir -p -- "${HOME}/.ssh"
    run cp -- "${DOTFILES_DIR}/.ssh/config.local.example" "${ssh_local}"
    run chmod 600 -- "${ssh_local}"
    ok "seeded ssh config.local from example (edit it with your hosts)"
  fi
}

step_prezto() {
  log "Ensuring prezto is present (zsh completion, history, keybinds)"
  if [[ -d "${DOTFILES_DIR}/prezto/modules" ]]; then
    ok "prezto modules vendored in repo"
  else
    warn "prezto/modules missing; initialize submodules:"
    warn "  git -C '${DOTFILES_DIR}' submodule update --init --recursive"
  fi
}

# Install mise itself if absent, then install every tool from the tracked
# config.toml. Depends on the mise config symlink from step_links.
step_mise() {
  log "Installing mise and managed tools"
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise not found; installing via https://mise.run"
    if [[ "${DRY_RUN}" == "1" ]]; then
      printf '    [dry-run] curl -fsSL https://mise.run | sh\n'
    else
      curl -fsSL https://mise.run | sh
    fi
  fi
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise still not on PATH; open a new shell, then: ./bootstrap.sh mise"
    return 0
  fi
  run mise install --yes
  ok "mise tools installed"
}

step_cargo() {
  log "Installing cargo tools"
  if ! command -v cargo >/dev/null 2>&1; then
    warn "cargo not found; install Rust (https://rustup.rs), then: ./bootstrap.sh cargo"
    return 0
  fi
  local spec name version
  for spec in "${CARGO_TOOLS[@]}"; do
    name="${spec%@*}"
    version="${spec#*@}"
    if command -v "${name}" >/dev/null 2>&1; then
      ok "${name} already installed"
      continue
    fi
    run cargo install --locked "${name}" --version "${version}"
  done
  ok "cargo tools installed"
}

# Install the global Python CLI tools listed in requirements.in, each in its
# own isolated environment via "uv tool install". This avoids the dependency
# conflicts of one shared global env. uv comes from mise (see mise config).
# Install the global Python packages.
#   - requirements.in      CLI tools  -> "uv tool install" (one isolated env
#                          per tool, each shimmed onto PATH). Avoids the
#                          dependency conflicts of one shared global env.
#   - requirements-lib.in  libraries  -> "uv pip install --system". Libraries
#                          have no executable, so "uv tool install" fails.
# uv comes from mise (see the mise config).
step_python() {
  log "Installing global Python packages (uv)"
  if ! command -v uv >/dev/null 2>&1; then
    warn "uv not found (install via 'mise' step first); skipping"
    return 0
  fi

  # CLI tools: one isolated environment each.
  local tools="${DOTFILES_DIR}/requirements.in"
  if [[ -f "${tools}" ]]; then
    local pkg
    while IFS= read -r pkg; do
      pkg="${pkg%%#*}"           # strip inline comments
      pkg="${pkg//[[:space:]]/}" # strip whitespace
      [[ -z "${pkg}" ]] && continue
      run uv tool install "${pkg}"
    done <"${tools}"
    ok "CLI tools installed"
  else
    warn "no requirements.in; skipping CLI tools"
  fi

  # Libraries: one shared environment via uv pip.
  local libs="${DOTFILES_DIR}/requirements-lib.in"
  if [[ -f "${libs}" ]]; then
    run uv pip install --system -r "${libs}"
    ok "libraries installed"
  else
    warn "no requirements-lib.in; skipping libraries"
  fi
}

# Install the terminal (kitty) and mise if missing.
#   - Debian/Ubuntu: prefer the upstream installer for a current kitty; apt's
#     build lags. Fall back to apt if curl is unavailable.
#   - Other hosts: print guidance.
# WezTerm on native Windows is installed by scripts/windows/setup.ps1.
step_terminal() {
  log "Installing terminal (kitty) and mise"

  # mise: the single source of truth for CLI tools.
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise missing; run the 'mise' step to install it"
  else
    ok "mise present"
  fi

  if command -v kitty >/dev/null 2>&1; then
    ok "kitty present: $(kitty --version 2>/dev/null || echo unknown)"
    return 0
  fi

  case "$(uname -s)" in
  Linux*)
    if command -v curl >/dev/null 2>&1; then
      warn "installing current kitty from the upstream installer"
      if [[ "${DRY_RUN}" == "1" ]]; then
        printf '    [dry-run] curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin\n'
      else
        curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
      fi
      run mkdir -p -- "${HOME}/.local/bin"
      run ln -sf -- "${HOME}/.local/kitty.app/bin/kitty" "${HOME}/.local/bin/kitty"
      run ln -sf -- "${HOME}/.local/kitty.app/bin/kitten" "${HOME}/.local/bin/kitten"
      ok "kitty installed to ~/.local/kitty.app and linked into ~/.local/bin"
    else
      warn "curl missing; install the distro package instead: sudo apt install kitty"
    fi
    ;;
  *)
    warn "install kitty by hand on this host, or use WezTerm on Windows (scripts/windows/setup.ps1)"
    ;;
  esac
}

# Fetch tinty's theme sources and apply base24-hivacruz. This regenerates the
# kitty include file and shell theme that kitty.conf / zshrc reference.
step_theme() {
  log "Applying theme (${THEME}) via tinty"
  if ! command -v tinty >/dev/null 2>&1; then
    warn "tinty not found (install via 'cargo' step first); skipping theme"
    return 0
  fi
  run tinty install
  run tinty apply "${THEME}"
  # Generate zsh completions from the installed tinty (not tracked; regenerated
  # here so they match the installed version). zshrc sources this path.
  run mkdir -p -- "${HOME}/.config/shell"
  if [[ "${DRY_RUN}" == "1" ]]; then
    printf '    [dry-run] tinty generate-completion zsh > ~/.config/shell/tinty-completion.zsh\n'
  else
    tinty generate-completion zsh >"${HOME}/.config/shell/tinty-completion.zsh"
  fi
  ok "theme applied; completions generated; kitty/shell artifacts regenerated"
}

# Install tmux plugin manager so the tinted-tmux status theme can load.
step_tmux() {
  log "Setting up tmux plugin manager (tpm)"
  local tpm_dir="${HOME}/.tmux/plugins/tpm"
  if [[ -d "${tpm_dir}" ]]; then
    ok "tpm already present"
  else
    run git clone --depth 1 https://github.com/tmux-plugins/tpm "${tpm_dir}"
    ok "tpm cloned; inside tmux press prefix + I to install plugins"
  fi
}

# Install the vendored FiraCode Nerd Font so TUI and GUI icons render.
# Linux and WSL use fontconfig. Native Windows cannot install fonts from a
# POSIX script, so this step only prints the manual action there; under WSL
# the fontconfig install is enough because kitty runs on the Linux side.
step_fonts() {
  log "Installing fonts (FiraCode Nerd Font)"
  local src_dir="${DOTFILES_DIR}/modern/fonts"
  if [[ ! -d "${src_dir}" ]]; then
    warn "no modern/fonts directory; skipping"
    return 0
  fi

  case "$(uname -s)" in
  Linux* | Darwin*)
    local dest="${HOME}/.local/share/fonts"
    [[ "$(uname -s)" == "Darwin" ]] && dest="${HOME}/Library/Fonts"
    run mkdir -p -- "${dest}"
    run cp -f -- "${src_dir}"/*.ttf "${dest}/"
    if command -v fc-cache >/dev/null 2>&1; then
      run fc-cache -f "${dest}"
    fi
    ok "fonts installed to ${dest}"
    ;;
  *)
    warn "non-POSIX host detected"
    warn "install ${src_dir}/*.ttf by hand (right-click -> Install), or on WSL run this step inside the distro"
    ;;
  esac
}

# Copy repo files to their Windows paths (WSL only). Symlinks across the
# boundary fail, so win-sync.py copies the files in modern/sync/win-map.toml.
# No-op off WSL or when the Windows paths do not resolve.
step_winsync() {
  log "Syncing files to Windows (win-sync push)"
  if [[ -z "${WSL_DISTRO_NAME:-}" ]]; then
    ok "not WSL; skipping Windows sync"
    return 0
  fi
  if command -v win-sync.py >/dev/null 2>&1; then
    run win-sync.py push
  else
    run "${DOTFILES_DIR}/bin/win-sync.py" push
  fi
  ok "Windows files synced"
}

step_verify() {
  log "Verifying"
  if command -v nvim >/dev/null 2>&1; then
    if run nvim --headless "+qa"; then
      ok "nvim starts without errors"
    else
      warn "nvim reported startup errors (see output above)"
    fi
  else
    warn "nvim not on PATH yet (open a new shell so mise shims load)"
  fi
  command -v tinty >/dev/null 2>&1 &&
    ok "current theme: $(tinty current 2>/dev/null || echo unknown)"
}

# --- dispatch --------------------------------------------------------------

# Ordered step list and the name->function table (dispatch by data, rule 2).
readonly -a STEP_ORDER=(check sysdeps terminal links prezto mise python cargo theme tmux fonts winsync verify)
declare -A STEPS=(
  [check]=step_check
  [sysdeps]=step_sysdeps
  [terminal]=step_terminal
  [links]=step_links
  [prezto]=step_prezto
  [mise]=step_mise
  [python]=step_python
  [cargo]=step_cargo
  [theme]=step_theme
  [tmux]=step_tmux
  [fonts]=step_fonts
  [winsync]=step_winsync
  [verify]=step_verify
)
readonly STEPS

usage() {
  cat <<EOF
bootstrap.sh - reproduce the modern terminal workflow (theme: ${THEME})

Usage:
  ./bootstrap.sh [STEP...]     run all steps, or only the named ones (in order)
  DRY_RUN=1 ./bootstrap.sh     show actions without changing anything

Steps (default order):
  check    verify prerequisites (git, curl) and repo integrity
  sysdeps  install apt build deps (toolchain, freetype, fontconfig, ...)
  terminal install kitty (current, upstream installer) and confirm mise
  links    symlink nvim/tmux/starship/mise/shell/tinty/kitty/prezto configs
  prezto   confirm prezto modules are vendored (zsh completion/history)
  mise     install mise (if needed) and all tools from modern/mise/config.toml
  python   install requirements.in CLI tools (uv tool install) and requirements-lib.in libraries (uv pip)
  cargo    install pinned cargo tools (neovide, tinty, stylua, ...)
  theme    tinty install + apply ${THEME} (regenerates kitty/shell theme)
  tmux     install tpm (tmux plugin manager)
  fonts    install the vendored FiraCode Nerd Font (Linux/WSL/macOS)
  winsync  copy repo files to their Windows paths (WSL only; win-sync push)
  verify   headless nvim smoke test + report current theme
EOF
}

main() {
  case "${1:-}" in
  -h | --help)
    usage
    return 0
    ;;
  esac

  local -a requested=()
  if [[ "$#" -eq 0 ]]; then
    requested=("${STEP_ORDER[@]}")
  else
    local arg
    for arg in "$@"; do
      [[ -v "STEPS[${arg}]" ]] || die "unknown step: ${arg} (try --help)"
      requested+=("${arg}")
    done
  fi

  [[ "${DRY_RUN}" == "1" ]] && warn "DRY_RUN=1: no changes will be made"
  log "dotfiles: ${DOTFILES_DIR}"

  local name
  for name in "${requested[@]}"; do
    "${STEPS[${name}]}"
  done

  log "Done."
  warn "Start a new zsh session to load mise/zoxide/atuin/direnv/tinty/starship hooks."
}

main "$@"

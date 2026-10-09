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
# prezto/runcoms/zshrc, which this script symlinks into place.
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
# from it. prezto runcoms are linked individually (matching the current box).
readonly -a LINKS=(
  "${HOME}/.config/nvim|${DOTFILES_DIR}/nvim"
  "${HOME}/.config/starship.toml|${DOTFILES_DIR}/starship.toml"
  "${HOME}/.tmux.conf|${DOTFILES_DIR}/.tmux.conf"
  "${HOME}/.config/mise/config.toml|${DOTFILES_DIR}/modern/mise/config.toml"
  "${HOME}/.config/shell/aliases.sh|${DOTFILES_DIR}/modern/shell/aliases.sh"
  "${HOME}/.config/tinted-theming/tinty/config.toml|${DOTFILES_DIR}/modern/tinty/config.toml"
  "${HOME}/.config/kitty/kitty.conf|${DOTFILES_DIR}/modern/kitty/kitty.conf"
  "${HOME}/.config/kitty/theme.conf|${DOTFILES_DIR}/modern/kitty/theme.conf"
  "${HOME}/.zprezto|${DOTFILES_DIR}/prezto"
  "${HOME}/.zshrc|${DOTFILES_DIR}/prezto/runcoms/zshrc"
  "${HOME}/.zpreztorc|${DOTFILES_DIR}/prezto/runcoms/zpreztorc"
  "${HOME}/.zprofile|${DOTFILES_DIR}/prezto/runcoms/zprofile"
  "${HOME}/.zshenv|${DOTFILES_DIR}/prezto/runcoms/zshenv"
)

# --- output helpers --------------------------------------------------------

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  OK\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! \033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }

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
    command -v "${tool}" >/dev/null 2>&1 || { warn "missing: ${tool}"; missing=1; }
  done
  [[ "${missing}" -eq 0 ]] || die "install the missing prerequisites and re-run"
  [[ -f "${DOTFILES_DIR}/modern/mise/config.toml" ]] \
    || die "missing modern/mise/config.toml (run from a full clone)"
  ok "git and curl present; repo looks complete"
}

# Create one symlink from the table, backing up anything real in the way.
link_one() {
  local link_path="$1" target_path="$2"
  [[ -e "${target_path}" ]] || { warn "target missing, skipping: ${target_path}"; return 0; }

  # Already correct? Nothing to do (idempotent).
  if [[ -L "${link_path}" \
        && "$(readlink -f -- "${link_path}")" == "$(readlink -f -- "${target_path}")" ]]; then
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
  ok "theme applied; kitty/shell artifacts regenerated"
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
  command -v tinty >/dev/null 2>&1 \
    && ok "current theme: $(tinty current 2>/dev/null || echo unknown)"
}

# --- dispatch --------------------------------------------------------------

# Ordered step list and the name->function table (dispatch by data, rule 2).
readonly -a STEP_ORDER=(check links prezto mise cargo theme tmux fonts verify)
declare -A STEPS=(
  [check]=step_check
  [links]=step_links
  [prezto]=step_prezto
  [mise]=step_mise
  [cargo]=step_cargo
  [theme]=step_theme
  [tmux]=step_tmux
  [fonts]=step_fonts
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
  links    symlink nvim/tmux/starship/mise/shell/tinty/kitty/prezto configs
  prezto   confirm prezto modules are vendored (zsh completion/history)
  mise     install mise (if needed) and all tools from modern/mise/config.toml
  cargo    install pinned cargo tools (neovide, tinty, stylua, ...)
  theme    tinty install + apply ${THEME} (regenerates kitty/shell theme)
  tmux     install tpm (tmux plugin manager)
  fonts    install the vendored FiraCode Nerd Font (Linux/WSL/macOS)
  verify   headless nvim smoke test + report current theme
EOF
}

main() {
  case "${1:-}" in
    -h | --help) usage; return 0 ;;
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

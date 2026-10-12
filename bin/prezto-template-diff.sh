#!/usr/bin/env bash
#
# Show how our zsh/ runcoms differ from the prezto upstream templates.
#
# Our runcoms live in zsh/ and control the workflow. The prezto submodule
# tracks upstream and holds the pristine templates in prezto/runcoms/. Upstream
# changes the templates rarely. Run this after "git -C prezto pull" to see what
# upstream added, then copy the wanted lines into our zsh/ copy by hand.
#
# Usage:
#   bin/prezto-template-diff.sh            # diff every mapped runcom
#   bin/prezto-template-diff.sh zpreztorc  # diff one runcom
#
# Exit status: 0 when no runcom differs, 1 when at least one differs.

set -Eeuo pipefail
shopt -s inherit_errexit 2>/dev/null || true

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly DOTFILES_DIR
readonly OURS_DIR="${DOTFILES_DIR}/zsh"
readonly TEMPLATE_DIR="${DOTFILES_DIR}/prezto/runcoms"

# Map our runcom name to the upstream template name. Only files we customized
# live here. zshenv and zlogin stay the pristine upstream copies.
readonly -a RUNCOMS=(zshrc zpreztorc zprofile)

# A pager that colors the diff when the terminal is interactive. delta follows
# tinty; plain diff is the fallback for a pipe or a host without delta.
diff_tool() {
  if [ -t 1 ] && command -v delta >/dev/null 2>&1; then
    delta
  else
    cat
  fi
}

diff_one() {
  local name="$1"
  local ours="${OURS_DIR}/${name}"
  local template="${TEMPLATE_DIR}/${name}"

  [ -r "$ours" ] || { printf 'skip %s: no copy in zsh/\n' "$name" >&2; return 0; }
  [ -r "$template" ] || { printf 'skip %s: no upstream template\n' "$name" >&2; return 0; }

  if diff -q "$template" "$ours" >/dev/null 2>&1; then
    printf 'same %s\n' "$name"
    return 0
  fi

  printf '\n=== %s (--- upstream template, +++ our copy) ===\n' "$name"
  # Do not let a non-zero diff status trip set -e; we report it ourselves.
  diff -u "$template" "$ours" | diff_tool || true
  return 1
}

main() {
  local -a targets
  if [ "$#" -gt 0 ]; then
    targets=("$@")
  else
    targets=("${RUNCOMS[@]}")
  fi

  local rc=0
  local name
  for name in "${targets[@]}"; do
    diff_one "$name" || rc=1
  done
  return "$rc"
}

main "$@"

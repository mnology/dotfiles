# ls
alias ls="eza"
alias l='ls -lah'
alias ll="l --git --icons"
alias lt="l --tree --level=2 --icons"
alias lr='l --sort=modified --reverse'

# git
alias gs='git status'
alias gl='git log --oneline --decorate --graph'
alias gco='git checkout'
alias gcb='git checkout -b'
alias lg='lazygit'

# tmux
alias ta='tmux attach'
alias tls='tmux ls'

# terraform
alias tf='terraform'

# misc
alias cat='bat'

if [ -n "$WSL_DISTRO_NAME" ] && command -v neovide.exe >/dev/null 2>&1; then
  # WSL: use the native Windows build, running nvim inside this distro
  v() { neovide.exe --wsl "$@"; }
elif command -v neovide >/dev/null 2>&1; then
  # plain Linux GUI
  v() { neovide "$@"; }
else
  # no GUI available, fall back to terminal nvim
  v() { nvim "$@"; }
fi

# obsidian: the Linux Electron build renders tiny under WSLg (reports 96 DPI on
# a scaled 4K panel). Electron ignores Xft.dpi, so force the Chromium scale to
# match Windows 150%. Backgrounded and detached so the terminal stays free.
if command -v obsidian >/dev/null 2>&1; then
  obsidian() { nohup /usr/bin/obsidian --force-device-scale-factor=1.5 "$@" >/dev/null 2>&1 & disown; }
fi

# vk: open the files the Kiro agent changed, then clear the queue. The
# PostFileSave hook queues them; :KiroChanged opens and clears. Both vk and the
# Stop hook call the same launcher script, so the host-aware backend choice and
# the neovide `--` arg-forwarding quirk live in one place.
vk() { "$HOME/devel/personal/dotfiles/bin/kiro-open-editor.sh"; }

# kiro-personal / kp: run Kiro CLI under a separate auth identity.
#
# Kiro stores its auth token in $XDG_DATA_HOME/kiro-cli/data.sqlite3. A second
# XDG_DATA_HOME is the only lever that persists a second, independent login, so
# the personal data dir exists solely to hold that separate auth store.
#
# XDG_DATA_HOME is a general var every child reads, so the override would leak
# into hooks, mise, neovide, and nvim and fork their state. To stop that, we
# save the parent value in _KIRO_PARENT_XDG_DATA_HOME; kiro-open-editor.sh (and
# any GUI-spawning hook) restores it so spawned tools use the real, shared dir.
kiro-personal() {
  _KIRO_PARENT_XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
  XDG_DATA_HOME="$HOME/devel/personal/.kiro-personal/data" \
    kiro-cli "$@"
}
kp() { kiro-personal --tui --v3; }

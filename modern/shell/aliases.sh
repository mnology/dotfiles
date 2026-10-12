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
  # plain Linux
  v() { neovide "$@"; }
else
  # no GUI available, fall back to terminal nvim
  v() { nvim "$@"; }
fi

# vk: open the files the Kiro agent changed, then clear the queue. The
# PostFileSave hook queues them; :KiroChanged opens and clears. Reuses v so the
# host-aware launcher (neovide / neovide.exe --wsl / nvim) is picked once.
vk() { v -c KiroChanged; }

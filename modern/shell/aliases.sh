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

# tmux
alias ta='tmux attach'
alias tls='tmux ls'

# terraform
alias tf='terraform'

# misc
alias cat='bat'

if [ -n "$WSL_DISTRO_NAME" ] && command -v neovide.exe >/dev/null 2>&1; then
  # WSL: use the native Windows build, running nvim inside this distro
  alias v='neovide.exe --wsl'
elif command -v neovide >/dev/null 2>&1; then
  # plain Linux
  alias v='neovide'
else
  # no GUI available, fall back to terminal nvim
  alias v='nvim'
fi

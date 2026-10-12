# Dotfiles Specification

Modern terminal workflow: kitty / tmux / starship / Neovim / Neovide / atuin /
fzf / ripgrep / mise / cargo, themed with base24-hivacruz.

This document records how the environment is built, what provides what, and the
differences found when the environment moved from the first Linux host to a
Windows 11 host that runs WSL.

## Hosts

| Host | OS | User | Role |
| --- | --- | --- | --- |
| original | Linux (bare) | ejohanse | first setup |
| typhon | Windows 11 + WSL2 (Ubuntu-26.04) | mnology | current |

## Tool sources

- mise: the single source of truth for command-line tools. See
  `modern/mise/config.toml`.
- cargo: tools that mise does not provide (neovide, tinty, stylua,
  tree-sitter, autohide-tdrop).
- prezto: zsh completion, history search, and editor key bindings.
- Shell hooks (in `prezto/runcoms/zshrc`): mise, zoxide, atuin, direnv, tinty,
  and starship.
- Theme: tinty applies base24-hivacruz to the shell, kitty, and vivid
  (`LS_COLORS`). tmux uses the gruvbox status theme.
- Fonts: FiraCode Nerd Font. The TTF files are in `modern/fonts/`.
- Git TUI: lazygit (via mise). Open it with the `lg` alias, or in Neovim with
  `<leader>gg` through snacks.

## Install

Run `bootstrap.sh` on a new Linux or WSL host. On Windows, run
`scripts/windows/setup.ps1` first to install WezTerm and the font.

## WSL <-> Windows file sync

Some files must exist on the Windows side (Kiro settings, wezterm.lua) but are
tracked in the repo on the WSL side. Symlinks across the boundary fail (Windows
cannot follow a symlink into `\\wsl.localhost` over UNC), so the files are
copied. `bin/win-sync.py` reads `modern/sync/win-map.toml` and copies in an
explicit direction; there is no automatic merge:

- `win-sync.py push` - repo -> Windows (what the bootstrap `winsync` step runs).
- `win-sync.py pull` - Windows -> repo (capture edits made in a Windows app,
  for example theme or settings changes made in the Kiro UI).
- `win-sync.py status` - report which side differs.

A differing target is backed up to `*.pre-winsync` before it is overwritten.

Steps, in order: check, terminal, links, prezto, mise, python, cargo, theme,
tmux, fonts, verify. Run `./bootstrap.sh --help` for details.

## Terminals

- Linux and WSL: kitty. The apt build lags, so bootstrap installs the current
  kitty from the upstream installer and links it into `~/.local/bin`.
- Windows: WezTerm (native). It uses the hivacruz colors and the Nerd Font and
  opens the WSL distro by default. See `modern/wezterm/wezterm.lua`.
- kitty has no native Windows build. On Windows, run kitty inside WSL through
  WSLg, or use WezTerm.

## Cross-host porting notes (Linux -> Windows/WSL)

These changes were needed to make the environment work on the WSL host. They
are host-aware so that both platforms keep working from one repository.

### Editor and the `v` alias

- `modern/shell/aliases.sh` sets `v` by host:
  - WSL with `neovide.exe` on the path: `v = neovide.exe --wsl`. This runs the
    native Windows Neovide and edits files inside the WSL distro.
  - Plain Linux: `v = neovide`.
  - No GUI: `v = nvim`.
- `.gitconfig` uses `editor = v --no-fork`, so Git follows the same per-host
  choice. `--no-fork` makes Neovide block, so Git waits for the message.
- On this host `neovide.exe` resolves through WSL interop to
  `/mnt/c/Program Files/Neovide/neovide.exe`.

### Neovide font name

- The Nerd Font family name differs by platform. `nvim/lua/neovide.lua` selects
  it at runtime:
  - Windows and WSL (neovide.exe): `FiraCode_Nerd_Font_Mono` (underscores, Mono
    face). Windows matches fonts by the installed face name.
  - Linux (fontconfig): `FiraCode Nerd Font` (spaces).

### mise tools moved from the system to mise

On the first host, several tools came from apt or snap. Fresh WSL did not have
them, so they moved into mise to make the toolset self-sufficient. Added to
`modern/mise/config.toml`: atuin, black, direnv, prettier, rust, shfmt,
starship, tombi, zoxide.

### tmux

- Added `@continuum-restore 'on'` so tmux-continuum restores the last session
  on start.
- The gruvbox status theme is the single tmux theme.

## System prerequisites (Debian / Ubuntu / WSL)

The cargo tools and the TUI stack need system packages. The `sysdeps` step of
`bootstrap.sh` installs them with `sudo apt-get`, and only installs what a
portable manager cannot provide.

apt-only (dev headers and toolchain; no mise/cargo equivalent, always ensured):

- `build-essential` - C/C++ toolchain for cargo native builds (neovide).
- `libfreetype-dev`, `libfontconfig-dev` - Neovide font rendering.
- `libclang-dev` - bindgen for native cargo crates.
- `pkg-config` - lets the build find the `-dev` `.pc` files.

runtime tools (installed from apt only if the binary is not already on PATH):

- `imagemagick` (`convert`) - image preview (snacks, kitty graphics).
- `unzip` - mason and tool archive extraction.
- `wl-clipboard` (`wl-copy`) - WSLg and Wayland clipboard.

## Manual steps (not done by bootstrap.sh)

These need a password, a Windows context, or a shell restart, so run them by
hand:

- `wsl --update` on Windows, for a current WSLg and GPU rendering.
- `git submodule update --init --recursive --depth 1 --jobs 8` to fetch prezto
  and the other submodules.
- `chsh -s "$(command -v zsh)"` to set zsh as the login shell. Log out and in.
- On Windows, run `scripts/windows/setup.ps1` for WezTerm and the font.

## Conventions

- Lua: two-space indent. The repository has no `stylua.toml`; stylua defaults to
  tabs, so pass `--indent-type Spaces --indent-width 2` or do not rely on the
  stylua default.
- Commit messages and code comments: ASD-STE100 (Simplified Technical English).
  Short, clear, imperative sentences; one idea per line.
- Neovim plugins: lazy-load where possible. obsidian, avante, and markdown-toc
  load only on their filetypes, commands, or keys, so a missing vault or a down
  service never breaks startup.

## Theme switching (tinty apply)

`tinty apply <scheme>` switches the theme across the whole stack at once. The
tinty config (`modern/tinty/config.toml`) runs a hook per target:

- Shell and kitty: the tinted-shell and tinted-terminal items.
- Neovim: the `tinted-theming/tinted-nvim` plugin follows the scheme.
- bat and delta: both read ANSI colors, so they follow the terminal palette.
  delta is styled with ANSI slots in `.gitconfig`.
- WezTerm: the hook copies the generated theme and writes `current_scheme`;
  `wezterm.lua` reads it and reloads. The hook derives the Windows profile from
  `cmd.exe`, so it works for any user.
- Meld: `bin/meld-tinty.py` builds a GtkSourceView scheme from the active
  palette, writes it to `~/.local/share/gtksourceview-4/styles`, and selects it
  with gsettings.
- Kiro IDE: the Tinted VSCode extension (`TintedTheming.base16-tinted-themes`)
  registers one theme per scheme, with labels equal to tinty scheme ids.
  `bin/kiro-tinty.py` writes the current scheme id into `workbench.colorTheme`
  in the Windows Kiro settings, and the IDE live-reloads it.

Platform and version notes:

- tinty runs each hook as `zsh -c '<hook>'`, so a hook must contain no single
  quotes. Use double quotes.
- The Meld integration targets `gtksourceview-4`, the version Meld links. The
  scheme must use the runtime `name` attribute (not the `_name` gettext form)
  and set `parent-scheme="classic"`, or GtkSourceView does not load it.
- Kiro IDE needs `window.autoDetectColorScheme` set to false, or it ignores
  `workbench.colorTheme` and uses the preferred dark/light theme instead.
- The WezTerm hook relies on WSL `cmd.exe` and `wslpath`. On non-WSL hosts
  `cmd.exe` is absent, so the WezTerm sync is skipped.

## Known follow-ups

- The Meld path (`gtksourceview-4`) is version-bound. A future GtkSourceView 5
  Meld would need `gtksourceview-5/styles`.
- Full-history email scrub with BFG. Only recent commits use the anonymized
  address; older history still has the work email.
- `scripts/windows/setup.ps1` is not lint-tested on Linux (no pwsh). Validate it
  on Windows. If the winget font id `DEVCOM.FiraCodeNerdFont` fails, find the
  current id with `winget search FiraCode`.
- avante uses a local ollama provider. If ollama is down, avante can still error
  when invoked (not at startup, since it is lazy-loaded).

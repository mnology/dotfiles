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
- prezto: zsh completion, history search, and editor key bindings. prezto is
  the pristine upstream submodule; our runcoms live in `zsh/` (zshenv, zprofile,
  zshrc, zpreztorc) and symlink into `$HOME`, so upstream pulls never conflict.
- Shell hooks (in `zsh/zshrc`): mise, zoxide, atuin, direnv, tinty, and
  starship.
- Theme: tinty applies the scheme to the shell, kitty, vivid (`LS_COLORS`), the
  starship prompt, and the tmux status bar. The starship prompt and tmux status
  colors are derived from the active scheme by `bin/starship-tinty.py`; they
  adapt to any base16 or base24 theme. See "Adaptive prompt and status theming".
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
  Push refuses a file when the Windows side is newer and differs, because it
  may hold edits not yet pulled back. Run `pull`, or `push --force` to override.
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
- The status bar is theme-adaptive, not a fixed theme. See "Adaptive prompt and
  status theming".

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
- fzf: zshrc sources the tinted-fzf theme into FZF_DEFAULT_OPTS at shell start.
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

## Adaptive prompt and status theming

`bin/starship-tinty.py` is a tinty hook. On every `tinty apply` it reads the
active scheme and generates the starship prompt palette and the tmux status
colors from it, so both adapt to any base16 or base24 scheme and stay legible.
It runs in the tinty hook chain next to `meld-tinty.py` and `kiro-tinty.py`.

### Data source

- The script derives the scheme from `tinty current`, not from the hook's
  `TINTY_THEME_FILE_PATH`. That variable points at the chaining item's theme
  file (a wezterm `.toml`), not the shell palette, so it is the wrong source.
- It parses the tinted-shell script (`.../tinted-shell/scripts/<scheme>.sh`),
  which exposes every base role as `colorNN="RR/GG/BB"` for both base16 and
  base24, and maps those to `base00`-`base0f`.

### Color selection (both prompt and status share one selection)

- Candidate accents are `base08`-`base0e` (the hue-bearing roles).
- Rank by saturation (the palette designer's emphasis), skip near-duplicate
  hues (within 25 degrees), take the top four, then order those by hue so the
  bar sweeps the wheel. Saturation is used as-is, so a pastel scheme yields a
  pastel bar.
- Each segment foreground is the dark or light base that has the higher WCAG
  contrast against that segment background, so text is legible on a light or a
  dark accent.

### starship

- `starship.toml` is a TEMPLATE with a sentinel block
  (`# >>> TINTY PALETTE >>>` ... `# <<< TINTY PALETTE <<<`). The generator
  rewrites the block and writes the result to `$STARSHIP_CONFIG`
  (`~/.config/starship.generated.toml`), which starship reads. The template
  stays tracked and pristine; the live file is generated and untracked.
- `zsh/zshrc` exports `STARSHIP_CONFIG` before `starship init`.
- Palette keys are emitted lowercase. starship lowercases a `bg:`/`fg:`
  reference when it resolves it but stores palette keys case-sensitively, so an
  uppercase key like `base0A` never matches and the color silently drops.
- Foreground keys are named `ink_*`, never `fg_on_base0A`. starship resolves a
  palette value that references another palette key, so a name containing
  `base0A` is read as a reference to `base0A` and the style silently drops.
- The hue segments reference stable `seg1`-`seg4` aliases; the generator decides
  which accents fill them. The template keeps the Nerd Font pills.

### tmux status

- The generator also emits `~/.config/tmux/tinty-colors.conf`, a fragment of
  `@tinty_*` user options, from the same selection. `modern/tmux/status.conf`
  sources it and reloads the running server. Prompt and status use one palette.
- Semantic roles: session = seg1, host = seg2, current window = seg4 (the
  attention pill), activity = seg3. The clock is a recessed neutral pill, not
  an accent.
- Three depth levels keep the bar distinct from the terminal:
  terminal background (base00), a distinct bar surface (`@tinty_bar_bg` =
  base03, about 1.5:1 against base00), and a recessed clock pill
  (`@tinty_clock_bg` = base01). base01 alone is too close to base00 and makes
  the bar vanish, so the bar surface and the clock pill are separate roles.
- Shape: rounded caps at the far ends, solid powerline arrows between pills, a
  solid arrow (`@tinty_divider` = base05) leads each inactive tab, and thin
  arrows mark window list overflow. The current window is a filled accent pill
  with its own caps (left-pointing to open, right-pointing to close); it stands
  out by background, not just foreground. Activity windows switch to the seg3
  background and bold.
- Traps:
  - A separator string colour is overridden by the push/pop-default wrapping in
    `status-format[0]`, so a coloured `window-status-separator` renders black.
    The divider arrow is therefore baked into `window-status-format` (where an
    inline `#[fg]` applies), and the separator is empty. Every inactive tab,
    including the first, leads with the arrow. Suppressing it only on window 1
    was tried and dropped: nesting a comma-bearing `#[fg=,bg=]` inside a
    `#{?...}` branch breaks the tmux conditional parser and leaks literal text.
  - `window-status-activity-style` loses to the inline colours in
    `window-status-format`, so activity colours are baked into the format with a
    `#{?window_activity_flag,...}` conditional, not left to the style.
  - Current-window caps live in `window-status-current-format`, not the
    separator, for the same inline-colour reason.
  - Overflow markers are set by overriding `status-format[0]` (based on the
    tmux 3.6 default), replacing the literal `<`/`>` markers.
- Truecolor: tmux must advertise RGB or Tc for the client terminal, or the
  status colours downsample and can collapse to black. `.tmux.conf` sets both
  `terminal-features ...:RGB` and a `terminal-overrides ...:Tc` fallback for
  xterm-kitty and xterm-256color (WezTerm reports xterm-256color). The client
  reads this at attach, so a running client needs a detach/reattach, or
  `tmux kill-server`, to pick up a change.

### Notes and traps

- The tmux reload in the hook is best-effort: it is a no-op when no server runs,
  so it never breaks the apply chain.
- The generator refuses to write a path that resolves to the tracked template,
  so a stale symlink cannot clobber the template.

## Agent file-change review

The agent queues every file it saves or creates and the editor opens them for a
pass. The flow is pull, not push: nothing launches the editor mid-turn.

- Global hook at `~/.kiro/hooks/kiro-changed.json` (user-level, not in any
  repo workspace), so it fires for every Kiro session regardless of workspace.
  It is tracked in the repo at `modern/kiro/hooks/kiro-changed.json` and
  bootstrap symlinks it into `~/.kiro/hooks/`. PostFileSave and PostFileCreate
  run `kiro-queue-changed.py`, which appends the changed path to
  `~/.cache/kiro/changed-files`. A Stop hook runs `kiro-open-editor.sh` at the
  end of a turn when the queue is non-empty.
- The hook calls the scripts by their `~/.local/bin` symlinks, not the repo
  path, so it is not coupled to where the dotfiles repo lives. bootstrap links
  both scripts into `~/.local/bin`.
- `bin/kiro-open-editor.sh`: the single host-aware launcher (neovide.exe --wsl
  on WSL, neovide on Linux, else nvim). It runs `:KiroChanged`. `vk` in
  `modern/shell/aliases.sh` calls the same script.
- `nvim/lua/kiro-changed.lua`: defines `:KiroChanged`, which opens the queued
  files and clears the queue, so each review starts fresh.

Platform notes (WSL + Windows Kiro IDE):

- Hooks live on the WSL side and run in WSL. The Kiro IDE on Windows opens this
  repo over Remote-WSL (the `open-remote-wsl` extension, backend in
  `~/.kiro-server`), so a hook command for a WSL workspace executes inside WSL,
  with WSL paths and tools. The WSL CLI and the Remote-WSL IDE share this.
- The global hook location is confirmed for the WSL CLI (`~/.kiro/hooks/`). The
  IDE's pickup of user-global hooks over Remote-WSL is not documented offline
  and must be confirmed by testing in a non-dotfiles WSL workspace. If the IDE
  does not pick up the global hook, place a copy per workspace in that repo's
  `.kiro/hooks/`.

## SSH config

- `~/.ssh/config` is a committed skeleton: global `Host *` defaults
  (`AddKeysToAgent yes`, `IdentitiesOnly yes`, `ForwardX11 no`, keepalive) and
  an `Include ~/.ssh/config.local` first. Include is first because ssh uses the
  first value found for each option, so local host blocks override the globals.
- All host entries and keys live in the untracked `~/.ssh/config.local`.
  `.ssh/config.local.example` is the committed template; bootstrap seeds the
  local file from it. `.gitignore` excludes the local file, private keys,
  `known_hosts`, and `authorized_keys`.

## Session handoff

Dense state for resuming work in a fresh session. The git history and this file
are the durable signal; the chat transcript is not.

### Working agreement

- Chat voice: caveman (terse). Code comments, docs, commit messages: ASD-STE100.
- Check in before editing code: propose the change inline, get approval, then
  write. Do not edit files first and let the user diff after.
- Commits: ASD-STE100 messages, short bullets. The user approves the message,
  then chooses amend or new, then approves the push. Never push unprompted.
- Prefer small, reviewable commits. Stage files by name, not `git add .`.
- Identity for commits: ejohanse@users.noreply.github.com (anonymized).

### Repo and submodule layout

- Main repo: git@github.com:mnology/dotfiles.git, branch master.
- prezto is the pristine upstream submodule (sorin-ionescu/prezto.git). Runcom
  edits do NOT go in the submodule: our runcoms live in `zsh/` (zshenv,
  zprofile, zshrc, zpreztorc) and symlink into `$HOME`. bootstrap links
  `~/.zshenv` to `zsh/zshenv`, not to the prezto copy. One commit, in the main
  repo. Pulling prezto upstream never conflicts with our runcoms.
- Generated artifacts are not tracked; they are regenerated (tinty themes,
  kitty include, delta config, tinty completions). bootstrap.sh regenerates
  them.

### How the theme pipeline hangs together

- `tinty apply <scheme>` drives everything: shell, kitty, wezterm, tmux, nvim,
  kiro, meld, bat, delta, fzf, the starship prompt, and the tmux status bar.
  See the Theme switching and "Adaptive prompt and status theming" sections.
- The starship prompt and tmux status colors are generated per scheme by
  `bin/starship-tinty.py` (adaptive, saturation-ranked accents, WCAG-legible
  foregrounds). The prompt reads `$STARSHIP_CONFIG`
  (`~/.config/starship.generated.toml`, untracked); the status reads
  `~/.config/tmux/tinty-colors.conf` (untracked). Both are regenerated.
- nvim uses prebuilt tinted-nvim themes first, and builds any missing scheme
  from the scheme YAML (nvim/lua/tinted-fallback.lua).
- Windows-side files (kiro settings, wezterm.lua) are copied, not symlinked
  (UNC limitation). bin/win-sync.py push/pull/status; push refuses to clobber a
  newer Windows file. Run `win-sync.py pull` after editing settings in a
  Windows app, then commit.

### Open loops

- Scrub the old work email from pre-anonymization git history with BFG.
- editorconfig gives 2-space on hand-edited files only; generated and
  tool-written files keep their own indent. That is the ceiling.

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

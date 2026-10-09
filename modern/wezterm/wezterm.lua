-- WezTerm config for Windows. Matches the Linux kitty look:
-- base24-hivacruz colors and FiraCode Nerd Font. Opens WSL by default.
--
-- Theme source order:
--   1. The tinty-generated WezTerm theme, if present. This keeps WezTerm in
--      sync when you re-theme with tinty.
--   2. The embedded hivacruz palette below, as a self-contained fallback.
--
-- Install path on Windows: %USERPROFILE%\.config\wezterm\wezterm.lua
-- The PowerShell script scripts/windows/setup.ps1 copies it there.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Open the WSL distro by default. Change "Ubuntu" to your distro name.
config.default_domain = "WSL:Ubuntu"

-- Match kitty: FiraCode Nerd Font supplies the icon glyphs.
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 10.0

-- GPU front end. Change to "OpenGL" if WebGpu is not available.
config.front_end = "WebGpu"

-- Try the tinty-generated theme first, then fall back to embedded colors.
local function tinty_wezterm_theme()
  local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
  local path = home
    .. "/.config/tinted-theming/tinty/wezterm/base24-hivacruz.toml"
  local file = io.open(path, "r")
  if file == nil then
    return nil
  end
  file:close()
  return path
end

local theme = tinty_wezterm_theme()
if theme ~= nil then
  config.color_scheme_dirs = { (theme:gsub("/[^/]+$", "")) }
  config.color_scheme = "base24-hivacruz"
else
  -- Embedded hivacruz palette (same values as the Linux terminal theme).
  config.colors = {
    foreground = "#ede4e4",
    background = "#132638",
    cursor_bg = "#979db4",
    cursor_border = "#979db4",
    cursor_fg = "#202746",
    selection_bg = "#5e6687",
    selection_fg = "#979db4",
    ansi = {
      "#202746",
      "#c94922",
      "#ac9739",
      "#c08b30",
      "#3d8fd1",
      "#6679cc",
      "#22a2c9",
      "#979db4",
    },
    brights = {
      "#6b7394",
      "#c76b29",
      "#73ad43",
      "#5e6687",
      "#898ea4",
      "#dfe2f1",
      "#9c637a",
      "#f5f7ff",
    },
  }
end

return config

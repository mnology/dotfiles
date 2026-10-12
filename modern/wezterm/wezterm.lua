-- WezTerm config for Windows. Opens WSL by default and follows the tinty theme.
--
-- The tinty hook (modern/tinty/config.toml) copies the scheme toml files into
-- colors/ and writes the active scheme name to current_scheme, both under this
-- config dir (%USERPROFILE%\.config\wezterm). WezTerm registers each toml under
-- its filename, so color_scheme = <current_scheme> resolves directly.

local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Open the WSL distro by default.
config.default_domain = "WSL:Ubuntu-26.04"

-- Match kitty: FiraCode Nerd Font supplies the icon glyphs.
config.font = wezterm.font("FiraCode Nerd Font")
config.font_size = 10.0

-- GPU front end. Change to "OpenGL" if WebGpu is not available.
config.front_end = "WebGpu"

-- Follow the tinty-selected theme.
local function read_file(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local s = f:read("*l")
	f:close()
	return s
end

config.color_scheme_dirs = { wezterm.config_dir .. "/colors" }
local scheme = read_file(wezterm.config_dir .. "/current_scheme")
config.color_scheme = scheme or "base16-ayu-dark"
wezterm.add_to_config_reload_watch_list(wezterm.config_dir .. "/current_scheme")

return config

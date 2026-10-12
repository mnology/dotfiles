-- Follow tinty across all schemes, not only the ones tinted-nvim prebuilds.
--
-- tinted-nvim ships prebuilt themes; tinty's scheme repo has more (for example
-- the pastelon schemes). When a scheme is not prebuilt, read its YAML from
-- tinty's scheme repo and apply the palette directly. Prebuilt stays the
-- primary path; the YAML is the fallback.

local M = {}

local tinted = require("tinted-colorscheme")

-- Config for every setup call: disable tinted-nvim's own tinty watcher, since
-- this module runs the watcher (see M.start). Passing real colors (a name or a
-- palette) also avoids the empty-table "unable to find suitable" warning.
local SETUP_CFG = { supports = { live_reload = false } }

-- Read the active scheme name that tinty wrote (base16-... or base24-...).
local function current_scheme()
  local out = vim.fn.systemlist({ "tinty", "current" })
  if vim.v.shell_error ~= 0 or #out == 0 then
    return nil
  end
  return vim.fn.trim(out[1])
end

-- Parse a tinty scheme YAML into a tinted-nvim palette table. The format is
-- flat: baseXX: "#rrggbb" lines plus variant: "dark". A line regex is enough;
-- no YAML library is pulled in.
local function load_palette(name)
  local system = name:match("^(base%d+)%-")
  local slug = name:gsub("^base%d+%-", "")
  if system == nil then
    return nil
  end
  local root = vim.fn.expand("~/.local/share/tinted-theming/tinty/repos/schemes")
  local path = string.format("%s/%s/%s.yaml", root, system, slug)
  local f = io.open(path, "r")
  if f == nil then
    return nil
  end

  local palette = {}
  for line in f:lines() do
    local key, hex = line:match('^%s*(base%x%x)%s*:%s*"?(#%x+)"?')
    if key ~= nil then
      palette[key] = hex
    end
    local variant = line:match('^%s*variant%s*:%s*"?(%a+)"?')
    if variant ~= nil then
      palette.variant = variant
    end
  end
  f:close()

  if palette.base00 == nil then
    return nil -- not a usable palette
  end
  return palette
end

-- Apply the current scheme: prefer the prebuilt theme, fall back to YAML.
-- Check the prebuilt table directly, because setup() with a missing name does
-- not error, so a pcall alone would never trigger the fallback.
function M.apply()
  local name = current_scheme()
  if name == nil then
    return
  end
  -- Probe the prebuilt set safely: colorschemes[name] lazy-requires
  -- colors.<name> and throws when missing, so guard the probe with pcall.
  local prebuilt_ok = pcall(require, "colors." .. name)
  if prebuilt_ok then
    pcall(tinted.setup, name, SETUP_CFG)
    return
  end
  local palette = load_palette(name)
  if palette ~= nil then
    pcall(tinted.setup, palette, SETUP_CFG)
  else
    vim.notify(
      string.format("tinted-fallback: no prebuilt or YAML scheme for '%s'", name),
      vim.log.levels.WARN
    )
  end
end

-- Start following tinty. Reuse tinted-nvim's own watcher (it handles the
-- data-dir lookup and the Tinty 0.28+ file-replace re-arm), but give it our
-- callback so misses fall back to YAML.
function M.start()
  M.apply()
  require("tinted-live-reload").setup_live_reload(function()
    M.apply()
  end)
end

return M

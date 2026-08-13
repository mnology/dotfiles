-- Migration Flags
local migration = require("migration")

-- Leader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins")

-- Native Lua Config
if not migration.legacy_options then
  require("options")
end

require("neovide")
require("keymaps")
require("integrations")
require("languages")
require("colors")
require("term")

if not migration.legacy_autocmds then
  require("autocmds")
end

if not migration.legacy_gui then
  require("neovide")
end

-- Legacy Fallback
if migration.use_legacy_everything then
  vim.cmd("source ~/.config/nvim/vimrc-legacy.vim")
end

local opt = vim.opt

opt.autoindent = true
opt.autoread = true
opt.autowrite = true

opt.backspace = {
  "indent",
  "eol",
  "start",
}

opt.background = "dark"

opt.colorcolumn = "+1"
vim.cmd("colorscheme base16-dracula")

opt.expandtab = true

opt.foldmethod = "syntax"
opt.foldcolumn = "3"
opt.foldlevelstart = 0

opt.hlsearch = true
opt.incsearch = true

opt.laststatus = 2

opt.mouse = "a"

opt.number = true
opt.relativenumber = true

opt.wrap = false

opt.showcmd = true
opt.ruler = true

opt.shiftround = true

opt.shiftwidth = 2
opt.tabstop = 2

opt.showmatch = true
opt.smartindent = true

opt.textwidth = 80

opt.visualbell = true

opt.wildmenu = true

opt.listchars = {
  tab = ">.",
  eol = "$",
}

opt.wildignore = {
  "*.bak",
  "*.o",
  "*.e",
  "*~",
}

opt.matchpairs:append({
  "<:>",
})

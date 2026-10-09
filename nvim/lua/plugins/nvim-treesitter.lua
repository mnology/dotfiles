local ts = require("nvim-treesitter")

ts.setup({
  install_dir = vim.fn.stdpath("data") .. "/site",
})

-- Parsers for the languages in active use plus the common support set.
-- Note: there is no dedicated Tree-sitter parser for Makefile or GitLab CI;
-- Makefiles use the "make" parser, and .gitlab-ci.yml is YAML (yaml parser).
ts.install({
  -- editor / config languages
  "lua",
  "vim",
  "vimdoc",
  "query",
  -- the user's day-to-day set
  "python",
  "toml",
  "yaml",
  "terraform",
  "hcl",
  "make",
  "cmake",
  "go",
  "gomod",
  "ruby",
  "perl",
  "php",
  -- recommended support set
  "bash",
  "json",
  "markdown",
  "markdown_inline",
  "dockerfile",
  "gitcommit",
  "gitignore",
  "diff",
  "regex",
})

return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
}

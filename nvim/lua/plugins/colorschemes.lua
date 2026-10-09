return {
  -- Current
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
  },

  -- Modern mainstream
  {
    "catppuccin/nvim",
    name = "catppuccin",
  },

  {
    "folke/tokyonight.nvim",
  },

  {
    "rebelot/kanagawa.nvim",
  },

  {
    "rose-pine/neovim",
    name = "rose-pine",
  },

  {
    "ellisonleao/gruvbox.nvim",
  },

  -- Strong engineering / platform themes
  {
    "EdenEast/nightfox.nvim",
  },

  {
    "navarasu/onedark.nvim",
  },

  {
    "AlexvZyl/nordic.nvim",
  },

  -- Newer "high rizz" themes
  {
    "scottmckendry/cyberdream.nvim",
  },

  {
    "projekt0n/github-nvim-theme",
  },

  {
    "slugbyte/lackluster.nvim",
  },

  {
    "ribru17/bamboo.nvim",
  },

  -- Honorable mentions
  {
    "shaunsingh/nord.nvim",
  },

  {
    "craftzdog/solarized-osaka.nvim",
  },
  {
    "kinoute/vim-hivacruz-theme",
    name = "hivacruz",
    lazy = false,
    priority = 1000,
    config = function()
      -- Apply after the UI has attached. hivacruz.vim indexes
      -- nvim_list_uis()[0], which is empty during headless/early startup
      -- and raises E684, so guard with pcall and defer to UIEnter.
      vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        callback = function()
          pcall(vim.cmd.colorscheme, "hivacruz")
        end,
      })
    end,
  },
}

return {
  {
    "tinted-theming/tinted-nvim",
    version = "0.1.*",
    priority = 1000,
    lazy = false,
    config = function()
      -- setup() starts the live-reload watcher (live_reload defaults to true).
      -- Without this call the watcher never runs, so Neovim does not follow
      -- `tinty apply`. Apply after the UI attaches to avoid headless issues.
      vim.api.nvim_create_autocmd("UIEnter", {
        once = true,
        callback = function()
          pcall(function()
            require("tinted-colorscheme").setup()
          end)
        end,
      })
    end,
  },
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
  },
}

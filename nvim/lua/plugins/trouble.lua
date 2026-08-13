return {
  {
    "folke/trouble.nvim",

    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },

    cmd = "Trouble",

    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<CR>",
        desc = "Diagnostics",
      },

      {
        "<leader>xq",
        "<cmd>Trouble qflist toggle<CR>",
        desc = "Quickfix",
      },

      {
        "<leader>xs",
        "<cmd>Trouble symbols toggle<CR>",
        desc = "Symbols",
      },

      {
        "<leader>xl",
        "<cmd>Trouble loclist toggle<CR>",
        desc = "Location List",
      },
    },

    opts = {},
  },
}

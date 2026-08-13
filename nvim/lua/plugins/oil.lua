return {
  "stevearc/oil.nvim",

  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require("oil").setup()

    vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent directory" })
  end,
}

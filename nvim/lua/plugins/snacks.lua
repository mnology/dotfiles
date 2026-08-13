return {
  {
    "folke/snacks.nvim",

    priority = 1000,
    lazy = false,

    opts = {
      dashboard = { enabled = true },
      notifier = { enabled = true },
      picker = { enabled = true },
      scratch = { enabled = true },
      explorer = { enabled = true },
    },

    keys = {
      {
        "<leader>sn",
        function()
          Snacks.notifier.show_history()
        end,
        desc = "Notifications",
      },
      {
        "<leader>ss",
        function()
          Snacks.scratch()
        end,
        desc = "Scratch Buffer",
      },
      {
        "<leader>sp",
        function()
          Snacks.picker()
        end,
        desc = "Snacks Picker",
      },
    },
  },
}

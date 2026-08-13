return {
  "stevearc/conform.nvim",

  event = { "BufWritePre" },

  cmd = { "ConformInfo" },

  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({
          async = true,
          lsp_fallback = true,
        })
      end,
      mode = { "n", "v" },
      desc = "Format Buffer",
    },
  },

  opts = {
    formatters_by_ft = {
      lua = { "stylua" },

      python = { "black" },

      terraform = { "terraform_fmt" },

      json = { "prettier" },
      jsonc = { "prettier" },

      yaml = { "prettier" },

      markdown = { "prettier" },

      sh = { "shfmt" },
      bash = { "shfmt" },
      zsh = { "shfmt" },
    },

    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}

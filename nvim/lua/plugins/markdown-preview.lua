return {
  {
    "iamcco/markdown-preview.nvim",

    ft = { "markdown" },

    cmd = {
      "MarkdownPreview",
      "MarkdownPreviewStop",
      "MarkdownPreviewToggle",
    },

    -- build = "cd app && npm install",

    keys = {
      {
        "<leader>mp",
        "<cmd>MarkdownPreviewToggle<CR>",
        desc = "Markdown Preview",
      },
    },

    init = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      vim.g.mkdp_echo_preview_url = 1
      vim.g.mkdp_theme = "dark"

      vim.g.mkdp_open_to_the_world = 0
      vim.g.mkdp_combine_preview = 0
      vim.g.mkdp_combine_preview_auto_refresh = 1
    end,
  },
}

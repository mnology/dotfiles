return {
  "lewis6991/gitsigns.nvim",

  config = function()
    local gs = require("gitsigns")

    gs.setup()

    vim.keymap.set("n", "]h", gs.next_hunk)
    vim.keymap.set("n", "[h", gs.prev_hunk)

    vim.keymap.set("n", "<leader>hs", gs.stage_hunk)
    vim.keymap.set("n", "<leader>hr", gs.reset_hunk)

    vim.keymap.set("n", "<leader>hp", gs.preview_hunk)
    vim.keymap.set("n", "<leader>hb", gs.blame_line)
  end,
}

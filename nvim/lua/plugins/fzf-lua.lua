return {
  "ibhagwan/fzf-lua",

  config = function()
    local fzf = require("fzf-lua")

    -- fzf_colors = true derives the fzf --color spec from the active Neovim
    -- highlight groups, so the picker follows the tinted-nvim scheme instead of
    -- fzf's built-in default palette. The shell's tinted-fzf theme does not
    -- apply here: fzf-lua builds its own colors and ignores FZF_DEFAULT_OPTS.
    fzf.setup({ fzf_colors = true })

    vim.keymap.set("n", "<leader>ff", fzf.files, { desc = "Files" })
    vim.keymap.set("n", "<leader>fg", fzf.live_grep, { desc = "Grep" })
    vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Buffers" })
    vim.keymap.set("n", "<leader>fh", fzf.helptags, { desc = "Help" })
    vim.keymap.set("n", "<leader>fc", fzf.commands, { desc = "Commands" })
    vim.keymap.set("n", "<leader>fr", fzf.resume, { desc = "Resume" })
    vim.keymap.set("n", "<leader><Tab>", function()
      require("fzf-lua").buffers()
    end, {
      desc = "Buffers",
    })
  end,
}

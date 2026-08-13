vim.keymap.set("n", "<leader>tc", function()
  require("fzf-lua").colorschemes()
end, {
  desc = "Themes",
})

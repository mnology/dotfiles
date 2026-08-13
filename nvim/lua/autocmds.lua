local autocmd = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup

autocmd("FileType", {
  group = group("chef", { clear = true }),
  pattern = { "ruby", "eruby" },
  callback = function()
    vim.bo.filetype = "ruby.eruby.chef"
  end,
})

autocmd("FileType", {
  group = group("anyfold", { clear = true }),
  pattern = "*",
  callback = function()
    pcall(vim.cmd, "AnyFoldActivate")
  end,
})

autocmd("FileType", {
  group = group("css", { clear = true }),
  pattern = "css",
  callback = function()
    vim.bo.equalprg = "csstidy --silent=true --template=low"
  end,
})

local map = vim.keymap.set

--
-- Javascript Beautify
--
map("n", "<C-f>", function()
  vim.cmd("call JsBeautify()")
end, {
  silent = true,
})

--
-- Insert completion
--
map("i", "<Tab>", "<C-p>")

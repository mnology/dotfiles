-- Completion: nvim-cmp wired to LSP, buffer, and path sources.
--
-- nvim-cmp is already pulled in as an avante.nvim dependency; here we give it
-- an actual configuration and the source plugins it needs. The LSP capabilities
-- it advertises are picked up by the servers enabled in plugins/lspconfig.lua
-- (nvim-lspconfig merges cmp's capabilities automatically when present).
return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp", -- LSP source
    "hrsh7th/cmp-buffer", -- current-buffer words
    "hrsh7th/cmp-path", -- filesystem paths
  },
  config = function()
    local cmp = require("cmp")

    cmp.setup({
      -- No snippet engine configured; expand is a no-op so cmp does not error
      -- when a server returns a snippet-kind item.
      snippet = {
        expand = function(args)
          vim.snippet.expand(args.body) -- native snippets (nvim 0.10+)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
      }),
      sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "path" },
      }, {
        { name = "buffer" },
      }),
    })
  end,
}

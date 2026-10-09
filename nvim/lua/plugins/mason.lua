-- mason is set up by plugins/lspconfig.lua (which depends on it and calls
-- require("mason").setup()). This spec just declares the plugin so lazy knows
-- about it; configuring it here too would double-initialize it.
return {
  "mason-org/mason.nvim",
}

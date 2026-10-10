-- Modern LSP stack for Neovim 0.11+ (this box runs 0.12.5).
--
-- Flow:
--   mason.nvim          installs the server binaries
--   mason-lspconfig     bridges mason <-> lspconfig and ensures servers exist
--   nvim-lspconfig      ships the default server configs
--   vim.lsp.enable()    activates them (0.11+ API; no per-server setup() calls)
--
-- Formatting stays in conform.nvim; linting/diagnostics come from the LSPs,
-- which is why the legacy ale/black/vim-go/vim-terraform-completion plugins
-- were retired (see plugins/languages.lua).

-- Servers to install and enable, keyed by lspconfig name.
-- HCL and Packer (*.hcl / *.pkr.hcl) are handled by terraformls.
-- Makefile and .gitlab-ci.yml have no dedicated server:
--   - Makefiles get Tree-sitter highlighting only.
--   - .gitlab-ci.yml is YAML; yamlls provides the GitLab CI schema below.
local SERVERS = {
  "lua_ls", -- Lua (Neovim config)
  "pyright", -- Python
  "taplo", -- TOML
  "yamlls", -- YAML (+ .gitlab-ci.yml via schema)
  "terraformls", -- Terraform / HCL / Packer
  "ansiblels", -- Ansible
  "bashls", -- bash / sh
  "jsonls", -- JSON / jsonc
  "marksman", -- Markdown
  "dockerls", -- Dockerfile
  "cmake", -- CMake
  "gopls", -- Go
  "ruby_lsp", -- Ruby / Chef cookbooks
  "perlnavigator", -- Perl
  "intelephense", -- PHP
}

-- Per-server config overrides, applied via vim.lsp.config() before enable.
local function configure_servers()
  -- Advertise nvim-cmp's completion capabilities to every server, so LSP
  -- completion items flow into cmp. Falls back gracefully if cmp is absent.
  local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok_cmp then
    vim.lsp.config("*", { capabilities = cmp_lsp.default_capabilities() })
  end

  vim.lsp.config("lua_ls", {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        -- Recognize the `vim` global so editing this config is warning-free.
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  })

  -- Attach the GitLab CI JSON schema to .gitlab-ci.yml so yamlls validates it.
  vim.lsp.config("yamlls", {
    settings = {
      yaml = {
        keyOrdering = false,
        schemas = {
          ["https://gitlab.com/gitlab-org/gitlab/-/raw/master/app/assets/javascripts/editor/schema/ci.json"] = {
            "*.gitlab-ci.yml",
            ".gitlab-ci.yml",
          },
        },
      },
    },
  })
end

-- Minimal LSP keymaps, set only for buffers that actually attach a server.
local function on_lsp_attach(ev)
  local function nmap(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
  end
  nmap("grn", vim.lsp.buf.rename, "LSP rename")
  nmap("gra", vim.lsp.buf.code_action, "LSP code action")
  nmap("grr", vim.lsp.buf.references, "LSP references")
  nmap("gd", vim.lsp.buf.definition, "LSP definition")
  nmap("K", vim.lsp.buf.hover, "LSP hover")
  nmap("[d", function()
    vim.diagnostic.jump({ count = -1 })
  end, "Prev diagnostic")
  nmap("]d", function()
    vim.diagnostic.jump({ count = 1 })
  end, "Next diagnostic")
end

return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { "mason-org/mason.nvim" },
      { "mason-org/mason-lspconfig.nvim" },
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = SERVERS,
        automatic_enable = false, -- we enable explicitly below
      })

      configure_servers()
      vim.lsp.enable(SERVERS)

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_attach", { clear = true }),
        callback = on_lsp_attach,
      })
    end,
  },
}

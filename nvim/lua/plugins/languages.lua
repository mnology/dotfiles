-- Language support plugins.
--
-- Retired in favor of the modern LSP + conform stack (plugins/lspconfig.lua,
-- plugins/conform.lua):
--   - dense-analysis/ale          -> LSP diagnostics + conform formatting
--   - psf/black                   -> conform runs black
--   - fatih/vim-go                -> gopls
--   - juliosueiras/vim-terraform-completion -> terraformls
--
-- Language servers enabled in plugins/lspconfig.lua now cover Python, Lua,
-- Terraform/HCL/Packer, Ansible, YAML, TOML, JSON, bash, Markdown, Docker,
-- CMake, Go, Ruby (Chef), Perl, and PHP.
--
-- Kept for filetype detection / indent / syntax niceties that the language
-- servers do not fully provide on their own:
return {
  { "hashivim/vim-terraform" }, -- terraform/tfvars/packer ftdetect + :Terraform cmds
  { "pearofducks/ansible-vim" }, -- ansible ft heuristics (playbooks vs plain yaml)
  { "lepture/vim-jinja" }, -- jinja templating syntax
  { "vim-ruby/vim-ruby" }, -- ruby indent/syntax (chef cookbooks)
}

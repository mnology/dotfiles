local ok, gitlab = pcall(require, "local.gitlab")

if ok then
  vim.g.gitlab_api_keys = gitlab
end

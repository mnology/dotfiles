-- Markdown table of contents. Lazy-load on Markdown or the :Mtoc command.
return {
  {
    "hedyhli/markdown-toc.nvim",
    ft = "markdown",
    cmd = { "Mtoc" },
    opts = {
      auto_update = true,
    },
  },
}

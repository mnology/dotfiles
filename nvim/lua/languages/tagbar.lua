vim.g.tagbar_type_make = {
  kinds = {
    "m:macros",
    "t:targets",
  },
}

vim.g.tagbar_type_markdown = {
  ctagstype = "markdown",

  ctagsbin = "/usr/local/lib/python3.6/dist-packages/markdown2ctags.py",

  ctagsargs = "-f - --sort=yes --sro=»",

  kinds = {
    "s:sections",
    "i:images",
  },

  sro = "»",

  kind2scope = {
    s = "section",
  },

  sort = 0,
}

vim.g.tagbar_type_ansible = {
  ctagstype = "ansible",

  kinds = {
    "t:tasks",
  },

  sort = 0,
}

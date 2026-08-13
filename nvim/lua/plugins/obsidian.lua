return {
  {
    "obsidian-nvim/obsidian.nvim",

    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "aad-cicd-platform-epics",
          path = "/home/ejohanse/devel/ADAS/platform/aad-cicd-platform-epics",
        },
      },
    },
  },
}

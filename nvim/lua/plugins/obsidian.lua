-- Obsidian notes. Lazy-load so a missing vault never breaks startup.
-- Load only for Markdown files or when an Obsidian command runs.
-- The default vault is portable; it does not need to exist at install time.
return {
  {
    "obsidian-nvim/obsidian.nvim",

    ft = "markdown",
    cmd = {
      "Obsidian",
      "ObsidianNew",
      "ObsidianOpen",
      "ObsidianSearch",
      "ObsidianToday",
      "ObsidianQuickSwitch",
    },

    dependencies = {
      "nvim-lua/plenary.nvim",
    },

    opts = {
      legacy_commands = false,
      workspaces = {
        {
          name = "mnology_notes",
          path = "~/Documents/mnology_notes",
        },
      },
    },
  },
}

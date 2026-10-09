return {
  { "folke/lazy.nvim" },
  {
    "yetone/avante.nvim",
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- ⚠️ must add this setting! ! !
    build = vim.fn.has("win32") ~= 0
        and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
      or "make",
    -- Lazy-load on the Avante commands and keys instead of VeryLazy, so avante
    -- never initializes at startup. This stops the start error when the ollama
    -- provider or RAG endpoint is not running.
    cmd = {
      "AvanteAsk",
      "AvanteToggle",
      "AvanteChat",
      "AvanteEdit",
      "AvanteRefresh",
      "AvanteBuild",
    },
    keys = {
      { "<leader>aa", desc = "Avante: ask" },
      { "<leader>at", desc = "Avante: toggle" },
    },
    version = false, -- Never set this value to "*"! Never!
    ---@module 'avante'
    ---@type avante.Config
    opts = {
      provider = "ollama",
      providers = {
        ollama = {
          endpoint = "http://localhost:11434",
          model = "qwq:32b",
        },
      },
      rag_service = "ollama",
      rag_service_options = {
        ollama = {
          endpoint = "http://localhost:11434/v1",
          llm_model = "qwq:32b", -- Optional, defaults to llama3
          embed_model = "nomic-embed-text", -- Optional, defaults to nomic-embed-text
          host_mount = os.getenv("HOME"), -- Or your project directory
        },
      },
      -- add any opts here
      -- for example
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "stevearc/dressing.nvim", -- for input provider dressing
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
      {
        -- support for image pasting
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          -- recommended settings
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = {
              insert_mode = true,
            },
            -- required for Windows users
            use_absolute_path = true,
          },
        },
      },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        opts = {
          file_types = { "markdown", "Avante" },
        },
        ft = { "markdown", "Avante" },
      },
    },
  },
  { "scrooloose/nerdtree" },
  { "tpope/vim-fugitive" },
  { "dense-analysis/ale" },
  { "tpope/vim-commentary" },
  { "tpope/vim-surround" },
  { "easymotion/vim-easymotion" },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
  },
}

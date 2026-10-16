return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("lualine").setup({
        -- tabline draws every open buffer as a tab. It is defined here so the
        -- component exists, but visibility is driven by showtabline below, not
        -- shown unconditionally.
        tabline = {
          lualine_a = {
            {
              "buffers",
              mode = 2, -- 0 name, 1 index, 2 name+index
              show_filename_only = true,
              show_modified_status = true,
              symbols = {
                modified = " ●",
                alternate_file = "",
                directory = "",
              },
            },
          },
          lualine_z = { "tabs" },
        },
      })

      -- Auto-show the tabline only when more than one file is loaded. Startup
      -- detection alone is not enough: the Kiro hook (:KiroChanged) opens
      -- buffers AFTER launch, so re-evaluate on buffer add/delete/enter.
      -- Count buflisted buffers only. Do NOT also require "loaded": files given
      -- on the command line or opened by the Kiro hook are buflisted before
      -- they are loaded, so a loaded check miscounts them as absent.
      local function count_listed_buffers()
        local n = 0
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[b].buflisted then
            n = n + 1
          end
        end
        return n
      end

      local function refresh_tabline()
        vim.o.showtabline = count_listed_buffers() > 1 and 2 or 0
      end

      vim.api.nvim_create_autocmd(
        { "BufAdd", "BufDelete", "BufEnter", "BufReadPost", "VimEnter" },
        {
          group = vim.api.nvim_create_augroup("AutoTabline", { clear = true }),
          -- BufDelete fires before the buffer is gone, so defer the count to
          -- the next tick to see the post-delete state.
          callback = function()
            vim.schedule(refresh_tabline)
          end,
        }
      )
    end,
  },
}
